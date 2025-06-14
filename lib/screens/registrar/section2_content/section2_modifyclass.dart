import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/models/manageClassSubjectsModel.dart';
import 'dart:math';

class ModifyClassDialog extends StatefulWidget {
  const ModifyClassDialog({
    Key? key,
    required this.onRefresh,
    required this.classModel,
    required this.subjectModels,
  }) : super(key: key);

  final ManageClassModel classModel;
  final VoidCallback onRefresh;
  final List<ManageClassSubjectsModel> subjectModels;

  @override
  State<ModifyClassDialog> createState() => _ModifyClassDialogState();
}

class _ModifyClassDialogState extends State<ModifyClassDialog> {
  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  // Kinder to 12 (K-12) System
  static const Map<String, String> _departmentCodes = {
    "Pre-School": "PRE",
    "Primary School": "PRI",
    "Junior High School": "JHS",
    "ABM - Senior High School": "ABM",
    "HUMMS - Senior High School": "HUMMS",
    "GAS - Senior High School": "GAS",
    "ICT - Senior High School": "ICT",
    "HE - Senior High School": "HE",
  };
  static const Map<String, String> _departmentCollections = {
    "Pre-School": "pre-dept",
    "Primary School": "pri-dept",
    "Junior High School": "jhs-dept",
    "ABM - Senior High School": "abm-dept",
    "HUMMS - Senior High School": "humms-dept",
    "GAS - Senior High School": "gas-dept",
    "ICT - Senior High School": "ict-dept",
    "HE - Senior High School": "he-dept",
  };
  static const Map<String, List<int>> _deparmentLevels = {
    "Pre-School": [1],
    "Primary School": [1, 2, 3, 4, 5, 6],
    "Junior High School": [7, 8, 9, 10],
    "HUMMS - Senior High School": [11, 12],
    "ABM - Senior High School": [11, 12],
    "GAS - Senior High School": [11, 12],
    "ICT - Senior High School": [11, 12],
    "HE - Senior High School": [11, 12],
  };

