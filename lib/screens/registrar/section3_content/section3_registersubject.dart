import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class RegisterSubjectDialog extends StatefulWidget {
  const RegisterSubjectDialog({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  final VoidCallback onRefresh;

  @override
  State<RegisterSubjectDialog> createState() => _RegisterSubjectDialogState();
}

class _RegisterSubjectDialogState extends State<RegisterSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedDepartment;
  bool _isGeneratingId = false;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  static const Map<String, Map<String, String>> _departments = {
    "Pre-School": {"code": "pre-dept", "prefix": "PRE"},
    "Primary School": {"code": "pri-dept", "prefix": "PRI"},
    "Junior High School": {"code": "jhs-dept", "prefix": "JHS"},
    "Senior High School (ABM)": {"code": "abm-dept", "prefix": "ABM"},
    "Senior High School (HUMMS)": {"code": "humms-dept", "prefix": "HUMMS"},
    "Senior High School (GAS)": {"code": "gas-dept", "prefix": "GAS"},
    "Senior High School (ICT)": {"code": "ict-dept", "prefix": "ICT"},
    "Senior High School (HE)": {"code": "he-dept", "prefix": "HE"},
  };

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generateSubjectId() async {
    if (_selectedDepartment == null) return;

    setState(() => _isGeneratingId = true);

    try {
      final departmentCode = _departments[_selectedDepartment]!["code"]!;
      final prefix = _departments[_selectedDepartment]!["prefix"]!;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('subjectDepartment', isEqualTo: departmentCode)
          .get();

      final subjectCount = querySnapshot.docs.length;
      final newSubjectId = "$prefix-${subjectCount + 1}";

      setState(() => _idController.text = newSubjectId);
    } catch (e) {
      _showToast("Failed to generate subject ID: $e", isError: true);
    } finally {
      setState(() => _isGeneratingId = false);
    }
  }

  Future<bool> _checkIfSubjectExists() async {
    final subjectName = _nameController.text.trim().toUpperCase();
    final departmentCode = _departments[_selectedDepartment]!["code"]!;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('subjectDepartment', isEqualTo: departmentCode)
          .where('subjectName', isEqualTo: subjectName)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _showToast("Failed to check subject existence: $e", isError: true);
      return false;
    }
  }

  Future<void> _registerSubject() async {
    if (!_formKey.currentState!.validate()) return;

    final subjectExists = await _checkIfSubjectExists();
    if (subjectExists) {
      _showToast(
          "A subject with this name already exists in the selected department.",
          isError: true);
      return;
    }

    try {
      final subjectId = _idController.text.trim().toUpperCase();
      final docRef =
          FirebaseFirestore.instance.collection('subjects').doc(subjectId);

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        _showToast("Subject with ID '$subjectId' already exists.",
            isError: true);
        return;
      }

      await docRef.set({
        'subjectId': subjectId,
        'subjectName': _nameController.text.trim().toUpperCase(),
        'subjectDepartment': _departments[_selectedDepartment]!["code"],
        'subjectDescription': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showToast("Subject registered successfully!");
      widget.onRefresh();
      Navigator.of(context).pop();
    } catch (e) {
      _showToast("Failed to register subject: $e", isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (isError) {
      useToastify.showErrorToast(context, "Error", message);
    } else {
      useToastify.showLoadingToast(context, "Success", message);
    }
  }

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'Pre-School':
        return Colors.purple;
      case 'Primary School':
        return Colors.green;
      case 'Junior High School':
        return Colors.orange;
      case 'Senior High School (ABM)':
      case 'Senior High School (HUMMS)':
      case 'Senior High School (GAS)':
      case 'Senior High School (ICT)':
      case 'Senior High School (HE)':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Register New Subject",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a new subject to the system',
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
            items: _departments.keys
                .map((dept) => DropdownMenuItem<String>(
                      value: dept,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getDepartmentColor(dept),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dept,
                            style: GoogleFonts.montserrat(fontSize: 14),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedDepartment = newValue!;
                _idController.clear();
              });
              _generateSubjectId();
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

  Widget _buildActionButtons() {
    return Container(
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
            onPressed: () => Navigator.of(context).pop(),
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
                colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed:
                  _selectedDepartment != null && _idController.text.isNotEmpty
                      ? _registerSubject
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Register Subject',
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
                  child: Column(
                    children: [
                      _buildDepartmentDropdown(),
                      const SizedBox(height: 20),
                      _buildFormField(
                        label: "Subject ID",
                        controller: _idController,
                        readOnly: true,
                        hintText: "Auto-generated based on department",
                        validator: (value) => value!.isEmpty
                            ? 'Please select a department to generate ID'
                            : null,
                        suffixIcon: _isGeneratingId
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        _primaryColor),
                                  ),
                                ),
                              )
                            : const Icon(Icons.lock_outline,
                                color: Colors.grey, size: 20),
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        label: "Subject Name",
                        controller: _nameController,
                        hintText: "e.g., 'BASIC MATHEMATICS'",
                        validator: (value) => value!.isEmpty
                            ? 'Please enter a subject name'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        label: "Subject Description",
                        controller: _descriptionController,
                        maxLines: 3,
                        hintText:
                            "Enter a detailed description of the subject...",
                        validator: (value) => value!.isEmpty
                            ? 'Please enter a subject description'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
