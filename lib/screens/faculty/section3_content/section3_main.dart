import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/studentModel.dart';
import 'package:sis_project/models/studentProfileModel.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/screens/faculty/section3_content/section3_viewstudent.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class FacultyThirdSection extends StatefulWidget {
  const FacultyThirdSection({super.key});

  @override
  State<FacultyThirdSection> createState() => _FacultyThirdSectionState();
}

class _FacultyThirdSectionState extends State<FacultyThirdSection> {
  bool isAdvisoryStudentListLoaded = false, isHeaderClicked = false;
  String query = '';
  double sortBy = -1;
  List<studentModel> advisoryStudentsFetch = [];
  List<studentModel> advisoryStudentsDeployed = [];
  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchAdvisoryStudents();
  }

  Future<void> _fetchAdvisoryStudents() async {
    try {
      final userID = Provider.of<GlobalState>(context, listen: false).userID;
      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final advisoryListQS =
          await entityCollection.where("userID", isEqualTo: userID).get();

      for (var doc in advisoryListQS.docs) {
        final advisoryClasses = doc.data()['advisoryClassId'];

        if (advisoryClasses is List) {
          for (var advisory in advisoryClasses) {
            if (advisory is String) {
              final studentID = await _getStudentList(
                advisory.split('-')[0],
                advisory.split(':')[0],
              );

              for (var student in studentID) {
                final studentSID = await _IDOfStudent(student);
                final studentName = await _nameOfStudent(student);
                final studentProgram = await _programOfStudent(advisory);
                final studentLevel = await _levelOfStudent(advisory);
                final studentSection = await _sectionOfStudent(advisory);

                final existingStudent = advisoryStudentsFetch
                    .any((student) => student.studentSID == studentSID);
                if (!existingStudent) {
                  advisoryStudentsFetch.add(
                    studentModel(
                      studentSID: studentSID,
                      studentName: studentName,
                      studentClassCode: advisory.split(':')[0],
                      studentProgram: _getProgramName(studentProgram),
                      studentLevel: studentLevel,
                      studentSection: studentSection,
                    ),
                  );
                }
              }
            }
          }
        }
      }

      if (mounted)
        setState(() {
          isAdvisoryStudentListLoaded = true;
          advisoryStudentsDeployed = __filteredAdvisoryStudents(query);
        });
    } catch (e) {
      print(e);
    }
  }

  Future<List<String>> _getStudentList(String classDept, String classID) async {
    final studentCollection =
        FirebaseFirestore.instance.collection(_convertClassDept(classDept));
    final studentQS =
        await studentCollection.where("class-code", isEqualTo: classID).get();

    for (var doc in studentQS.docs) {
      final studentID = doc.data()['class-list'];
      if (studentID is List) {
        return studentID.map((e) => e.toString()).toList();
      } else {
        return ['N/A'];
      }
    }

    return ['N/A'];
  }

  String _convertClassDept(String identifier) {
    switch (identifier) {
      case 'PRE':
        return 'pre-dept';
      case 'PRI':
        return 'pri-dept';
      case 'JHS':
        return 'jhs-dept';
      case 'ABM':
        return 'abm-dept';
      case 'HUMMS':
        return 'humms-dept';
      case 'GAS':
        return 'gas-dept';
      case 'ICT':
        return 'ict-dept';
      case 'HE':
        return 'Home Economics';
      default:
        return 'N/A';
    }
  }

  Future<String> _IDOfStudent(String studentID) async {
    final studentCollection = FirebaseFirestore.instance.collection("entity");
    final studentQS =
        await studentCollection.where("userID", isEqualTo: studentID).get();

    if (studentQS.docs.isNotEmpty) {
      final studentData = studentQS.docs.first.data();
      return studentData['userID'] ?? 'N/A';
    } else {
      return 'N/A';
    }
  }

  Future<String> _nameOfStudent(String studentID) async {
    final studentCollection = FirebaseFirestore.instance.collection("entity");
    final studentQS =
        await studentCollection.where("userID", isEqualTo: studentID).get();

    if (studentQS.docs.isNotEmpty) {
      final studentData = studentQS.docs.first.data();
      return "${studentData['userName00']} ${studentData['userName01']}";
    } else {
      return 'N/A';
    }
  }

  Future<String> _programOfStudent(identifier) async {
    final entityCollection =
        FirebaseFirestore.instance.collection("class-subjects");
    final advisoryListQS = await entityCollection
        .where("classSubjectCode", isEqualTo: identifier)
        .get();

    if (advisoryListQS.docs.isNotEmpty) {
      final doc = advisoryListQS.docs.first;
      final subjectDept = doc.data()['subjectDepartment'];
      return subjectDept;
    } else {
      return 'N/A';
    }
  }

  String _getProgramName(String identifier) {
    switch (identifier) {
      case 'pre-dept':
        return 'Pre-School';
      case 'pri-dept':
        return 'Primary School';
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

  String _levelOfStudent(String classSubjectCode) {
    final parts = classSubjectCode.split(':')[0].split('-');
    return parts.length > 1 ? parts[1] : '';
  }

  String _sectionOfStudent(String classSubjectCode) {
    final parts = classSubjectCode.split(':')[0].split('-');
    return parts.length > 2 ? parts[2] : '';
  }

  List<studentModel> __filteredAdvisoryStudents(String query) {
    final filteredStudents = query.isEmpty
        ? advisoryStudentsFetch
        : advisoryStudentsFetch.where((_students) {
            return _students.studentClassCode
                    .toUpperCase()
                    .contains(query.toUpperCase()) ||
                _students.studentSID
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _students.studentName
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _students.studentProgram
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _students.studentLevel
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                _students.studentSection
                    .toLowerCase()
                    .contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredStudents.sort((a, b) => a.studentSID.compareTo(b.studentSID));
        break;
      case 0.5:
        filteredStudents.sort((a, b) => b.studentSID.compareTo(a.studentSID));
        break;
      case 1:
        filteredStudents.sort((a, b) => a.studentName.compareTo(b.studentName));
        break;
      case 1.5:
        filteredStudents.sort((a, b) => b.studentName.compareTo(a.studentName));
        break;
      case 2:
        filteredStudents
            .sort((a, b) => a.studentProgram.compareTo(b.studentProgram));
        break;
      case 2.5:
        filteredStudents
            .sort((a, b) => b.studentProgram.compareTo(a.studentProgram));
        break;
      case 3:
        filteredStudents
            .sort((a, b) => a.studentLevel.compareTo(b.studentLevel));
        break;
      case 3.5:
        filteredStudents
            .sort((a, b) => b.studentLevel.compareTo(a.studentLevel));
        break;
      case 4:
        filteredStudents
            .sort((a, b) => a.studentSection.compareTo(b.studentSection));
        break;
      case 4.5:
        filteredStudents
            .sort((a, b) => b.studentSection.compareTo(a.studentSection));
        break;
      default:
        filteredStudents.sort((a, b) => a.studentSID.compareTo(b.studentSID));
        break;
    }
    return filteredStudents.take(50).toList();
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
                HugeIcons.strokeRoundedStudentCard,
                color: Colors.white,
                size:
                    DynamicSizeService.calculateAspectRatioSize(context, 0.04),
              ),
              const SizedBox(width: 12),
              Text(
                "Manage Advisory",
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
            'View and manage your advisory class students.',
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

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      advisoryStudentsDeployed = __filteredAdvisoryStudents(query);
    });
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
          hintText: "Search by ID, name, or program...",
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

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderCell("STUDENT ID")),
          Expanded(flex: 3, child: _buildHeaderCell("NAME")),
          Expanded(flex: 2, child: _buildHeaderCell("PROGRAM")),
          Expanded(flex: 1, child: _buildHeaderCell("LEVEL")),
          Expanded(flex: 1, child: _buildHeaderCell("SECTION")),
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
              text.replaceAll('_', ' '),
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

  Future<void> _refreshStudentsList() async {
    setState(() {
      advisoryStudentsFetch.clear();
      advisoryStudentsDeployed.clear();
      isAdvisoryStudentListLoaded = false;
    });
  }

  Widget _buildModernStudentRow(studentModel student) {
    return InkWell(
      onTap: () => _onRowTapped(student),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  student.studentSID,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Text(
                student.studentProgram,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Text(
                student.studentLevel,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Text(
                student.studentSection,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
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
            HugeIcons.strokeRoundedStudentCard,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or contact the registrar for inquiries',
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

  Widget _buildClassList() {
    final currentList = advisoryStudentsDeployed;

    final sourceList = advisoryStudentsFetch;

    if (sourceList.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        return _buildModernStudentRow(currentList[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentTabLoaded = isAdvisoryStudentListLoaded;

    return Scaffold(
      backgroundColor: _lightGray,
      body: RefreshIndicator(
        onRefresh: _refreshStudentsList,
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
                _buildModernSearchBar(),
                const SizedBox(height: 16),
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
                  child: Column(
                    children: [
                      _buildModernTableHeader(),
                      const Divider(height: 1),
                      isCurrentTabLoaded
                          ? _buildClassList()
                          : _buildLoadingIndicator(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'STUDENT ID':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'NAME':
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
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      advisoryStudentsDeployed = __filteredAdvisoryStudents(query);
    });
  }

  void _onRowTapped(studentModel student) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
          ),
        ),
      );

      studentProfileModel studentProfile = studentProfileModel(
        studentId: 'N/A',
        entryYear: 'N/A',
        enrolledClass: 'N/A',
        address: 'N/A',
        dateOfBirth: Timestamp(0, 0),
        religion: 'N/A',
        contactNumber: 'N/A',
        fatherName00: 'N/A',
        fatherName01: 'N/A',
        fatherName02: 'N/A',
        fatherOccupation: 'N/A',
        fatherContact: 'N/A',
        motherName00: 'N/A',
        motherName01: 'N/A',
        motherName02: 'N/A',
        motherOccupation: 'N/A',
        motherContact: 'N/A',
        guardianName00: 'N/A',
        guardianName01: 'N/A',
        guardianName02: 'N/A',
        guardianOccupation: 'N/A',
        guardianContact: 'N/A',
        guardianRelation: 'N/A',
        birthCertificate: false,
        form137: false,
      );

      AuthenticationModel user = AuthenticationModel(
        userID: 'N/A',
        firstName: 'N/A',
        lastName: 'N/A',
        middleName: 'N/A',
        entityType: 3,
        userMail: 'N/A',
        userKey: 'N/A',
        lastSession: Timestamp(0, 0),
      );

      final profileCollection =
          FirebaseFirestore.instance.collection("profile-information");
      final profileQuery = await profileCollection
          .where("studentId", isEqualTo: student.studentSID)
          .get();

      if (profileQuery.docs.isNotEmpty) {
        final profileData = profileQuery.docs.first.data();
        studentProfile = studentProfileModel.fromMap(profileData);
      }

      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final authQuery = await entityCollection
          .where("userID", isEqualTo: student.studentSID)
          .get();

      if (authQuery.docs.isNotEmpty) {
        final authData = authQuery.docs.first.data();
        user = AuthenticationModel(
          userID: authData['userID'] ?? 'N/A',
          firstName: authData['userName00'] ?? 'N/A',
          lastName: authData['userName01'] ?? 'N/A',
          middleName: authData['userName02'] ?? '',
          entityType: (authData['entity'] as num?)?.toDouble() ?? 3.0,
          userMail: authData['userMail'] ?? 'N/A',
          userKey: authData['userKey'] ?? 'N/A',
          lastSession: authData['lastSession'] ?? Timestamp.now(),
        );
      }

      Navigator.of(context).pop();

      showDialog(
          context: context,
          builder: (context) => ViewAdvisoryDialog(
                onRefresh: _refreshStudentsList,
                studentDataDeployed: [],
                authDataDeployed: [],
                studentToModify: studentProfile,
                authDataToModify: user,
              ));
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load student details. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Error loading student details: $e");
    }
  }
}