  List<Map<String, dynamic>> _availableSubjects = [];
  List<Map<String, dynamic>> _availableTeachers = [];
  final _captchaController = TextEditingController();
  String _captchaWord = '';
  int _currentPage = 0;
  final List<String> _daysOfWeek = [
    'TBA',
    'Everyday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> _departments = _deparmentLevels.keys.toList();
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingSubjects = false;
  bool _isLoadingTeachers = false;
  final _sectionController = TextEditingController();
  String _selectedAdviser = '';
  List<String> _selectedDays = [];
  String _selectedDepartment = '';
  List<String> _selectedEndTimes = [];
  int _selectedLevel = 0;
  List<String> _selectedStartTimes = [];
  List<String> _selectedSubjects = [];
  List<String> _selectedTeachers = [];
  bool _showDeleteConfirmation = false;

  final List<String> _timeSlots =
      List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');

  @override
  void dispose() {
    _sectionController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeFromModels();
    _generateCaptcha();
  }

  void _initializeFromModels() {
    final classCode = widget.classModel.classCode;
    final parts = classCode.split('-');

    _selectedDepartment = _departmentCollections.entries
        .firstWhere((entry) => entry.value == widget.classModel.classDepartment)
        .key;

    if (parts.length >= 3) {
      _selectedLevel = int.tryParse(parts[1]) ?? 1;
      _sectionController.text = parts[2];
    }

    _selectedAdviser = widget.classModel.adviser;

    for (final subjectModel in widget.subjectModels) {
      _selectedSubjects.add(subjectModel.subjectName);
      _selectedTeachers.add(subjectModel.teacherId);

      final schedule = subjectModel.classSchedule;
      final scheduleRegex = RegExp(r'([A-Z]+)\s+(\d{2}:\d{2})-(\d{2}:\d{2})');
      final match = scheduleRegex.firstMatch(schedule);

      if (match != null) {
        final dayCode = match.group(1)!;
        final startTime = match.group(2)!;
        final endTime = match.group(3)!;

        final dayName = _daysOfWeek.firstWhere(
          (day) => day.substring(0, 2).toUpperCase() == dayCode,
          orElse: () => _daysOfWeek.first,
        );

        _selectedDays.add(dayName);
        _selectedStartTimes.add(startTime);
        _selectedEndTimes.add(endTime);
      } else {
        _selectedDays.add(_daysOfWeek.first);
        _selectedStartTimes.add(_timeSlots.first);
        _selectedEndTimes.add(_timeSlots[1]);
      }
    }
  }

  void _generateCaptcha() {
    const words = ['DELETE', 'REMOVE', 'CONFIRM', 'PROCEED', 'EXECUTE'];
    final random = Random();
    _captchaWord = words[random.nextInt(words.length)];
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('subjectDepartment',
              isEqualTo: _departmentCollections[_selectedDepartment])
          .get();

      _availableSubjects = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'subjectId': doc['subjectId'],
                'subjectName': doc['subjectName'],
                'subjectDescription': doc['subjectDescription'],
                'subjectDepartment': doc['subjectDepartment'],
              })
          .toList();
    } catch (e) {
      _showError("Failed to fetch subjects: $e");
    } finally {
      setState(() => _isLoadingSubjects = false);
    }
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoadingTeachers = true);

    try {
      final departmentCode = _departmentCollections[_selectedDepartment];
      if (departmentCode == null)
        throw Exception("Invalid department selected");
      List<String> departmentList = [departmentCode];
      final snapshot = await FirebaseFirestore.instance
          .collection('entity')
          .where('entity', isEqualTo: 2)
          .where('department', arrayContainsAny: departmentList)
          .get();

      _availableTeachers = snapshot.docs
          .map((doc) => {
                'id': doc['userID'],
                'name': "${doc['userName00']} ${doc['userName01']}",
              })
          .toList();
    } catch (e) {
      _showError("Failed to fetch teachers: $e");
    } finally {
      setState(() => _isLoadingTeachers = false);
    }
  }

  bool _teacherExists(String teacherId) {
    if (teacherId.isEmpty) return false;
    return _availableTeachers.any((t) => t['id'] == teacherId);
  }

  String _generateClassCode() {
    final deptCode = _departmentCodes[_selectedDepartment] ?? '';
    return '$deptCode-$_selectedLevel-${_sectionController.text}';
  }

  String _generateClassSubjectCode(int subjectIndex) {
    final subject = _availableSubjects.firstWhere(
      (s) => s['subjectName'] == _selectedSubjects[subjectIndex],
      orElse: () => {},
    );

    if (subject.isNotEmpty) {
      final subjectId = subject['subjectId'].toString().split('-')[1];
      return '${_generateClassCode()}:$subjectId';
    }

    return '${_generateClassCode()}:${subjectIndex + 1}';
  }

  String _generateSchedule(int index) {
    if (index >= _selectedDays.length ||
        index >= _selectedStartTimes.length ||
        index >= _selectedEndTimes.length) {
      return '';
    }

    final dayInitial = _selectedDays[index].substring(0, 2).toUpperCase();
    final classSubjectCode = _generateClassSubjectCode(index);
    return '$classSubjectCode $dayInitial ${_selectedStartTimes[index]}-${_selectedEndTimes[index]}';
  }

  ManageClassModel _createClassModel() {
    final subjectIds = <int>[];

    for (int i = 0; i < _selectedSubjects.length; i++) {
      final subject = _availableSubjects.firstWhere(
        (s) => s['subjectName'] == _selectedSubjects[i],
        orElse: () => {},
      );

      if (subject.isNotEmpty) {
        final subjectId = int.tryParse(subject['subjectId'].toString()) ?? 0;
        subjectIds.add(subjectId);
      }
    }

    return ManageClassModel(
      classDepartment: _departmentCollections[_selectedDepartment]!,
      classCode: _generateClassCode(),
      classList: widget.classModel.classList,
      enrolledSubjects: subjectIds,
      adviser: _selectedAdviser,
    );
  }

  List<ManageClassSubjectsModel> _createSubjectModels() {
    final models = <ManageClassSubjectsModel>[];

    for (int i = 0; i < _selectedSubjects.length; i++) {
      final subject = _availableSubjects.firstWhere(
        (s) => s['subjectName'] == _selectedSubjects[i],
        orElse: () => {},
      );

      if (subject.isNotEmpty) {
        models.add(ManageClassSubjectsModel(
          teacherId: _selectedTeachers[i],
          subjectDepartment: _departmentCollections[_selectedDepartment]!,
          subjectId: subject['subjectId'],
          subjectName: subject['subjectName'],
          subjectDescription: subject['subjectDescription'],
          classSubjectCode: _generateClassSubjectCode(i),
          classSchedule: _generateSchedule(i),
        ));
      }
    }

    return models;
  }

  Future<void> _deleteClass() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final studentIds = await _getStudentIds();
      final classDoc = FirebaseFirestore.instance
          .collection(widget.classModel.classDepartment)
          .doc(widget.classModel.classCode);

      batch.delete(classDoc);

      for (final subjectModel in widget.subjectModels) {
        final subjectDoc = FirebaseFirestore.instance
            .collection('class-subjects')
            .doc(subjectModel.classSubjectCode);
        batch.delete(subjectDoc);

        final teacherQuery = await FirebaseFirestore.instance
            .collection('entity')
            .where('userID', isEqualTo: subjectModel.teacherId)
            .get();

        if (teacherQuery.docs.isNotEmpty) {
          final teacherDoc = teacherQuery.docs.first;
          final teacherRef = FirebaseFirestore.instance
              .collection('entity')
              .doc(teacherDoc.id);

          if (subjectModel.teacherId == widget.classModel.adviser) {
            batch.update(teacherRef, {
              'advisoryClassId':
                  FieldValue.arrayRemove([subjectModel.classSubjectCode])
            });
          } else {
            batch.update(teacherRef, {
              'subjectsList':
                  FieldValue.arrayRemove([subjectModel.classSubjectCode])
            });
          }
        }
      }

      for (final studentId in studentIds) {
        if (studentId.isNotEmpty) {
          final studentProfileRef = FirebaseFirestore.instance
              .collection('profile-information')
              .doc(studentId);

          final studentDoc = await studentProfileRef.get();
          if (studentDoc.exists) {
            final studentData = studentDoc.data();
            final currentEnrolledClass =
                studentData?['enrolledClass'] as String?;

            if (currentEnrolledClass == widget.classModel.classCode) {
              batch.update(studentProfileRef, {'enrolledClass': ''});
            }
          }
        }
      }

      await batch.commit();
      _showSuccess("Class deleted successfully!");
      widget.onRefresh();
      Navigator.of(context).pop();
    } catch (e) {
      _showError("Failed to delete class: $e");
    }
  }

  Future<void> _createGradeRecords(
      String classSubjectCode, List<String> studentIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (String studentId in studentIds) {
        final gradeDoc = FirebaseFirestore.instance
            .collection('class-subjects')
            .doc(classSubjectCode)
            .collection('grades')
            .doc(studentId);

        batch.set(gradeDoc, {
          'firstQuarter': 0,
          'secondQuarter': 0,
          'thirdQuarter': 0,
          'fourthQuarter': 0,
          'studentId': studentId,
        });
      }

      await batch.commit();
    } catch (e) {
      print("Failed to create grade records: $e");
    }
  }

  Future<List<String>> _getStudentIds() async {
    try {
      final classDoc = await FirebaseFirestore.instance
          .collection(widget.classModel.classDepartment)
          .doc(widget.classModel.classCode)
          .get();

      if (classDoc.exists) {
        final data = classDoc.data();
        return List<String>.from(data?['class-list'] ?? []);
      }
      return [];
    } catch (e) {
      print("Failed to fetch student IDs: $e");
      return [];
    }
  }

  Future<void> _submitModification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final classModel = _createClassModel();
      final subjectModels = _createSubjectModels();

      final enrolledSubjects = _selectedSubjects.map((subjectName) {
        final subject = _availableSubjects.firstWhere(
          (s) => s['subjectName'] == subjectName,
          orElse: () => {'subjectId': ''},
        );
        return int.parse(subject['subjectId'].toString().split('-')[1]);
      }).toList();

      final classDoc = FirebaseFirestore.instance
          .collection(classModel.classDepartment)
          .doc(classModel.classCode);

      batch.set(classDoc, {
        'class-code': classModel.classCode,
        'class-list': classModel.classList,
        'enrolled-subjects': enrolledSubjects,
        'adviser': classModel.adviser,
      });

      final oldSubjectCodes =
          widget.subjectModels.map((s) => s.classSubjectCode).toList();
      final newSubjectCodes =
          subjectModels.map((s) => s.classSubjectCode).toList();
      final removedSubjectCodes = oldSubjectCodes
          .where((code) => !newSubjectCodes.contains(code))
          .toList();

      for (final subjectCode in removedSubjectCodes) {
        final oldSubjectDoc = FirebaseFirestore.instance
            .collection('class-subjects')
            .doc(subjectCode);
        batch.delete(oldSubjectDoc);
      }

      Map<String, List<String>> previousTeacherSubjects = {};

      for (final subjectModel in widget.subjectModels) {
        final teacherId = subjectModel.teacherId;
        if (!previousTeacherSubjects.containsKey(teacherId)) {
          previousTeacherSubjects[teacherId] = [];
        }
        previousTeacherSubjects[teacherId]!.add(subjectModel.classSubjectCode);
      }

      for (final subjectModel in subjectModels) {
        final subjectDoc = FirebaseFirestore.instance
            .collection('class-subjects')
            .doc(subjectModel.classSubjectCode);
        batch.set(subjectDoc, subjectModel.toMap());

        final teacherQuery = await FirebaseFirestore.instance
            .collection('entity')
            .where('userID', isEqualTo: subjectModel.teacherId)
            .get();

        if (teacherQuery.docs.isNotEmpty) {
          final teacherDoc = teacherQuery.docs.first;
          final teacherRef = FirebaseFirestore.instance
              .collection('entity')
              .doc(teacherDoc.id);

          if (subjectModel.teacherId == classModel.adviser) {
            final currentClasses =
                List<String>.from(teacherDoc['advisoryClassId'] ?? []);
            if (!currentClasses.contains(subjectModel.classSubjectCode)) {
              currentClasses.add(subjectModel.classSubjectCode);
            }
            batch.update(teacherRef, {'advisoryClassId': currentClasses});
          } else {
            final currentClasses =
                List<String>.from(teacherDoc['subjectsList'] ?? []);
            if (!currentClasses.contains(subjectModel.classSubjectCode)) {
              currentClasses.add(subjectModel.classSubjectCode);
            }
            batch.update(teacherRef, {'subjectsList': currentClasses});
          }
        }
      }

      for (final teacherId in previousTeacherSubjects.keys) {
        final teacherQuery = await FirebaseFirestore.instance
            .collection('entity')
            .where('userID', isEqualTo: teacherId)
            .get();

        if (teacherQuery.docs.isNotEmpty) {
          final teacherDoc = teacherQuery.docs.first;
          final teacherRef = FirebaseFirestore.instance
              .collection('entity')
              .doc(teacherDoc.id);

          final isAdviser = teacherId == widget.classModel.adviser;
          final subjectCodes = previousTeacherSubjects[teacherId]!;

          if (isAdviser) {
            batch.update(teacherRef,
                {'advisoryClassId': FieldValue.arrayRemove(subjectCodes)});
          } else {
            batch.update(teacherRef,
                {'subjectsList': FieldValue.arrayRemove(subjectCodes)});
          }
        }
      }

      await batch.commit();
      final studentIds = await _getStudentIds();
      for (final subjectModel in subjectModels) {
        await _createGradeRecords(subjectModel.classSubjectCode, studentIds);
      }
      _showSuccess("Class modified successfully!");
      widget.onRefresh();
      Navigator.of(context).pop();
    } catch (e) {
      print("Modification failed: $e");
      _showError("Modification failed: $e");
    }
  }

  void _showError(String message) {
    useToastify.showErrorToast(context, "Error", message);
  }

  void _showSuccess(String message) {
    useToastify.showLoadingToast(context, "Success", message);
  }

  void _addSubject() {
    setState(() {
      _selectedSubjects.add('');
      _selectedTeachers.add('');
      _selectedDays.add(_daysOfWeek.first);
      _selectedStartTimes.add(_timeSlots.first);
      _selectedEndTimes.add(_timeSlots[1]);
    });
  }

  void _removeSubject(int index) {
    setState(() {
      _selectedSubjects.removeAt(index);
      _selectedTeachers.removeAt(index);
      _selectedDays.removeAt(index);
      _selectedStartTimes.removeAt(index);
      _selectedEndTimes.removeAt(index);
    });
  }

  void _showUnavailableTeachersWarning() {
    final unavailableTeachers = <String>[];

    if (_selectedAdviser.isNotEmpty &&
        !_availableTeachers.any((t) => t['id'] == _selectedAdviser)) {
      unavailableTeachers.add('Class Adviser (ID: $_selectedAdviser)');
    }

    for (int i = 0; i < _selectedTeachers.length; i++) {
      final teacherId = _selectedTeachers[i];
      if (teacherId.isNotEmpty &&
          !_availableTeachers.any((t) => t['id'] == teacherId)) {
        final subjectName = i < _selectedSubjects.length
            ? _selectedSubjects[i]
            : 'Subject ${i + 1}';
        unavailableTeachers.add('$subjectName Teacher (ID: $teacherId)');
      }
    }

    if (unavailableTeachers.isNotEmpty) {
      _showError(
          'Some previously assigned faculty are no longer available:\n${unavailableTeachers.join('\n')}\n\nPlease reassign teachers before saving.');
    }
  }

  bool _validateTeacherAvailability() {
    if (_selectedAdviser.isNotEmpty &&
        !_availableTeachers.any((t) => t['id'] == _selectedAdviser)) {
      return false;
    }

    for (final teacherId in _selectedTeachers) {
      if (teacherId.isNotEmpty &&
          !_availableTeachers.any((t) => t['id'] == teacherId)) {
        return false;
      }
    }

    return true;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              HugeIcons.strokeRoundedSchool,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Modify Class",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Edit class information and structure',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? _lightGray : _cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            validator: validator,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: readOnly ? Colors.grey.shade600 : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: readOnly ? _lightGray : _cardBackground,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDepartment,
            items: _departments
                .map((dept) => DropdownMenuItem<String>(
                      value: dept,
                      child: Text(
                        dept,
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: null,
            decoration: InputDecoration(
              hintText: 'Select a department',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedLevel,
            items: _deparmentLevels[_selectedDepartment]!
                .map((level) => DropdownMenuItem<int>(
                      value: level,
                      child: Text(
                        level.toString(),
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: null,
            decoration: InputDecoration(
              hintText: 'Select a level',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectDropdown(int index) {
    if (index < 0 || index >= _selectedSubjects.length) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject ${index + 1}',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedSubjects[index].isEmpty
                      ? null
                      : _selectedSubjects[index],
                  items: _availableSubjects
                      .map((s) => s['subjectName'] as String)
                      .where((name) =>
                          !_selectedSubjects.contains(name) ||
                          name == _selectedSubjects[index])
                      .map((subjectName) => DropdownMenuItem<String>(
                            value: subjectName,
                            child: Text(
                              subjectName,
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSubjects[index] = newValue ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Select a subject',
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: _cardBackground,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (index == 0)
              IconButton(
                onPressed: () => useToastify.showLoadingToast(
                    context, "Info", "You cannot remove the first subject."),
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.grey),
              )
            else
              IconButton(
                onPressed: () => _removeSubject(index),
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherDropdown(int index) {
    final assignedTeacherId = _selectedTeachers[index];
    final isTeacherUnavailable = assignedTeacherId.isNotEmpty &&
        !_availableTeachers.any((t) => t['id'] == assignedTeacherId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teacher',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (isTeacherUnavailable) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedAlert01,
                  color: Colors.orange.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Previously assigned faculty (ID: $assignedTeacherId) is no longer available. Please select a new teacher.',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: isTeacherUnavailable
                ? Border.all(color: Colors.orange.shade300, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: isTeacherUnavailable
                ? null
                : _selectedTeachers[index].isEmpty
                    ? null
                    : _availableTeachers.firstWhere(
                        (t) => t['id'] == _selectedTeachers[index],
                        orElse: () => {'name': ''},
                      )['name'] as String?,
            items: _availableTeachers
                .map((t) => t['name'] as String)
                .map((teacherName) => DropdownMenuItem<String>(
                      value: teacherName,
                      child: Text(
                        teacherName,
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: (newValue) {
              final teacher = _availableTeachers.firstWhere(
                (t) => t['name'] == newValue,
                orElse: () => {},
              );
              if (teacher.isNotEmpty) {
                setState(() => _selectedTeachers[index] = teacher['id'] ?? '');
              }
            },
            validator: (value) {
              if (_selectedTeachers[index].isEmpty) {
                return 'Please assign a teacher to this subject';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: isTeacherUnavailable
                  ? 'Select a new teacher'
                  : 'Select a teacher',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: isTeacherUnavailable
                    ? Colors.orange.shade600
                    : Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isTeacherUnavailable
                  ? Colors.orange.shade50
                  : _cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayDropdown(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDays[index],
            items: _daysOfWeek
                .map((day) => DropdownMenuItem<String>(
                      value: day,
                      child: Text(
                        day,
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: (newValue) {
              setState(
                  () => _selectedDays[index] = newValue ?? _daysOfWeek.first);
            },
            decoration: InputDecoration(
              hintText: 'Select a day',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDropdown(int index, bool isStartTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStartTime ? 'Start Time' : 'End Time',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: isStartTime
                ? _selectedStartTimes[index]
                : _selectedEndTimes[index],
            items: _timeSlots
                .map((time) => DropdownMenuItem<String>(
                      value: time,
                      child: Text(
                        time,
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: (newValue) {
              setState(() {
                if (isStartTime) {
                  _selectedStartTimes[index] = newValue ?? _timeSlots.first;
                } else {
                  _selectedEndTimes[index] = newValue ?? _timeSlots[1];
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Select a time',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassDetailsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDepartmentDropdown(),
        const SizedBox(height: 20),
        _buildLevelDropdown(),
        const SizedBox(height: 20),
        _buildFormField(
          label: 'Section',
          controller: _sectionController,
          readOnly: true,
          hintText: 'Auto-generated based on department and level',
        ),
      ],
    );
  }

  Widget _buildSubjectsPage() {
    if (_isLoadingSubjects) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading subjects...',
              style: GoogleFonts.montserrat(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_selectedSubjects.length, (index) {
          return Column(
            children: [
              _buildSubjectDropdown(index),
              const SizedBox(height: 20),
            ],
          );
        }),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _addSubject,
            icon: const Icon(HugeIcons.strokeRoundedAdd01, size: 18),
            label: Text("Add Subject", style: GoogleFonts.montserrat()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdviserDropdown() {
    final isAdviserUnavailable = _selectedAdviser.isNotEmpty &&
        !_availableTeachers.any((t) => t['id'] == _selectedAdviser);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Adviser',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (isAdviserUnavailable) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedAlert01,
                  color: Colors.red.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Previously assigned adviser (ID: $_selectedAdviser) is no longer available. Please select a new adviser.',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: isAdviserUnavailable
                ? Border.all(color: Colors.red.shade300, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: isAdviserUnavailable
                ? null
                : _selectedAdviser.isEmpty
                    ? null
                    : _selectedAdviser,
            items: _availableTeachers
                .map((teacher) => DropdownMenuItem<String>(
                      value: teacher['id'],
                      child: Text(
                        teacher['name'],
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedAdviser = newValue ?? '';
              });
            },
            validator: (value) {
              if (_selectedAdviser.isEmpty) {
                return 'Please select a class adviser';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: isAdviserUnavailable
                  ? 'Previous adviser unavailable - Select a new adviser'
                  : 'Select an adviser',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: isAdviserUnavailable
                    ? Colors.red.shade600
                    : Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  isAdviserUnavailable ? Colors.red.shade50 : _cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectDetailsPage() {
    if (_isLoadingTeachers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading teachers...',
              style: GoogleFonts.montserrat(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAdviserDropdown(),
        const SizedBox(height: 20),
        ...List.generate(_selectedSubjects.length, (index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedSubjects[index]}',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTeacherDropdown(index)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDayDropdown(index)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTimeDropdown(index, true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTimeDropdown(index, false)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage == 0)
            Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Color.fromARGB(255, 244, 67, 54)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showDeleteConfirmation = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text('Delete',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ))
                    ])))
          else if (_currentPage > 0)
            TextButton.icon(
              onPressed: () => setState(() => _currentPage--),
              icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
              label: Text('Back', style: GoogleFonts.montserrat()),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            )
          else
            const SizedBox(),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('Cancel', style: GoogleFonts.montserrat()),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_currentPage == 0) {
                    await _fetchSubjects();
                    setState(() => _currentPage = 1);
                  } else if (_currentPage == 1) {
                    if (_selectedSubjects.every((s) => s.isNotEmpty)) {
                      await _fetchTeachers();

                      _showUnavailableTeachersWarning();
                      setState(() => _currentPage = 2);
                    } else {
                      _showError("Please select at least one subject.");
                    }
                  } else {
                    bool hasValidAdviser = _selectedAdviser.isNotEmpty &&
                        _teacherExists(_selectedAdviser);
                    bool allTeachersValid = _selectedTeachers.every(
                        (teacherId) =>
                            teacherId.isNotEmpty && _teacherExists(teacherId));
                    bool adviserIsTeacher =
                        _selectedTeachers.contains(_selectedAdviser);

                    bool allTeachersAvailable = _validateTeacherAvailability();

                    if (!hasValidAdviser) {
                      _showError("Please select a valid class adviser.");
                      return;
                    }

                    if (!allTeachersValid) {
                      _showError(
                          "Please assign valid teachers to all subjects.");
                      return;
                    }

                    if (!adviserIsTeacher) {
                      _showError(
                          "The class adviser must be assigned to teach at least one subject.");
                      return;
                    }

                    if (!allTeachersAvailable) {
                      _showError(
                          "Some assigned teachers are no longer available in the system. Please reassign all teachers before saving.");
                      return;
                    }

                    await _submitModification();
                  }
                },
                icon: Icon(_currentPage == 2
                    ? HugeIcons.strokeRoundedDownload01
                    : HugeIcons.strokeRoundedArrowRight01),
                label: Text(
                  _currentPage == 2 ? 'Save Changes' : 'Continue',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showDeleteConfirmation
        ? Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: DynamicSizeService.calculateWidthSize(context, 0.5),
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Color.fromARGB(255, 244, 67, 54)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            HugeIcons.strokeRoundedDelete02,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Confirm Deletion",
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This action cannot be undone',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                HugeIcons.strokeRoundedAlert01,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "This will permanently delete the class '${widget.classModel.classCode}'. This action cannot be undone.",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "To confirm deletion, please type: $_captchaWord",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFormField(
                          label: "Confirmation",
                          controller: _captchaController,
                          hintText: "Type $_captchaWord here",
                          validator: (value) {
                            if (value != _captchaWord) {
                              return 'Please type the exact word: $_captchaWord';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: _lightGray,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _captchaController.clear();
                            setState(() => _showDeleteConfirmation = false);
                          },
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.red,
                                Color.fromARGB(255, 244, 67, 54)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_captchaController.text.toUpperCase() ==
                                  _captchaWord) {
                                await _deleteClass();
                              } else {
                                useToastify.showErrorToast(
                                  context,
                                  'Oops!',
                                  "Incorrect confirmation word. Please try again.",
                                );
                                _captchaController.clear();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  HugeIcons.strokeRoundedDelete02,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Class',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: DynamicSizeService.calculateWidthSize(context, 0.6),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentPage == 0
                              ? _buildClassDetailsPage()
                              : _currentPage == 1
                                  ? _buildSubjectsPage()
                                  : _buildSubjectDetailsPage(),
                        ),
                      ),
                    ),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ),
          );
  }
}
