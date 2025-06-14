import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/classModel.dart';
import 'package:sis_project/models/manageClassSubjectsModel.dart';
import 'package:sis_project/screens/registrar/section2_content/section2_modifyclass.dart';
import 'package:sis_project/screens/registrar/section2_content/section2_registerclass.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_on_hover/animate_on_hover.dart';

class RegistrarSecondSection extends StatefulWidget {
  const RegistrarSecondSection({super.key});

  @override
  State<RegistrarSecondSection> createState() => _RegistrarSecondSectionState();
}

class _RegistrarSecondSectionState extends State<RegistrarSecondSection> {
  List<classModel> classDeployed = [];
  List<classModel> classFetch = [];

  Map<String, ManageClassModel> classDetailsMap = {};

  bool isClassListLoaded = false;
  bool isHeaderClicked = false;
  String query = '';
  double sortBy = -1;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses({bool skipInitialClear = false}) async {
    try {
      if (!skipInitialClear) {
        setState(() {
          isClassListLoaded = false;
          classFetch.clear();
          classDetailsMap.clear();
        });
      }

      final List<QuerySnapshot> departmentSnapshots = await Future.wait(
          departments.map(
              (dept) => FirebaseFirestore.instance.collection(dept).get()));

      for (int deptIndex = 0; deptIndex < departments.length; deptIndex++) {
        final snapshot = departmentSnapshots[deptIndex];

        final List<Future<void>> classProcessingTasks =
            snapshot.docs.map((classDoc) async {
          final classData = classDoc.data() as Map<String, dynamic>;
          final classCode = classData['class-code'];

          if (classCode == null) return;

          final classAdviser = classData['adviser'] ?? '';
          final classList = classData['class-list'] ?? [];
          final enrolledSubjects = classData['enrolled-subjects'] ?? [];
          final classDepartmentProgram = _deptProgOfClass(classCode);

          final manageClassModel = ManageClassModel(
            classDepartment: classDepartmentProgram,
            classCode: classCode,
            classList: List<String>.from(classList),
            enrolledSubjects: List<int>.from(enrolledSubjects),
            adviser: classAdviser,
          );

          classDetailsMap[classCode] = manageClassModel;

          final enrolledCount = classList is List ? classList.length : 0;

          final displayClassModel = classModel(
            classCode: classCode,
            classDepartment: _getDepartmentName(classDepartmentProgram),
            classProgram: _getProgramName(classDepartmentProgram),
            classLevel: _levelOfClass(classCode),
            classSection: _sectionOfClass(classCode),
            classEnrolled: enrolledCount,
          );

          classFetch.add(displayClassModel);
        }).toList();

        await Future.wait(classProcessingTasks);
      }

      if (mounted) {
        useToastify.showLoadingToast(
            context, "Fetched", "Classes fetched successfully");
        if (classFetch.length > 50)
          useToastify.showLoadingToast(
              context, "Limiter", "Showing 50 out of ${classFetch.length}");
        else
          useToastify.showLoadingToast(context, "Limiter",
              "Showing ${classFetch.length} out of ${classFetch.length}");
        setState(() {
          isClassListLoaded = true;
          classDeployed = _filteredClasses(query);
        });
      }
    } catch (e) {
      if (mounted) {
        useToastify.showErrorToast(context, "Error", "Failed to fetch classes");
      }
      print('Error fetching data: $e');
    }
  }

  Future<List<ManageClassSubjectsModel>> _fetchClassSubjects(
      String classCode) async {
    try {
      final manageClass = classDetailsMap[classCode];
      if (manageClass == null || manageClass.enrolledSubjects.isEmpty) {
        return [];
      }

      final classSubjectCodes = manageClass.enrolledSubjects
          .map((subjectId) => '$classCode:$subjectId')
          .toList();

      final subjectsQuery = await FirebaseFirestore.instance
          .collection('class-subjects')
          .where('classSubjectCode', whereIn: classSubjectCodes)
          .get();

      final List<ManageClassSubjectsModel> subjects =
          subjectsQuery.docs.map((doc) {
        final data = doc.data();
        return ManageClassSubjectsModel(
          teacherId: data['teacherId'] ?? '',
          subjectDepartment: data['subjectDepartment'] ?? '',
          subjectId: classCode,
          subjectName: data['subjectName'] ?? '',
          subjectDescription: data['subjectDescription'] ?? '',
          classSubjectCode: data['classSubjectCode'] ?? '',
          classSchedule: data['classSchedule'] ?? '',
        );
      }).toList();

      return subjects;
    } catch (e) {
      print('Error fetching class subjects: $e');
      return [];
    }
  }

