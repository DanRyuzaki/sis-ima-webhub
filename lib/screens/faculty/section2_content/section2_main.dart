import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/classesModel.dart';
import 'package:sis_project/screens/faculty/section2_content/section2_viewadvisoryclass.dart';
import 'package:sis_project/screens/faculty/section2_content/section2_viewsubjectclass.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class FacultySecondSection extends StatefulWidget {
  const FacultySecondSection({super.key});

  @override
  State<FacultySecondSection> createState() => _FacultySecondSectionState();
}

class _FacultySecondSectionState extends State<FacultySecondSection> {
  bool isAdvisoryClassListLoaded = false,
      isSubjectClassListLoaded = false,
      isHeaderClicked = false,
      isCurrentTabLoaded = false;
  String query = '';
  double sortBy = -1;
  List<classSubjectModel> advisoryClassFetch = [], subjectClassFetch = [];
  List<classSubjectModel> advisoryClassDeployed = [], subjectClassDeployed = [];
  Map<String, List<classSubjectModel>> groupedAdvisoryClasses = {};

  List<String> tableItems = ['Advisory Classes', 'Subject Classes'];
  int currentTableItem = 0;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchAdvisoryClass();
    _fetchSubjectClass();
  }

  Future<void> _fetchAdvisoryClass() async {
    try {
      final userID = Provider.of<GlobalState>(context, listen: false).userID;
      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final advisoryListQS =
          await entityCollection.where("userID", isEqualTo: userID).get();

      advisoryClassFetch.clear();
      groupedAdvisoryClasses.clear();

      for (var doc in advisoryListQS.docs) {
        final advisoryClasses = doc.data()['advisoryClassId'];

        if (advisoryClasses is List) {
          for (var advisory in advisoryClasses) {
            if (advisory is String) {
              final classSubjectCode = await advisory;
              final classSubject = await _subjectOfClass(advisory);
              final classDepartment = await _departmentOfClass(advisory);
              final classProgram = await _programOfClass(advisory);
              final classLevel = await _levelOfClass(advisory);
              final classSection = await _sectionOfClass(advisory);
              final classEnrolled = await _enrolledInClass(
                classDepartment,
                advisory.split(':')[0],
              );

              var classModel = classSubjectModel(
                  classCode: classSubjectCode.split(':')[0],
                  classSubjectCode:
                      "${classSubjectCode.split(':')[0].split('-')[0]}-${classSubjectCode.split(':')[1]}",
                  classClassSubjectCode: classSubjectCode,
                  classSubject: classSubject,
                  classDepartment: _getDepartmentName(classDepartment),
                  classProgram: _getProgramName(classProgram),
                  classLevel: classLevel,
                  classSection: classSection,
                  classEnrolled: classEnrolled,
                  teacherId: userID);

              advisoryClassFetch.add(classModel);

              String classCode = classModel.classCode;
              if (!groupedAdvisoryClasses.containsKey(classCode)) {
                groupedAdvisoryClasses[classCode] = [];
              }
              groupedAdvisoryClasses[classCode]!.add(classModel);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          isAdvisoryClassListLoaded = true;
          advisoryClassDeployed = __filteredAdvisoryClasses(query);
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        isAdvisoryClassListLoaded = true;
        advisoryClassFetch = [];
        advisoryClassDeployed = [];
        groupedAdvisoryClasses = {};
      });
    }
  }

  Future<void> _fetchSubjectClass() async {
    try {
      final userID = Provider.of<GlobalState>(context, listen: false).userID;
      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final advisoryListQS =
          await entityCollection.where("userID", isEqualTo: userID).get();

      for (var doc in advisoryListQS.docs) {
        final advisoryClasses = doc.data()['subjectsList'];

        if (advisoryClasses is List) {
          for (var advisory in advisoryClasses) {
            if (advisory is String) {
              final isClassValidQS = await FirebaseFirestore.instance
                  .collection("class-subjects")
                  .where("classSubjectCode", isEqualTo: advisory)
                  .where("teacherId", isEqualTo: userID)
                  .get();

              if (isClassValidQS.docs.isEmpty)
                subjectClassFetch.add(
                  classSubjectModel(
                      classCode: 'N/A',
                      classSubjectCode: 'N/A',
                      classClassSubjectCode: 'N/A',
                      classSubject: 'N/A',
                      classDepartment: 'N/A',
                      classProgram: 'N/A',
                      classLevel: 'N/A',
                      classSection: 'N/A',
                      classEnrolled: 0,
                      teacherId: userID),
                );
              else {
                final classSubjectCode = await advisory;
                final classSubject = await _subjectOfClass(advisory);
                final classDepartment = await _departmentOfClass(advisory);
                final classProgram = await _programOfClass(advisory);
                final classLevel = await _levelOfClass(advisory);
                final classSection = await _sectionOfClass(advisory);
                final classEnrolled = await _enrolledInClass(
                  classDepartment,
                  advisory.split(':')[0],
                );

                subjectClassFetch.add(
                  classSubjectModel(
                      classCode: classSubjectCode.split(':')[0],
                      classSubjectCode:
                          "${classSubjectCode.split(':')[0].split('-')[0]}-${classSubjectCode.split(':')[1]}",
                      classClassSubjectCode: classSubjectCode,
                      classSubject: classSubject,
                      classDepartment: _getDepartmentName(classDepartment),
                      classProgram: _getProgramName(classProgram),
                      classLevel: classLevel,
                      classSection: classSection,
                      classEnrolled: classEnrolled,
                      teacherId: userID),
                );
              }
            }
          }
        }
      }

      if (mounted)
        setState(() {
          isSubjectClassListLoaded = true;
          subjectClassDeployed = __filteredSubjectClasses(query);
        });
    } catch (e) {
      print(e);
      setState(() {
        isSubjectClassListLoaded = true;
        subjectClassFetch = [];
        subjectClassDeployed = [];
      });
    }
  }

  Future<String> _subjectOfClass(identifier) async {
    final entityCollection =
        FirebaseFirestore.instance.collection("class-subjects");
    final advisoryListQS = await entityCollection
        .where("classSubjectCode", isEqualTo: identifier)
        .get();

    if (advisoryListQS.docs.isNotEmpty) {
      final doc = advisoryListQS.docs.first;
      return doc.data()['subjectName'];
    } else {
      return 'N/A';
    }
  }

  Future<String> _departmentOfClass(identifier) async {
    final entityCollection =
        FirebaseFirestore.instance.collection("class-subjects");
    final advisoryListQS = await entityCollection
        .where("classSubjectCode", isEqualTo: identifier)
        .get();

    if (advisoryListQS.docs.isNotEmpty) {
      final doc = advisoryListQS.docs.first;
      return doc.data()['subjectDepartment'];
    } else {
      return 'N/A';
    }
  }

  String _getDepartmentName(identifier) {
    switch (identifier) {
      case 'pre-dept':
        return 'Pre-School';
      case 'pri-dept':
        return 'Primary School';
      case 'jhs-dept':
        return 'Junior High School';
      case 'abm-dept':
        return 'Senior High School';
      case 'humms-dept':
        return 'Senior High School';
      case 'gas-dept':
        return 'Senior High School';
      case 'ict-dept':
        return 'Senior High School';
      case 'he-dept':
        return 'Senior High School';

      default:
        return 'N/A';
    }
  }

  Future<String> _programOfClass(identifier) async {
    final entityCollection =
        FirebaseFirestore.instance.collection("class-subjects");
    final advisoryListQS = await entityCollection
        .where("classSubjectCode", isEqualTo: identifier)
        .get();

    if (advisoryListQS.docs.isNotEmpty) {
      final doc = advisoryListQS.docs.first;
      return doc.data()['subjectDepartment'];
    } else {
      return 'N/A';
    }
  }

  String _getProgramName(identifier) {
    switch (identifier) {
      case 'pre-dept':
        return 'Kindergarten';
      case 'pri-dept':
        return 'Elementary';
      case 'jhs-dept':
        return 'Junior High School';
      case 'abm-dept':
        return 'Accountancy, Business, and Management';
      case 'humms-dept':
        return 'Humanities and Social Sciences';
      case 'gas-dept':
        return 'General Academic Strand';
      case 'ict-dept':
        return 'Information, Communication, and Technology';
      case 'he-dept':
        return 'Home Economics';
      default:
        return 'N/A';
    }
  }

  String _levelOfClass(classSubjectCode) {
    final parts = classSubjectCode.split(':')[0].split('-');
    return parts.length > 1 ? parts[1] : '';
  }

  String _sectionOfClass(String classSubjectCode) {
    final parts = classSubjectCode.split(':')[0].split('-');
    return parts.length > 2 ? parts[2] : '';
  }

  Future<int> _enrolledInClass(deptCode, classCode) async {
    try {
      final entityCollection = FirebaseFirestore.instance.collection(deptCode);
      final advisoryListQS = await entityCollection
          .where("class-code", isEqualTo: classCode)
          .get();

      if (advisoryListQS.docs.isNotEmpty) {
        final docData = advisoryListQS.docs.first.data();
        final rawList = docData['class-list'];

        if (rawList is List) {
          final classList = rawList.cast<String>();
          return classList.length;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching enrolled count: $e');
      return 0;
    }
  }

  List<classSubjectModel> __filteredAdvisoryClasses(String query) {
    Map<String, List<classSubjectModel>> groupedClasses = {};

    for (var classItem in advisoryClassFetch) {
      String classCode = classItem.classCode;
      if (!groupedClasses.containsKey(classCode)) {
        groupedClasses[classCode] = [];
      }
      groupedClasses[classCode]!.add(classItem);
    }

    List<classSubjectModel> consolidatedClasses = [];

    groupedClasses.forEach((classCode, classList) {
      if (classList.length == 1) {
        consolidatedClasses.add(classList.first);
      } else {
        var primaryClass = classList.first;
        var additionalCount = classList.length - 1;

        var consolidatedClass = classSubjectModel(
          classCode: primaryClass.classCode,
          classSubjectCode:
              "${primaryClass.classSubjectCode} + $additionalCount other${additionalCount > 1 ? 's' : ''}",
          classClassSubjectCode: primaryClass.classClassSubjectCode,
          classSubject:
              "${primaryClass.classSubject} + $additionalCount other${additionalCount > 1 ? 's' : ''}",
          classDepartment: primaryClass.classDepartment,
          classProgram: primaryClass.classProgram,
          classLevel: primaryClass.classLevel,
          classSection: primaryClass.classSection,
          classEnrolled: primaryClass.classEnrolled,
          teacherId: primaryClass.teacherId,
        );

        consolidatedClasses.add(consolidatedClass);
      }
    });

    final filteredClasses = query.isEmpty
        ? consolidatedClasses
        : consolidatedClasses.where((_class) {
            return _class.classSubject
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _class.classDepartment
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _class.classProgram
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _class.classLevel.toLowerCase().contains(query.toLowerCase()) ||
                _class.classSection
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _class.classEnrolled
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredClasses
            .sort((a, b) => a.classSubject.compareTo(b.classSubject));
      case 0.5:
        filteredClasses
            .sort((a, b) => b.classSubject.compareTo(a.classSubject));
      case 1:
        filteredClasses
            .sort((a, b) => a.classDepartment.compareTo(b.classDepartment));
      case 1.5:
        filteredClasses
            .sort((a, b) => b.classDepartment.compareTo(a.classDepartment));
      case 2:
        filteredClasses
            .sort((a, b) => a.classProgram.compareTo(b.classProgram));
      case 2.5:
        filteredClasses
            .sort((a, b) => b.classProgram.compareTo(a.classProgram));
      case 3:
        filteredClasses.sort((a, b) => a.classLevel.compareTo(b.classLevel));
      case 3.5:
        filteredClasses.sort((a, b) => b.classLevel.compareTo(a.classLevel));
      case 4:
        filteredClasses
            .sort((a, b) => a.classSection.compareTo(b.classSection));
      case 4.5:
        filteredClasses
            .sort((a, b) => b.classSection.compareTo(a.classSection));
      case 5:
        filteredClasses
            .sort((a, b) => a.classEnrolled.compareTo(b.classEnrolled));
      case 5.5:
        filteredClasses
            .sort((a, b) => b.classEnrolled.compareTo(a.classEnrolled));
      default:
        filteredClasses.sort((a, b) => a.classLevel.compareTo(b.classLevel));
    }

    return filteredClasses.take(50).toList();
  }

  List<classSubjectModel> __filteredSubjectClasses(String query) {
    final filteredClasses = query.isEmpty
        ? subjectClassFetch
        : subjectClassFetch.where((_class) {
            return _class.classSubject
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _class.classDepartment
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _class.classProgram
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _class.classLevel.toLowerCase().contains(query.toLowerCase()) ||
                _class.classSection
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _class.classEnrolled
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredClasses
            .sort((a, b) => a.classSubject.compareTo(b.classSubject));
      case 0.5:
        filteredClasses
            .sort((a, b) => b.classSubject.compareTo(a.classSubject));
      case 1:
        filteredClasses
            .sort((a, b) => a.classDepartment.compareTo(b.classDepartment));
      case 1.5:
        filteredClasses
            .sort((a, b) => b.classDepartment.compareTo(a.classDepartment));
      case 2:
        filteredClasses
            .sort((a, b) => a.classProgram.compareTo(b.classProgram));
      case 2.5:
        filteredClasses
            .sort((a, b) => b.classProgram.compareTo(a.classProgram));
      case 3:
        filteredClasses.sort((a, b) => a.classLevel.compareTo(b.classLevel));
      case 3.5:
        filteredClasses.sort((a, b) => b.classLevel.compareTo(a.classLevel));
      case 4:
        filteredClasses
            .sort((a, b) => a.classSection.compareTo(b.classSection));
      case 4.5:
        filteredClasses
            .sort((a, b) => b.classSection.compareTo(a.classSection));
      case 5:
        filteredClasses
            .sort((a, b) => a.classEnrolled.compareTo(b.classEnrolled));
      case 5.5:
        filteredClasses
            .sort((a, b) => b.classSection.compareTo(a.classSection));
      default:
        filteredClasses.sort((a, b) => a.classLevel.compareTo(b.classLevel));
    }
    return filteredClasses.take(50).toList();
  }

  @override
  Widget build(BuildContext context) {
    isCurrentTabLoaded = currentTableItem == 0
        ? isAdvisoryClassListLoaded
        : isSubjectClassListLoaded;

    return Scaffold(
      backgroundColor: _lightGray,
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
                _buildTabSwitcher(),
                const SizedBox(height: 16),
                _buildModernSearchBar(),
                const SizedBox(height: 16),
                _buildModernClassTable(),
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
                "Manage Classes",
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
            'View and manage your advisory and teaching classes.',
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

  Widget _buildTabSwitcher() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DynamicSizeService.calculateWidthSize(context, 0.01),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: DynamicSizeService.calculateAspectRatioSize(context, 0.015),
            child: Divider(thickness: 1.5, color: Colors.grey),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DynamicSizeService.calculateWidthSize(context, 0.009),
            ),
            child: InkWell(
              onTap: _handleTabSwitch,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right:
                          DynamicSizeService.calculateWidthSize(context, 0.004),
                    ),
                    child: Icon(
                      HugeIcons.strokeRoundedCardExchange02,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    tableItems[currentTableItem],
                    style: TextStyle(
                      fontSize: DynamicSizeService.calculateAspectRatioSize(
                          context, 0.019),
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 74, 208),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
            child: Divider(thickness: 1.5, color: Colors.grey),
          ),
        ],
      ),
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
          isCurrentTabLoaded ? _buildClassList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderCell("SUBJECT")),
          Expanded(flex: 2, child: _buildHeaderCell("DEPARTMENT")),
          Expanded(flex: 2, child: _buildHeaderCell("PROGRAM")),
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

  Widget _buildClassList() {
    final currentList =
        currentTableItem == 0 ? advisoryClassDeployed : subjectClassDeployed;
    final sourceList =
        currentTableItem == 0 ? advisoryClassFetch : subjectClassFetch;

    if (sourceList.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentList.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernClassRow(currentList[index]);
      },
    );
  }

  Widget _buildModernClassRow(classSubjectModel classModel) {
    bool isConsolidated = classModel.classSubject.contains('+ ') &&
        classModel.classSubject.contains('other');

    return InkWell(
      onTap: () async {
        final dept = await _departmentOfClass(classModel.classClassSubjectCode);
        if (currentTableItem == 0) {
          showDialog(
            context: context,
            builder: (context) => ViewAdvisoryClassDialog(
              departmentCode: dept,
              classCode: classModel.classCode,
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => ViewSubjectClassDialog(
              departmentCode: dept,
              classCode: classModel.classCode,
              subjectId: classModel.classSubjectCode,
              teacherId: classModel.teacherId,
            ),
          );
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
                    classModel.classSubject,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isConsolidated
                          ? Colors.blue.shade700
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    classModel.classSubjectCode,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (isConsolidated)
                    Text(
                      'Tap to view all subjects',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        color: Colors.blue.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                classModel.classDepartment,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                classModel.classProgram,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
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
                  classModel.classLevel,
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
                  classModel.classSection,
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
                    '${classModel.classEnrolled}',
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
            'Try adjusting your search terms or contact the registrar for inquiries.',
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

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      advisoryClassDeployed = __filteredAdvisoryClasses(query);
      subjectClassDeployed = __filteredSubjectClasses(query);
    });
  }

  Future<void> _refreshClassList() async {
    setState(() {
      isAdvisoryClassListLoaded = false;
      isSubjectClassListLoaded = false;
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'SUBJECT':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'DEPARTMENT':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'PROGRAM':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        case 'LEVEL':
          newSortBy = isHeaderClicked ? 3.5 : 3;
          break;
        case 'SECTION':
          newSortBy = isHeaderClicked ? 4.5 : 4;
          break;
        case 'ENROLLED':
          newSortBy = isHeaderClicked ? 5.5 : 5;
          break;
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      advisoryClassDeployed = __filteredAdvisoryClasses(query);
      subjectClassDeployed = __filteredSubjectClasses(query);
    });
  }

  void _handleTabSwitch() {
    if (isAdvisoryClassListLoaded && isSubjectClassListLoaded)
      setState(() {
        currentTableItem = currentTableItem == 0 ? 1 : 0;
      });
    else
      useToastify.showErrorToast(
          context, 'Info', 'Please wait until the data are deployed.');
  }
}
