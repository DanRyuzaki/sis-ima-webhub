import 'package:web/web.dart' as web;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class ViewAdvisoryClassDialog extends StatefulWidget {
  final String departmentCode;
  final String classCode;

  const ViewAdvisoryClassDialog({
    Key? key,
    required this.departmentCode,
    required this.classCode,
  }) : super(key: key);

  @override
  _ViewAdvisoryClassDialogState createState() =>
      _ViewAdvisoryClassDialogState();
}

class _ViewAdvisoryClassDialogState extends State<ViewAdvisoryClassDialog> {
  bool _isLoading = true;
  Map<String, dynamic>? _classData;
  List<String> _studentList = [];
  List<Map<String, dynamic>> _studentDetails = [];
  String _adviserName = 'Not Assigned';
  List<Map<String, dynamic>> _subjectList = [];

  @override
  void initState() {
    super.initState();
    _fetchClassData();
  }

  Future<void> _fetchClassData() async {
    try {
      setState(() => _isLoading = true);

      QuerySnapshot classSnapshot = await FirebaseFirestore.instance
          .collection(widget.departmentCode)
          .where('class-code', isEqualTo: widget.classCode)
          .get();

      if (classSnapshot.docs.isNotEmpty) {
        _classData = classSnapshot.docs.first.data() as Map<String, dynamic>;
        _studentList = List<String>.from(_classData!['class-list'] ?? []);

        await _fetchAdviserName();

        await _fetchStudentDetails();

        await _fetchSubjectsData();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching class data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAdviserName() async {
    try {
      String adviserId = _classData!['adviser'] ?? '';

      if (adviserId.isNotEmpty) {
        QuerySnapshot adviserSnapshot = await FirebaseFirestore.instance
            .collection('entity')
            .where('userID', isEqualTo: adviserId)
            .get();

        if (adviserSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> adviserData =
              adviserSnapshot.docs.first.data() as Map<String, dynamic>;

          String firstName = adviserData['userName00'] ?? '';
          String lastName = adviserData['userName01'] ?? '';
          String middleName = adviserData['userName02'] ?? '';

          setState(() {
            _adviserName =
                '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'
                    .trim();
          });
        }
      }
    } catch (e) {
      print('Error fetching adviser name: $e');
    }
  }

  Future<void> _fetchStudentDetails() async {
    try {
      List<Map<String, dynamic>> studentDetails = [];

      for (String studentId in _studentList) {
        QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('entity')
            .where('userID', isEqualTo: studentId)
            .get();

        if (studentSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> studentData =
              studentSnapshot.docs.first.data() as Map<String, dynamic>;

          String firstName = studentData['userName00'] ?? '';
          String lastName = studentData['userName01'] ?? '';
          String middleName = studentData['userName02'] ?? '';

          String fullName =
              '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'
                  .trim();

          studentDetails.add({
            'studentId': studentId,
            'fullName': fullName,
          });
        } else {
          studentDetails.add({
            'studentId': studentId,
            'fullName': studentId,
          });
        }
      }

      setState(() {
        _studentDetails = studentDetails;
      });
    } catch (e) {
      print('Error fetching student details: $e');
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

  Future<void> _fetchSubjectsData() async {
    try {
      List<dynamic> enrolledSubjects = _classData!['enrolled-subjects'] ?? [];
      List<Map<String, dynamic>> subjects = [];

      for (dynamic subjectCode in enrolledSubjects) {
        String classSubjectCode = '${widget.classCode}:$subjectCode';

        QuerySnapshot classSubjectSnapshot = await FirebaseFirestore.instance
            .collection('class-subjects')
            .where('classSubjectCode', isEqualTo: classSubjectCode)
            .get();

        if (classSubjectSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> subjectData =
              classSubjectSnapshot.docs.first.data() as Map<String, dynamic>;

          String teacherName = 'Unknown Teacher';
          String teacherId = subjectData['teacherId'] ?? '';

          if (teacherId.isNotEmpty) {
            QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance
                .collection('entity')
                .where('userID', isEqualTo: teacherId)
                .get();

            if (teacherSnapshot.docs.isNotEmpty) {
              Map<String, dynamic> teacherData =
                  teacherSnapshot.docs.first.data() as Map<String, dynamic>;

              String firstName = teacherData['userName00'] ?? '';
              String lastName = teacherData['userName01'] ?? '';
              String middleName = teacherData['userName02'] ?? '';

              teacherName =
                  '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'
                      .trim();
            }
          }

          subjects.add({
            'subjectName': subjectData['subjectName'] ?? 'Unknown Subject',
            'subjectDescription': subjectData['subjectDescription'] ?? '',
            'subjectId': subjectData['subjectId'] ?? '',
            'teacherName': teacherName,
            'teacherId': teacherId,
            'classSchedule': subjectData['classSchedule'] ?? 'No Schedule',
          });
        }
      }

      setState(() {
        _subjectList = subjects;
      });
    } catch (e) {
      print('Error fetching subjects data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Container(
          width: DynamicSizeService.calculateWidthSize(context, 0.6),
          height: DynamicSizeService.calculateHeightSize(context, 0.8),
          child: _isLoading ? _buildLoadingWidget() : _buildClassContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 36, 66, 117),
            ),
          ),
          SizedBox(height: 16),
          Text('Loading class information...'),
        ],
      ),
    );
  }

  Widget _buildClassContent() {
    if (_classData == null) {
      return _buildErrorWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClassInfoCard(),
                const SizedBox(height: 16),
                _buildStudentListCard(),
                const SizedBox(height: 16),
                _buildSubjectsCard(),
              ],
            ),
          ),
        ),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Class not found',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load class information',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 36, 66, 117),
            Color.fromARGB(255, 52, 89, 149),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.class_,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classCode,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Class Information',
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
    );
  }

  Widget _buildInfoCard(String title, Widget content, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: const Color.fromARGB(255, 36, 66, 117),
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 36, 66, 117),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return _buildInfoCard(
      'Class Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Class Code', widget.classCode),
          _buildDetailRow(
              'Department', _getDepartmentName(widget.departmentCode)),
          _buildDetailRow('Class Adviser', '$_adviserName (You)'),
          _buildDetailRow('Total Students', '${_studentDetails.length}'),
          _buildDetailRow('Total Subjects', '${_subjectList.length}'),
        ],
      ),
      icon: Icons.info_outline,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentListCard() {
    return _buildInfoCard(
      'Students (${_studentDetails.length})',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_studentDetails.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No students enrolled in this class',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _studentDetails.length,
                    itemBuilder: (context, index) {
                      final student = _studentDetails[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 66, 117)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        const Color.fromARGB(255, 36, 66, 117),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['fullName'],
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${student['studentId']}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      web.window.location.assign(
                          '/?session=true&page=2&assessment=true&class=${widget.classCode}');
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(
                      'View Student Details',
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 36, 66, 117),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      icon: Icons.people_outline,
    );
  }

  Widget _buildSubjectsCard() {
    return _buildInfoCard(
      'Subjects (${_subjectList.length})',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_subjectList.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No subjects assigned to this class',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 300,
              child: ListView.builder(
                itemCount: _subjectList.length,
                itemBuilder: (context, index) {
                  final subject = _subjectList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 66, 117)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                subject['subjectId'] ?? '',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 36, 66, 117),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subject['subjectName'] ?? '',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subject['subjectDescription']?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 4),
                          Text(
                            subject['subjectDescription'],
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                subject['teacherName'] ?? 'No Teacher Assigned',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              subject['classSchedule'] ?? 'No Schedule',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      icon: Icons.book_outlined,
    );
  }

  Widget _buildCloseButton() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 36, 66, 117),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Close',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
