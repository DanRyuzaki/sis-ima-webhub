import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/scheduleModel.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentFourthSection extends StatefulWidget {
  const StudentFourthSection({super.key});

  @override
  State<StudentFourthSection> createState() => _StudentFourthSectionState();
}

class _StudentFourthSectionState extends State<StudentFourthSection> {
  final List<scheduleModel> _schedules = [];
  final List<scheduleModel> _filteredSchedules = [];
  bool _isLoading = true;
  String _searchQuery = '';
  double _sortBy = -1;
  bool _isHeaderClicked = false;

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

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      setState(() {
        _isLoading = true;
        _schedules.clear();
        _filteredSchedules.clear();
      });

      final studentId = Provider.of<GlobalState>(context, listen: false).userID;
      final classId = await _fetchStudentClass(studentId);
      final department = _convertDepartment(classId.split('-').first);
      final subjects = await _fetchStudentSubjects(classId, department);
      final schedules = await Future.wait(
        subjects.map((subject) => _fetchSubjectSchedule(subject)),
      );

      if (mounted) {
        setState(() {
          _schedules.addAll(schedules.expand((s) => s));
          _filteredSchedules.addAll(_schedules);
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      _handleError('Error loading schedules', e);
    }
  }

  Future<String> _fetchStudentClass(String studentId) async {
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

  String _convertDepartment(String identifier) =>
      _departmentMapping[identifier.toUpperCase()] ?? 'N/A';

  Future<List<String>> _fetchStudentSubjects(
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
      _handleError('Error fetching subjects', e);
      return [];
    }
  }

  Future<List<scheduleModel>> _fetchSubjectSchedule(String subjectId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('class-subjects')
          .where('classSubjectCode', isEqualTo: subjectId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final doc = snapshot.docs.first;
      final data = doc.data();

      
      final teacherId = data['teacherId']?.toString() ?? '';
      final teacherName = await _fetchTeacherName(teacherId);

      return [
        scheduleModel(
          scheduleSubjectID: data['subjectId']?.toString() ?? 'N/A',
          scheduleClassSubjectCode:
              data['classSubjectCode']?.toString() ?? 'N/A',
          subjectName: data['subjectName']?.toString() ?? 'Unknown Subject',
          subjectSchedule: data['classSchedule']?.toString() ?? 'No Schedule',
          teacherName: teacherName,
        )
      ];
    } catch (e) {
      _handleError('Error fetching schedule for $subjectId', e);
      return [];
    }
  }

  Future<String> _fetchTeacherName(String teacherId) async {
    if (teacherId.isEmpty) return 'No Teacher Assigned';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('entity')
          .where('userID', isEqualTo: teacherId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 'Unknown Teacher';

      final data = snapshot.docs.first.data();
      final firstName = data['userName00']?.toString() ?? '';
      final lastName = data['userName01']?.toString() ?? '';
      final middleName = data['userName02']?.toString() ?? '';

      String fullName = '';
      if (firstName.isNotEmpty) fullName += firstName;
      if (middleName.isNotEmpty)
        fullName += (fullName.isNotEmpty ? ' ' : '') + middleName;
      if (lastName.isNotEmpty)
        fullName += (fullName.isNotEmpty ? ' ' : '') + lastName;

      return fullName.isNotEmpty ? fullName : 'Unknown Teacher';
    } catch (e) {
      debugPrint('Error fetching teacher name: $e');
      return 'Unknown Teacher';
    }
  }

  void _handleError(String message, dynamic error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      useToastify.showErrorToast(context, 'Error', message);
    }
    debugPrint('$message: $error');
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    setState(() {
      List<scheduleModel> filtered = _searchQuery.isEmpty
          ? List.from(_schedules)
          : _schedules.where((schedule) {
              return schedule.subjectName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  schedule.scheduleSubjectID
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  schedule.scheduleClassSubjectCode
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  schedule.subjectSchedule
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  (schedule.teacherName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()));
            }).toList();

      
      switch (_sortBy) {
        case 0: 
          filtered.sort(
              (a, b) => a.scheduleSubjectID.compareTo(b.scheduleSubjectID));
          break;
        case 0.5: 
          filtered.sort(
              (a, b) => b.scheduleSubjectID.compareTo(a.scheduleSubjectID));
          break;
        case 1: 
          filtered.sort((a, b) => a.subjectName.compareTo(b.subjectName));
          break;
        case 1.5: 
          filtered.sort((a, b) => b.subjectName.compareTo(a.subjectName));
          break;
        case 2: 
          filtered
              .sort((a, b) => a.subjectSchedule.compareTo(b.subjectSchedule));
          break;
        case 2.5: 
          filtered
              .sort((a, b) => b.subjectSchedule.compareTo(a.subjectSchedule));
          break;
        case 3: 
          filtered.sort((a, b) => (a.teacherName).compareTo(b.teacherName));
          break;
        case 3.5: 
          filtered.sort((a, b) => (b.teacherName).compareTo(a.teacherName));
          break;
        default:
          filtered.sort((a, b) => a.subjectName.compareTo(b.subjectName));
      }

      _filteredSchedules.clear();
      _filteredSchedules.addAll(filtered);
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'SUBJECT ID':
          newSortBy = _isHeaderClicked ? 0.5 : 0;
          break;
        case 'SUBJECT NAME':
          newSortBy = _isHeaderClicked ? 1.5 : 1;
          break;
        case 'SCHEDULE':
          newSortBy = _isHeaderClicked ? 2.5 : 2;
          break;
        case 'TEACHER':
          newSortBy = _isHeaderClicked ? 3.5 : 3;
          break;
        default:
          newSortBy = 1;
      }

      _sortBy = newSortBy;
      _isHeaderClicked = !_isHeaderClicked;
    });
    _applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      body: RefreshIndicator(
        onRefresh: _loadSchedules,
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
                _buildModernScheduleTable(),
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
                HugeIcons.strokeRoundedCalendar03,
                color: Colors.white,
                size:
                    DynamicSizeService.calculateAspectRatioSize(context, 0.04),
              ),
              const SizedBox(width: 12),
              Text(
                "My Classes",
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
            'View the schedule and assigned teacher for each subject you are enrolled in.',
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
        decoration: InputDecoration(
          hintText: "Search by subject, schedule, teacher, or subject ID...",
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

  Widget _buildModernScheduleTable() {
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
          !_isLoading ? _buildScheduleList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderCell("SUBJECT ID")),
          Expanded(flex: 3, child: _buildHeaderCell("SUBJECT NAME")),
          Expanded(flex: 3, child: _buildHeaderCell("TEACHER")),
          Expanded(flex: 3, child: _buildHeaderCell("SCHEDULE")),
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

  Widget _buildScheduleList() {
    if (_schedules.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredSchedules.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernScheduleRow(_filteredSchedules[index]);
      },
    );
  }

  Widget _buildModernScheduleRow(scheduleModel schedule) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                schedule.scheduleSubjectID,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.subjectName,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  schedule.scheduleClassSubjectCode,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedTeacher,
                    size: 14,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      schedule.teacherName,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedClock01,
                    size: 14,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      schedule.subjectSchedule,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            HugeIcons.strokeRoundedCalendar03,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your class schedule will appear here once available.',
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
}