  final departments = [
    'pre-dept',
    'pri-dept',
    'jhs-dept',
    'abm-dept',
    'humms-dept',
    'gas-dept',
    'ict-dept',
    'he-dept'
  ];
  String _getClassCodeFromDisplayModel(classModel displayModel) {
    for (final entry in classDetailsMap.entries) {
      final classCode = entry.key;
      final manageClass = entry.value;

      if (_levelOfClass(classCode) == displayModel.classLevel &&
          _sectionOfClass(classCode) == displayModel.classSection &&
          _getDepartmentName(manageClass.classDepartment) ==
              displayModel.classDepartment &&
          _getProgramName(manageClass.classDepartment) ==
              displayModel.classProgram) {
        return classCode;
      }
    }

    final level = displayModel.classLevel;
    final section = displayModel.classSection;
    final department = displayModel.classDepartment;

    String deptCode = '';
    switch (department) {
      case 'Pre-School':
        deptCode = 'PRE';
        break;
      case 'Primary School':
        deptCode = 'PRI';
        break;
      case 'Junior High School':
        deptCode = 'JHS';
        break;
      case 'Senior High School':
        if (displayModel.classProgram.contains('Humanities'))
          deptCode = 'HUMMS';
        else if (displayModel.classProgram.contains('Accountacy'))
          deptCode = 'ABM';
        else if (displayModel.classProgram.contains('General'))
          deptCode = 'GAS';
        else if (displayModel.classProgram.contains('Technology'))
          deptCode = 'ICT';
        else if (displayModel.classProgram.contains('Economics'))
          deptCode = 'HE';
        break;
    }

    return '$deptCode-$level-$section';
  }

//Kinder to 12 (K-12) system
  static const Map<String, String> _departmentNameMap = {
    'pre-dept': 'Pre-School',
    'pri-dept': 'Primary School',
    'jhs-dept': 'Junior High School',
    'abm-dept': 'Senior High School',
    'humms-dept': 'Senior High School',
    'gas-dept': 'Senior High School',
    'ict-dept': 'Senior High School',
    'he-dept': 'Senior High School',
  };
  static const Map<String, String> _programNameMap = {
    'pre-dept': 'Kindergarten',
    'pri-dept': 'Elementary',
    'jhs-dept': 'Junior High School',
    'abm-dept': 'Accountancy, Business, and Management',
    'humms-dept': 'Humanities and Social Sciences',
    'gas-dept': 'General Academic Strand',
    'ict-dept': 'Information, Communication, and Technology',
    'he-dept': 'Home Economics'
  };
  static const Map<String, String> _deptProgMap = {
    'HE': 'he-dept',
    'ICT': 'ict-dept',
    'GAS': 'gas-dept',
    'HUMMS': 'humms-dept',
    'ABM': 'abm-dept',
    'JHS': 'jhs-dept',
    'PRI': 'pri-dept',
    'PRE': 'pre-dept',
  };
  String _deptProgOfClass(String identifier) {
    final code = identifier.split('-')[0];
    return _deptProgMap[code] ?? 'N/A';
  }

  String _getDepartmentName(String identifier) {
    return _departmentNameMap[identifier] ?? 'N/A';
  }

  String _getProgramName(String identifier) {
    return _programNameMap[identifier] ?? 'N/A';
  }

  String _levelOfClass(String classSubjectCode) {
    final parts = classSubjectCode.split(':')[0].split('-');
    return parts.length > 1 ? parts[1] : '';
  }

  String _sectionOfClass(String classSubjectCode) {
    final parts = classSubjectCode.split(':')[0].split('-');
    return parts.length > 2 ? parts[2] : '';
  }

