import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class AssessStudentDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String classCode;
  final String teacherId;
  final String departmentCode;

  const AssessStudentDialog({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.classCode,
    required this.teacherId,
    required this.departmentCode,
  }) : super(key: key);

  @override
  _AssessStudentDialogState createState() => _AssessStudentDialogState();
}

class _AssessStudentDialogState extends State<AssessStudentDialog> {
  bool _isLoading = true;
  Map<String, dynamic>? _teacherSubjectData;
  List<Map<String, dynamic>> _gradeRecords = [];
  String _subjectName = '';
  String _classSubjectCode = '';

  @override
  void initState() {
    super.initState();
    _fetchTeacherSubjectData();
  }

  Future<void> _fetchTeacherSubjectData() async {
    try {
      setState(() => _isLoading = true);

      QuerySnapshot classSubjectSnapshot = await FirebaseFirestore.instance
          .collection('class-subjects')
          .where('teacherId', isEqualTo: widget.teacherId)
          .get();

      for (QueryDocumentSnapshot doc in classSubjectSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String classSubjectCode = data['classSubjectCode'] ?? '';

        if (classSubjectCode.startsWith('${widget.classCode}:')) {
          _teacherSubjectData = data;
          _classSubjectCode = classSubjectCode;
          _subjectName = data['subjectName'] ?? 'Unknown Subject';
          break;
        }
      }

      if (_teacherSubjectData != null) {
        await _fetchStudentGrades();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching teacher subject data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudentGrades() async {
    try {
      DocumentSnapshot gradeDoc = await FirebaseFirestore.instance
          .collection('class-subjects')
          .doc(_classSubjectCode)
          .collection('grades')
          .doc(widget.studentId)
          .get();

      List<Map<String, dynamic>> grades = [];

      if (gradeDoc.exists) {
        Map<String, dynamic> gradeData =
            gradeDoc.data() as Map<String, dynamic>;

        List<String> quarters = [
          'firstQuarter',
          'secondQuarter',
          'thirdQuarter',
          'fourthQuarter'
        ];
        List<String> quarterNames = [
          'First Quarter',
          'Second Quarter',
          'Third Quarter',
          'Fourth Quarter'
        ];

        for (int i = 0; i < quarters.length; i++) {
          if (gradeData.containsKey(quarters[i]) &&
              gradeData[quarters[i]] != null) {
            grades.add({
              'id': '${quarters[i]}_${widget.studentId}',
              'assessmentName': quarterNames[i],
              'score': gradeData[quarters[i]],
              'quarter': quarters[i],
            });
          }
        }
      }

      setState(() {
        _gradeRecords = grades;
      });
    } catch (e) {
      print('Error fetching student grades: $e');
    }
  }

  double _calculateOverallGrade() {
    if (_gradeRecords.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    for (var grade in _gradeRecords) {
      if (grade['score'] != null && grade['score'] is num) {
        total += grade['score'].toDouble();
        count++;
      }
    }

    return count > 0 ? total / count : 0.0;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Container(
          width: DynamicSizeService.calculateWidthSize(context, 0.6),
          height: DynamicSizeService.calculateHeightSize(context, 0.8),
          child: _isLoading ? _buildLoadingWidget() : _buildContent(),
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
          Text('Loading student information...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_teacherSubjectData == null) {
      return _buildNoSubjectWidget();
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
                _buildStudentInfoCard(),
                const SizedBox(height: 16),
                _buildGradeOverviewCard(),
                const SizedBox(height: 16),
                _buildGradeTableCard(),
              ],
            ),
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildNoSubjectWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.orange.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Subject Assignment',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are not teaching any subject to this student\'s class.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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
              Icons.person,
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
                  widget.studentName,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$_subjectName - Grades Management',
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

  Widget _buildStudentInfoCard() {
    return Container(
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
              const Icon(
                Icons.info_outline,
                color: Color.fromARGB(255, 36, 66, 117),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Student Information',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 36, 66, 117),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Student ID', widget.studentId),
          _buildDetailRow('Student Name', widget.studentName),
          _buildDetailRow('Class Code', widget.classCode),
          _buildDetailRow('Subject', _subjectName),
        ],
      ),
    );
  }

  Widget _buildGradeOverviewCard() {
    double overallGrade = _calculateOverallGrade();
    String status = _getGradeStatus(overallGrade);
    Color statusColor = _getGradeColor(overallGrade);

    return Container(
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
              const Icon(
                Icons.analytics_outlined,
                color: Color.fromARGB(255, 36, 66, 117),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Grade Overview',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 36, 66, 117),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        overallGrade.toStringAsFixed(1),
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'Overall Grade',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_gradeRecords.length}',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      Text(
                        'Total Records',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Status: $status',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeTableCard() {
    return Container(
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
              const Icon(
                Icons.table_chart_outlined,
                color: Color.fromARGB(255, 36, 66, 117),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Grade Records (${_gradeRecords.length})',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 36, 66, 117),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_gradeRecords.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.grade_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No grades recorded yet',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 66, 117),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Assessment',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Score',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _gradeRecords.length,
                      itemBuilder: (context, index) {
                        final grade = _gradeRecords[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
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
                              Expanded(
                                flex: 2,
                                child: Text(
                                  grade['assessmentName'] ??
                                      'Assessment ${index + 1}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  grade['score']?.toString() ?? 'N/A',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _getGradeColor(
                                        grade['score']?.toDouble() ?? 0),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: Text(
              '$label: ',
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _teacherSubjectData != null
                  ? () {
                      _showAddGradeDialog();
                    }
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Add Grade',
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
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGradeDialog() {
    String selectedQuarter = 'firstQuarter';
    TextEditingController gradeController = TextEditingController();

    // Get current grade for the selected quarter if it exists
    void updateCurrentGrade() {
      var existingGrade = _gradeRecords.firstWhere(
        (grade) => grade['quarter'] == selectedQuarter,
        orElse: () => <String, dynamic>{},
      );

      if (existingGrade.isNotEmpty) {
        gradeController.text = existingGrade['score'].toString();
      } else {
        gradeController.clear();
      }
    }

    updateCurrentGrade();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Manage Quarter Grade',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 36, 66, 117),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student: ${widget.studentName}',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Quarter:',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedQuarter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'firstQuarter', child: Text('First Quarter')),
                  DropdownMenuItem(
                      value: 'secondQuarter', child: Text('Second Quarter')),
                  DropdownMenuItem(
                      value: 'thirdQuarter', child: Text('Third Quarter')),
                  DropdownMenuItem(
                      value: 'fourthQuarter', child: Text('Fourth Quarter')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedQuarter = value!;
                    updateCurrentGrade();
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Grade (0-100):',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: gradeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Enter grade (0-100)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (gradeController.text.isNotEmpty) {
                  double? grade = double.tryParse(gradeController.text);
                  if (grade != null && grade >= 0 && grade <= 100) {
                    await _saveQuarterGrade(selectedQuarter, grade);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please enter a valid grade between 0 and 100')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 36, 66, 117),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Save Grade',
                style: GoogleFonts.montserrat(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuarterGrade(String quarter, double grade) async {
    try {
      DocumentReference gradeDoc = FirebaseFirestore.instance
          .collection('class-subjects')
          .doc(_classSubjectCode)
          .collection('grades')
          .doc(widget.studentId);

      // Check if document exists
      DocumentSnapshot docSnapshot = await gradeDoc.get();

      if (docSnapshot.exists) {
        // Update existing document
        await gradeDoc.update({
          quarter: grade,
          'dateUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new document with student info
        await gradeDoc.set({
          'studentId': widget.studentId,
          'studentName': widget.studentName,
          'classCode': widget.classCode,
          quarter: grade,
        });
      }

      // Refresh the grades display
      await _fetchStudentGrades();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grade saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving grade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving grade. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
