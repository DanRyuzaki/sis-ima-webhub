import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/models/gradesModel.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class ViewGradesDialog extends StatefulWidget {
  final gradesModel grade;
  final String gradeText;

  const ViewGradesDialog({
    Key? key,
    required this.grade,
    required this.gradeText,
  }) : super(key: key);

  @override
  State<ViewGradesDialog> createState() => _ViewGradesDialogState();
}

class _ViewGradesDialogState extends State<ViewGradesDialog> {
  bool _isLoading = false;

  String _toTitleCase(String input) {
    if (input.isEmpty) return '';
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) return Colors.green.shade600;
    if (grade >= 85) return Colors.blue.shade600;
    if (grade >= 80) return Colors.orange.shade600;
    if (grade >= 75) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  String _getGradeStatus(double grade) {
    if (grade >= 90) return 'Excellent';
    if (grade >= 85) return 'Very Good';
    if (grade >= 80) return 'Good';
    if (grade >= 75) return 'Fair';
    return 'Needs Improvement';
  }

  List<Map<String, dynamic>> _getQuarterGrades() {
    return [
      {
        'quarter': 'First Quarter',
        'grade': widget.grade.gradesFirGrade,
      },
      {
        'quarter': 'Second Quarter',
        'grade': widget.grade.gradesSecGrade,
      },
      {
        'quarter': 'Third Quarter',
        'grade': widget.grade.gradesThiGrade,
      },
      {
        'quarter': 'Fourth Quarter',
        'grade': widget.grade.gradesFouGrade,
      },
    ];
  }

  Future<void> _copyToClipboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Clipboard.setData(ClipboardData(text: widget.gradeText));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grade details copied to clipboard!'),
            backgroundColor: Color.fromARGB(255, 36, 66, 117),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy to clipboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
                _buildSubjectInfoCard(),
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
              Icons.school,
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
                  _toTitleCase(widget.grade.gradesSubName),
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Academic Performance Overview',
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

  Widget _buildSubjectInfoCard() {
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
                'Subject Information',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 36, 66, 117),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
              'Subject Name', _toTitleCase(widget.grade.gradesSubName)),
          _buildDetailRow('Academic Status', widget.grade.gradesGraStat),
          _buildDetailRow(
              'Final Grade', widget.grade.gradesFinGrade.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildGradeOverviewCard() {
    double overallGrade = widget.grade.gradesFinGrade;
    String status = _getGradeStatus(overallGrade);
    Color statusColor = _getGradeColor(overallGrade);
    List<Map<String, dynamic>> quarterGrades = _getQuarterGrades();
    int completedQuarters = quarterGrades.where((q) => q['grade'] > 0).length;

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
                        'Final Grade',
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
                        '$completedQuarters/4',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      Text(
                        'Quarters',
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
    List<Map<String, dynamic>> quarterGrades = _getQuarterGrades();
    List<Map<String, dynamic>> validGrades =
        quarterGrades.where((grade) => grade['grade'] > 0).toList();

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
                'Quarter Grades (${validGrades.length})',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 36, 66, 117),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (validGrades.isEmpty)
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
                  Center(
                      child: Text(
                    'No grades available yet',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  )),
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
                            'Quarter',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Grade',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Status',
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
                      itemCount: quarterGrades.length,
                      itemBuilder: (context, index) {
                        final quarterData = quarterGrades[index];
                        final grade = quarterData['grade'];
                        final isValidGrade = grade > 0;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isValidGrade
                                ? Colors.white
                                : Colors.grey.shade50,
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
                                  quarterData['quarter'],
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: isValidGrade
                                        ? Colors.black87
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  isValidGrade
                                      ? grade.toStringAsFixed(1)
                                      : 'N/A',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isValidGrade
                                        ? _getGradeColor(grade)
                                        : Colors.grey.shade400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  isValidGrade
                                      ? _getGradeStatus(grade)
                                      : 'Pending',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: isValidGrade
                                        ? _getGradeColor(grade)
                                        : Colors.grey.shade400,
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
              onPressed: _isLoading ? null : _copyToClipboard,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.copy, size: 18),
              label: Text(
                _isLoading ? 'Copying...' : 'Copy Details',
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
}