  List<classModel> _filteredClasses(String query) {
    List<classModel> filteredClasses;

    if (query.isEmpty) {
      filteredClasses = List.from(classFetch);
    } else {
      final lowerQuery = query.toLowerCase();
      final upperQuery = query.toUpperCase();
      filteredClasses = classFetch.where((_class) {
        return _class.classCode.toUpperCase().contains(upperQuery) ||
            _class.classDepartment.toLowerCase().contains(lowerQuery) ||
            _class.classProgram.toLowerCase().contains(lowerQuery) ||
            _class.classLevel.toLowerCase().contains(lowerQuery) ||
            _class.classSection.toLowerCase().contains(lowerQuery) ||
            _class.classEnrolled.toString().contains(lowerQuery);
      }).toList();
    }

    switch (sortBy) {
      case 0:
        filteredClasses
            .sort((a, b) => a.classDepartment.compareTo(b.classDepartment));
        break;
      case 0.5:
        filteredClasses
            .sort((a, b) => b.classDepartment.compareTo(a.classDepartment));
        break;
      case 1:
        filteredClasses
            .sort((a, b) => a.classProgram.compareTo(b.classProgram));
        break;
      case 1.5:
        filteredClasses
            .sort((a, b) => b.classProgram.compareTo(a.classProgram));
        break;
      case 2:
        filteredClasses.sort((a, b) => a.classLevel.compareTo(b.classLevel));
        break;
      case 2.5:
        filteredClasses.sort((a, b) => b.classLevel.compareTo(a.classLevel));
        break;
      case 3:
        filteredClasses
            .sort((a, b) => a.classSection.compareTo(b.classSection));
        break;
      case 3.5:
        filteredClasses
            .sort((a, b) => b.classSection.compareTo(a.classSection));
        break;
      case 4:
        filteredClasses
            .sort((a, b) => a.classEnrolled.compareTo(b.classEnrolled));
        break;
      case 4.5:
        filteredClasses
            .sort((a, b) => b.classEnrolled.compareTo(a.classEnrolled));
        break;
      default:
        filteredClasses.sort((a, b) {
          final departmentOrder = {
            'Pre-School': 1,
            'Primary School': 2,
            'Junior High School': 3,
            'Senior High School': 4,
          };
          final deptA = departmentOrder[a.classDepartment] ?? 999;
          final deptB = departmentOrder[b.classDepartment] ?? 999;
          if (deptA != deptB) return deptA.compareTo(deptB);

          final levelA = int.tryParse(a.classLevel) ?? 0;
          final levelB = int.tryParse(b.classLevel) ?? 0;
          if (levelA != levelB) return levelA.compareTo(levelB);

          return a.classSection.compareTo(b.classSection);
        });
    }

    return filteredClasses.take(50).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      classDeployed = _filteredClasses(query);
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'DEPARTMENT':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'PROGRAM':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'LEVEL':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        case 'SECTION':
          newSortBy = isHeaderClicked ? 3.5 : 3;
          break;
        case 'ENROLLED':
          newSortBy = isHeaderClicked ? 4.5 : 4;
          break;
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      classDeployed = _filteredClasses(query);
    });
  }

  Future<void> _refreshClassList() async {
    setState(() {
      isClassListLoaded = false;
      classFetch.clear();
      classDeployed.clear();
      classDetailsMap.clear();
    });
    await _fetchClasses(skipInitialClear: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      floatingActionButton: _buildModernFloatingActionButton(),
      body: RefreshIndicator(
        onRefresh: _refreshClassList,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(
              DynamicSizeService.calculateAspectRatioSize(context, 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildClassManagementSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                HugeIcons.strokeRoundedSchool,
                color: Colors.white,
                size:
                    DynamicSizeService.calculateAspectRatioSize(context, 0.04),
              ),
              const SizedBox(width: 12),
              Text(
                "Class Management",
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.032),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Register, manage, and organize classes across all departments',
            style: GoogleFonts.montserrat(
              fontSize:
                  DynamicSizeService.calculateAspectRatioSize(context, 0.016),
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Overview',
          style: GoogleFonts.montserrat(
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.024),
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildModernSearchBar(),
        const SizedBox(height: 16),
        _buildModernClassTable(),
      ],
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
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
      child: TextField(
        decoration: InputDecoration(
          hintText:
              "Search by department, program, level, section, or enrollment...",
          hintStyle: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search_outlined,
            color: Colors.grey.shade500,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        style: GoogleFonts.montserrat(fontSize: 14),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildModernClassTable() {
    return Container(
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
      child: Column(
        children: [
          _buildModernTableHeader(),
          const Divider(height: 1),
          isClassListLoaded ? _buildClassesList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderCell("DEPARTMENT")),
          Expanded(flex: 3, child: _buildHeaderCell("PROGRAM")),
          Expanded(flex: 1, child: _buildHeaderCell("LEVEL")),
          Expanded(flex: 1, child: _buildHeaderCell("SECTION")),
          Expanded(flex: 1, child: _buildHeaderCell("ENROLLED")),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return InkWell(
      onTap: () => _onHeaderTap(text),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Text(
              text,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isHeaderClicked
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 16,
              color: _primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    if (classDeployed.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernClassRow(classDeployed[index]);
      },
    );
  }

  Widget _buildModernClassRow(classModel displayClassModel) {
    return InkWell(
      onTap: () async {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: _primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Loading class details...',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          final classCode = _getClassCodeFromDisplayModel(displayClassModel);
          final manageClass = classDetailsMap[classCode];

          if (manageClass == null) {
            Navigator.pop(context);
            if (mounted) {
              useToastify.showErrorToast(
                  context, "Error", "Class details not found");
            }
            return;
          }

          final classSubjects = await _fetchClassSubjects(classCode);

          if (mounted) {
            Navigator.pop(context);

            showDialog(
              context: context,
              builder: (context) => ModifyClassDialog(
                classModel: manageClass,
                subjectModels: classSubjects,
                onRefresh: _refreshClassList,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            useToastify.showErrorToast(
                context, "Error", "Failed to load class details");
          }
          print('Error loading class details: $e');
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayClassModel.classDepartment,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    displayClassModel.classCode,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                displayClassModel.classProgram,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayClassModel.classLevel,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayClassModel.classSection,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIcons.strokeRoundedStudentCard,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${displayClassModel.classEnrolled}',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            HugeIcons.strokeRoundedSchool,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No classes found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or register a new class',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildModernFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                RegisterClassDialog(onRefresh: _refreshClassList),
          );
        },
      ),
    ).increaseSizeOnHover(1.1);
  }
}
