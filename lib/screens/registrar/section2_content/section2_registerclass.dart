import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/models/manageClassSubjectsModel.dart';

class RegisterClassDialog extends StatefulWidget {
  final VoidCallback onRefresh;

  const RegisterClassDialog({Key? key, required this.onRefresh})
      : super(key: key);

  @override
  State<RegisterClassDialog> createState() => _RegisterClassDialogState();
}

class _RegisterClassDialogState extends State<RegisterClassDialog> {
  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  final _formKey = GlobalKey<FormState>();
  final _sectionController = TextEditingController();

  String _selectedDepartment = '';
  int _selectedLevel = 0;
  String _selectedAdviser = '';

  List<String> _selectedSubjects = [];
  List<String> _selectedTeachers = [];
  List<String> _selectedDays = [];
  List<String> _selectedStartTimes = [];
  List<String> _selectedEndTimes = [];

  List<Map<String, dynamic>> _availableSubjects = [];
  List<Map<String, dynamic>> _availableTeachers = [];

  bool _isLoadingSection = false;
  bool _isLoadingSubjects = false;
  bool _isLoadingTeachers = false;
  int _currentPage = 0;

  static const Map<String, List<int>> _departmentLevels = {
    "Pre-School": [1],
    "Primary School": [1, 2, 3, 4, 5, 6],
    "Junior High School": [7, 8, 9, 10],
    "ABM - Senior High School": [11, 12],
    "HUMMS - Senior High School": [11, 12],
    "GAS - Senior High School": [11, 12],
    "ICT - Senior High School": [11, 12],
    "HE - Senior High School": [11, 12]
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

  final List<String> _departments = _departmentLevels.keys.toList();
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
  final List<String> _timeSlots =
      List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  void _initializeDefaults() {
    _sectionController.text = 'loading...';
    _selectedDepartment = _departments.first;
    _selectedLevel = _departmentLevels[_selectedDepartment]!.first;
    _updateSection();
  }

  Future<void> _updateSection() async {
    setState(() => _isLoadingSection = true);

    try {
      final collectionName = _departmentCollections[_selectedDepartment];
      if (collectionName == null) throw Exception("Invalid department");

      final querySnapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();
      int maxSection = 0;

      for (final doc in querySnapshot.docs) {
        final classCode = doc['class-code'].toString();
        final parts = classCode.split('-');

        if (parts.length >= 3) {
          final grade = int.tryParse(parts[1]);
          final section = int.tryParse(parts[2]);

          if (grade == _selectedLevel &&
              section != null &&
              section > maxSection) {
            maxSection = section;
          }
        }
      }

      _sectionController.text = (maxSection + 1).toString();
    } catch (e) {
      _sectionController.text = 'N/A';
      _showError("Failed to fetch section: $e");
    } finally {
      setState(() => _isLoadingSection = false);
    }
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

  String _generateClassCode() {
    final deptCode = _departmentCodes[_selectedDepartment] ?? '';
    return '$deptCode-$_selectedLevel-${_sectionController.text}';
  }

  String _generateClassSubjectCode(int subjectIndex) {
    final subject = _availableSubjects.firstWhere(
      (s) => s['subjectName'] == _selectedSubjects[subjectIndex],
      orElse: () => {},
    );

    final subjectId =
        subject.isNotEmpty ? subject['subjectId'] : (subjectIndex + 1);
    return '${_generateClassCode()}:${subjectId.toString().split('-')[1]}';
  }

  String _generateSchedule(int index) {
    if (index >= _selectedDays.length ||
        index >= _selectedStartTimes.length ||
        index >= _selectedEndTimes.length) {
      return '';
    }

    String dayInitial = _selectedDays[index] == 'TBA'
        ? 'TBA'
        : _selectedDays[index].substring(0, 2).toUpperCase();

    final classSubjectCode = _generateClassSubjectCode(index);
    return '$classSubjectCode $dayInitial ${_selectedStartTimes[index]}-${_selectedEndTimes[index]}';
  }

  ManageClassModel _createClassModel() {
    final subjectIds = _selectedSubjects
        .map((subjectName) {
          final subject = _availableSubjects.firstWhere(
            (s) => s['subjectName'] == subjectName,
            orElse: () => {},
          );
          return subject.isNotEmpty
              ? int.parse(subject['subjectId'].toString().split('-')[1])
              : 0;
        })
        .where((id) => id != 0)
        .toList();

    return ManageClassModel(
      classDepartment: _departmentCollections[_selectedDepartment]!,
      classCode: _generateClassCode(),
      classList: [],
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

  void _addSubject() {
    setState(() {
      _selectedSubjects.add('');
      _selectedTeachers.add('');
      _selectedDays.add(_daysOfWeek.first);
      _selectedStartTimes.add(_timeSlots.first);
      _selectedEndTimes.add(_timeSlots[1]);
    });
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAdviser.isEmpty) {
      _showError("Please select an adviser.");
      return;
    }

    try {
      final classModel = _createClassModel();
      final subjectModels = _createSubjectModels();

      await FirebaseFirestore.instance
          .collection(classModel.classDepartment)
          .doc(classModel.classCode)
          .set({
        'class-code': classModel.classCode,
        'class-list': classModel.classList,
        'enrolled-subjects': classModel.enrolledSubjects,
        'adviser': classModel.adviser,
      });

      for (var model in subjectModels) {
        await FirebaseFirestore.instance
            .collection('class-subjects')
            .doc(model.classSubjectCode)
            .set(model.toMap());

        await _updateTeacherRecord(model.teacherId, model.classSubjectCode);
      }

      _showSuccess("Class registered successfully!");
      widget.onRefresh();
      Navigator.of(context).pop();
    } catch (e) {
      _showError("Registration failed: $e");
      print(e);
    }
  }

  Future<void> _updateTeacherRecord(
      String teacherId, String classSubjectCode) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('entity')
        .where('userID', isEqualTo: teacherId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final isAdviser = teacherId == _selectedAdviser;
      final fieldName = isAdviser ? 'advisoryClassId' : 'subjectsList';
      final currentClasses = List<String>.from(doc[fieldName] ?? []);

      if (!currentClasses.contains(classSubjectCode)) {
        currentClasses.add(classSubjectCode);
        await FirebaseFirestore.instance
            .doc(doc.reference.path)
            .update({fieldName: currentClasses});
      }
    }
  }

  void _showError(String message) {
    useToastify.showErrorToast(context, "Error", message);
  }

  void _showSuccess(String message) {
    useToastify.showLoadingToast(context, "Success", message);
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
                "Register New Class",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a new class to the system',
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
            onChanged: (newValue) {
              setState(() {
                _selectedDepartment = newValue!;
                _selectedLevel = _departmentLevels[newValue]!.first;
                _updateSection();
              });
            },
            validator: (value) =>
                value == null ? 'Please select a department' : null,
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
            items: _departmentLevels[_selectedDepartment]!
                .map((level) => DropdownMenuItem<int>(
                      value: level,
                      child: Text(
                        level.toString(),
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedLevel = newValue!;
                _updateSection();
              });
            },
            validator: (value) =>
                value == null ? 'Please select a level' : null,
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
      key: ValueKey('subject-column-$index'),
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
                  validator: (value) =>
                      value == null ? 'Please select a subject' : null,
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
                key: ValueKey('remove-button-$index'),
                onPressed: () => _removeSubject(index),
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
              ),
          ],
        ),
      ],
    );
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

  Widget _buildTeacherDropdown(int index) {
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
            value: _selectedTeachers[index].isEmpty
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
            validator: (value) =>
                value == null ? 'Please select a teacher' : null,
            decoration: InputDecoration(
              hintText: 'Select a teacher',
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
          if (_currentPage > 0)
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
                onPressed: _isLoadingSection
                    ? null
                    : () async {
                        if (_currentPage == 0) {
                          await _fetchSubjects();
                          if (_selectedSubjects.isEmpty) _addSubject();
                          setState(() => _currentPage = 1);
                        } else if (_currentPage == 1) {
                          if (_selectedSubjects.every((s) => s.isNotEmpty)) {
                            await _fetchTeachers();
                            setState(() => _currentPage = 2);
                          } else {
                            _showError("Please select at least one subject.");
                          }
                        } else {
                          if (_selectedTeachers.contains(_selectedAdviser) &&
                              _selectedAdviser.isNotEmpty) {
                            await _submitRegistration();
                          } else {
                            _showError(
                                "Please select the class adviser as a teacher for at least one subject.");
                          }
                        }
                      },
                icon: Icon(_currentPage < 2
                    ? HugeIcons.strokeRoundedArrowRight01
                    : HugeIcons.strokeRoundedCheckmarkCircle01),
                label: Text(
                  _currentPage < 2 ? 'Next' : 'Register Class',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
    return Dialog(
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

  Widget _buildAdviserDropdown() {
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
            value: _selectedAdviser.isEmpty ? null : _selectedAdviser,
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
            validator: (value) =>
                value == null ? 'Please select an adviser' : null,
            decoration: InputDecoration(
              hintText: 'Select an adviser',
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
}
