import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/gradesModel.dart';
import 'package:sis_project/screens/student/section3_content/section3_viewgrade.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';

class StudentThirdSection extends StatefulWidget {
  const StudentThirdSection({super.key});

  @override
  State<StudentThirdSection> createState() => _StudentThirdSectionState();
}

class _StudentThirdSectionState extends State<StudentThirdSection> {
  final List<gradesModel> _allGrades = [];
  bool _isLoading = true;
  bool _isEnrolled = false;
  String _enrollmentMessage = '';
  String _searchQuery = '';
  bool _isHeaderClicked = false;
  double _sortBy = 0;

  TextEditingController _searchController = TextEditingController();
  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  static const _departmentMapping = {
    'PRE': 'pre-dept',
    'PRI': 'pri-dept',
    'JHS': 'jhs-dept',
    'ABM': 'abm-dept',
    'HUMMS': 'humms-dept',
    'GAS': 'gas-dept',
    'ICT': 'ict-dept',
    'HE': 'he-dept'
  };

  @override
  void initState() {
    super.initState();
    final querySubject = Uri.base.queryParameters['subject'] ?? '';
    if (querySubject.isNotEmpty) {
      _searchController.text = querySubject;
      _searchQuery = querySubject;
    }
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
      _allGrades.clear();
      _isEnrolled = false;
      _enrollmentMessage = '';
    });

    try {
      final globalState = Provider.of<GlobalState>(context, listen: false);
      final studentId = globalState.userID;

      final enrollmentCheck = await _verifyEnrollment(studentId, globalState);

      if (!enrollmentCheck['isEnrolled']) {
        setState(() {
          _isEnrolled = false;
          _enrollmentMessage = enrollmentCheck['message'];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isEnrolled = true;
      });

      final classId = await _getStudentClass(studentId);
      final department = _convertClassDepartment(classId.split('-').first);
      final subjects = await _getStudentSubjects(classId, department);

      final processedSubjects = <String>{};
      final List<gradesModel> allGrades = [];

      for (String subject in subjects) {
        if (!processedSubjects.contains(subject)) {
          processedSubjects.add(subject);
          final grades = await _fetchSubjectGrades(subject, studentId);
          allGrades.addAll(grades);
        }
      }

      if (mounted) {
        setState(() {
          _allGrades.clear();
          _allGrades.addAll(allGrades);
          _isLoading = false;
        });
      }
    } catch (e) {
      _handleError('Error loading grades', e);
    }
  }

  Future<Map<String, dynamic>> _verifyEnrollment(
      String studentId, GlobalState globalState) async {
    try {
      final classId = await _getStudentClass(studentId);
      if (classId == 'Unknown Class' || classId == 'N/A') {
        return {
          'isEnrolled': false,
          'message':
              'No class enrollment found. Please contact the registrar for assistance.'
        };
      }

      final department = _convertClassDepartment(classId.split('-').first);

      final classSnapshot = await FirebaseFirestore.instance
          .collection(department)
          .doc(classId)
          .get();

      if (!classSnapshot.exists) {
        return {
          'isEnrolled': false,
          'message':
              'Class record not found. Please contact the registrar to verify your enrollment.'
        };
      }

      final classList = classSnapshot.data()?['class-list'] as List?;
      if (classList == null) {
        return {
          'isEnrolled': false,
          'message':
              'Class roster is empty. Please contact the registrar for assistance.'
        };
      }

      final studentFullName = '$studentId';
      final isInClassList = classList.any((student) => student
          .toString()
          .toLowerCase()
          .contains(studentFullName.toLowerCase()));

      if (!isInClassList) {
        return {
          'isEnrolled': false,
          'message':
              'You are not enrolled in class $classId. Please contact the registrar to resolve this enrollment issue.'
        };
      }

      return {'isEnrolled': true, 'message': ''};
    } catch (e) {
      return {
        'isEnrolled': false,
        'message':
            'Error verifying enrollment. Please contact the registrar for assistance.'
      };
    }
  }

  Future<String> _getStudentClass(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('profile-information')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      return snapshot.docs.firstOrNull?.data()['enrolledClass'] ??
          'Unknown Class';
    } catch (e) {
      _handleError('Error fetching student class', e);
      return 'N/A';
    }
  }

  String _convertClassDepartment(String identifier) {
    return _departmentMapping[identifier.toUpperCase()] ?? 'N/A';
  }

  Future<List<String>> _getStudentSubjects(
      String classId, String department) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(department)
          .where('class-code', isEqualTo: classId)
          .limit(1)
          .get();

      final subjects =
          snapshot.docs.firstOrNull?.data()['enrolled-subjects'] as List?;
      return subjects?.map<String>((s) => '$classId:$s').toList() ?? [];
    } catch (e) {
      _handleError('Error fetching student subjects', e);
      return [];
    }
  }

  Future<List<gradesModel>> _fetchSubjectGrades(
      String subjectId, String studentId) async {
    try {
      final classSubjectSnap = await FirebaseFirestore.instance
          .collection('class-subjects')
          .where('classSubjectCode', isEqualTo: subjectId)
          .limit(1)
          .get();

      if (classSubjectSnap.docs.isEmpty) return [];

      final classDoc = classSubjectSnap.docs.first;
      final subjectName = classDoc.data()['subjectName'] ?? 'Unknown Subject';

      final gradesSnap = await FirebaseFirestore.instance
          .collection('class-subjects')
          .doc(classDoc.id)
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      return gradesSnap.docs.map((gradeDoc) {
        final data = gradeDoc.data();
        final finalGrade = _computeFinalGrade(
          (data['firstQuarter'] as num).toDouble(),
          (data['secondQuarter'] as num).toDouble(),
          (data['thirdQuarter'] as num).toDouble(),
          (data['fourthQuarter'] as num).toDouble(),
        );

        return gradesModel(
          gradesStudentID: data['studentId'] ?? 'N/A',
          gradesSubName: subjectName,
          gradesFirGrade: (data['firstQuarter'] as num).toDouble(),
          gradesSecGrade: (data['secondQuarter'] as num).toDouble(),
          gradesThiGrade: (data['thirdQuarter'] as num).toDouble(),
          gradesFouGrade: (data['fourthQuarter'] as num).toDouble(),
          gradesFinGrade: finalGrade,
          gradesGraStat: _getGradeStatus(finalGrade),
        );
      }).toList();
    } catch (e) {
      _handleError('Error fetching subject grades', e);
      return [];
    }
  }

  List<gradesModel> _removeDuplicateGrades(List<gradesModel> grades) {
    final Map<String, gradesModel> uniqueGrades = {};

    for (final grade in grades) {
      final key = grade.gradesSubName.toLowerCase().trim();
      if (!uniqueGrades.containsKey(key)) {
        uniqueGrades[key] = grade;
      }
    }

    return uniqueGrades.values.toList();
  }

  double _computeFinalGrade(
      double first, double second, double third, double fourth) {
    return (first + second + third + fourth) / 4;
  }

  String _getGradeStatus(double grade) {
    if (grade >= 90) return 'Excellent';
    if (grade >= 85) return 'Very Good';
    if (grade >= 80) return 'Good';
    if (grade >= 75) return 'Fair';
    return 'Needs Improvement';
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) return Colors.green.shade600;
    if (grade >= 85) return Colors.blue.shade600;
    if (grade >= 80) return Colors.orange.shade600;
    if (grade >= 75) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  void _handleError(String message, dynamic error) {
    if (mounted) {
      useToastify.showErrorToast(context, 'Error', message);
      setState(() {
        _isLoading = false;
      });
    }
    debugPrint('$message: $error');
  }

  List<gradesModel> _filterAndSortGrades() {
    var grades = _removeDuplicateGrades(_allGrades);

    var filtered = _searchQuery.isEmpty
        ? grades
        : grades
            .where((grade) => grade.gradesSubName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    switch (_sortBy) {
      case 0:
        filtered.sort((a, b) => a.gradesSubName.compareTo(b.gradesSubName));
        break;
      case 0.5:
        filtered.sort((a, b) => b.gradesSubName.compareTo(a.gradesSubName));
        break;
      case 1:
        filtered.sort((a, b) => a.gradesFinGrade.compareTo(b.gradesFinGrade));
        break;
      case 1.5:
        filtered.sort((a, b) => b.gradesFinGrade.compareTo(a.gradesFinGrade));
        break;
      case 2:
        filtered.sort((a, b) => a.gradesGraStat.compareTo(b.gradesGraStat));
        break;
      case 2.5:
        filtered.sort((a, b) => b.gradesGraStat.compareTo(a.gradesGraStat));
        break;
      default:
        filtered.sort((a, b) => a.gradesSubName.compareTo(b.gradesSubName));
    }
    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'SUBJECT':
          newSortBy = _isHeaderClicked ? 0.5 : 0;
          break;
        case 'FINAL GRADE':
          newSortBy = _isHeaderClicked ? 1.5 : 1;
          break;
        case 'STATUS':
          newSortBy = _isHeaderClicked ? 2.5 : 2;
          break;
        default:
          newSortBy = 0;
      }

      _sortBy = newSortBy;
      _isHeaderClicked = !_isHeaderClicked;
    });
  }

  void _showGradeDetails(gradesModel grade) {
    final gradeText = '''
Grade Details for ${_toTitleCase(grade.gradesSubName)}:

First Quarter: ${grade.gradesFirGrade.toStringAsFixed(1)}
Second Quarter: ${grade.gradesSecGrade.toStringAsFixed(1)}
Third Quarter: ${grade.gradesThiGrade.toStringAsFixed(1)}
Fourth Quarter: ${grade.gradesFouGrade.toStringAsFixed(1)}
Final Grade: ${grade.gradesFinGrade.toStringAsFixed(1)}
Status: ${grade.gradesGraStat}
    ''';

    showDialog(
      context: context,
      builder: (context) => ViewGradesDialog(
        grade: grade,
        gradeText: gradeText,
      ),
    );
  }

  String _toTitleCase(String input) {
    if (input.isEmpty) return '';
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _refreshData() async {
    await _loadGrades();
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
                HugeIcons.strokeRoundedSchoolReportCard,
                color: Colors.white,
                size:
                    DynamicSizeService.calculateAspectRatioSize(context, 0.04),
              ),
              const SizedBox(width: 12),
              Text(
                "My Academic Grades",
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
            'Track your academic performance and view detailed grade breakdowns.',
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
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by subject name...",
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
          Expanded(flex: 3, child: _buildHeaderCell("SUBJECT")),
          Expanded(flex: 2, child: _buildHeaderCell("FINAL GRADE")),
          Expanded(flex: 2, child: _buildHeaderCell("STATUS")),
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
              _isHeaderClicked
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

  Widget _buildModernGradeRow(gradesModel grade) {
    return InkWell(
      onTap: () => _showGradeDetails(grade),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _toTitleCase(grade.gradesSubName),
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
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGradeColor(grade.gradesFinGrade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  grade.gradesFinGrade.toStringAsFixed(1),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getGradeColor(grade.gradesFinGrade),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Text(
                grade.gradesGraStat,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            HugeIcons.strokeRoundedSchoolReportCard,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No grades found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or contact your teacher for inquiries',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildGradesList() {
    final filteredGrades = _filterAndSortGrades();

    if (filteredGrades.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredGrades.length,
      itemBuilder: (context, index) {
        return _buildModernGradeRow(filteredGrades[index]);
      },
    );
  }

  Widget _buildEnrollmentError() {
    return Center(
        child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Enrollment Issue',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _enrollmentMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.red.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      body: RefreshIndicator(
        onRefresh: _refreshData,
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
                if (_isLoading)
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
                    child: _buildLoadingIndicator(),
                  )
                else if (!_isEnrolled)
                  _buildEnrollmentError()
                else ...[
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
                        _buildGradesList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
