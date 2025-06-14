import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/facultyProfileModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class ModifyFacultyDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final facultyProfileModel facultyDataDeployed;

  const ModifyFacultyDialog({
    Key? key,
    required this.onRefresh,
    required this.facultyDataDeployed,
  }) : super(key: key);

  @override
  _ModifyFacultyDialogState createState() => _ModifyFacultyDialogState();
}

class _ModifyFacultyDialogState extends State<ModifyFacultyDialog> {
  final _formKey = GlobalKey<FormState>();

  final _facultyIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _contactNumberController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  DateTime? _selectedDate;
  bool _obscurePassword = true;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _showDeleteConfirmation = false;
  String _captchaWord = '';
  List<String> _selectedDepartments = [];

  final Map<String, String> _departmentOptions = {
    'Pre-School': 'pre-dept',
    'Primary School': 'pri-dept',
    'Junior High School': 'jhs-dept',
    'ABM - Senior High School': 'abm-dept',
    'HUMMS - Senior High Shool': 'humms-dept',
    'GAS - Senior High School': 'gas-dept',
    'ICT - Senior High School': 'ict-dept',
    'HE - Senior High School': 'he-dept'
  };

  @override
  void initState() {
    super.initState();
    _preloadFacultyData();
    _generateCaptcha();
  }

  void _preloadFacultyData() {
    _facultyIdController.text = widget.facultyDataDeployed.facultyId;
    _firstNameController.text = widget.facultyDataDeployed.facultyName00;
    _middleNameController.text = widget.facultyDataDeployed.facultyName02;
    _lastNameController.text = widget.facultyDataDeployed.facultyName01;
    _emailController.text = widget.facultyDataDeployed.facultyEmail;
    _passwordController.text = widget.facultyDataDeployed.facultyKey;
    _contactNumberController.text = widget.facultyDataDeployed.contactNumber;

    _selectedDate = widget.facultyDataDeployed.dateOfBirth.toDate();
    _dateOfBirthController.text =
        "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";

    _selectedDepartments = widget.facultyDataDeployed.department
        .map((deptCode) => _departmentOptions.entries
            .firstWhere((entry) => entry.value == deptCode,
                orElse: () => _departmentOptions.entries.first)
            .key)
        .toList();
  }

  @override
  void dispose() {
    _facultyIdController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    const words = ['DELETE', 'REMOVE', 'CONFIRM', 'PROCEED', 'EXECUTE'];
    final random = Random();
    _captchaWord = words[random.nextInt(words.length)];
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
            color: Color.fromARGB(255, 52, 89, 149),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Color(0xFFF8F9FA) : Colors.white,
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
              fillColor: readOnly ? Color(0xFFF8F9FA) : Colors.white,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteConfirmationDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: DynamicSizeService.calculateWidthSize(context, 0.5),
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Color.fromARGB(255, 244, 67, 54)],
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
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Confirm Deletion",
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This action cannot be undone',
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
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedAlert01,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "This will permanently delete the faculty's profile. This action cannot be undone.",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "To confirm deletion, please type: $_captchaWord",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 52, 89, 149),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFormField(
                    label: "Confirmation",
                    controller: _captchaController,
                    hintText: "Type $_captchaWord here",
                    validator: (value) {
                      if (value != _captchaWord) {
                        return 'Please type the exact word: $_captchaWord';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _captchaController.clear();
                      setState(() => _showDeleteConfirmation = false);
                    },
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
                        colors: [Colors.red, Color.fromARGB(255, 244, 67, 54)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_captchaController.text.toUpperCase() ==
                            _captchaWord) {
                          widget.onRefresh();
                          Navigator.of(context).pop();
                          _deleteFaculty();
                        } else {
                          useToastify.showErrorToast(context, 'Oops!',
                              "Incorrect confirmation word. Please try again.");
                          _captchaController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete Faculty',
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFaculty() async {
    setState(() => _isLoading = true);

    try {
      String facultyId = widget.facultyDataDeployed.facultyId;
      String teacherIdPath = '/entity/$facultyId';

      print('Deleting faculty: $facultyId');
      print('Teacher ID path: $teacherIdPath');

      print('Step 1: Removing faculty from class-subjects (subjects)...');
      QuerySnapshot classSubjectsSnapshot = await FirebaseFirestore.instance
          .collection('class-subjects')
          .where('teacherId', isEqualTo: teacherIdPath)
          .get();

      List<Future<void>> subjectUpdateTasks = [];
      for (DocumentSnapshot doc in classSubjectsSnapshot.docs) {
        print('Removing teacherId from class-subject: ${doc.id}');
        subjectUpdateTasks
            .add(doc.reference.update({'teacherId': FieldValue.delete()}));
      }
      await Future.wait(subjectUpdateTasks);
      print('Completed removing faculty from subjects');

      print('Step 2: Processing advisory classes...');
      List<dynamic> advisoryClassIds =
          widget.facultyDataDeployed.advisoryClassId;

      for (String advisoryClassCode in advisoryClassIds) {
        print('Processing advisory class: $advisoryClassCode');

        List<String> parts = advisoryClassCode.split(':')[0].split('-');
        if (parts.isNotEmpty) {
          String departmentCode = '${parts[0].toLowerCase()}-dept';
          String classCode = advisoryClassCode.split(':')[0];

          print('Department: $departmentCode, Class Code: $classCode');

          try {
            QuerySnapshot adviserQuery = await FirebaseFirestore.instance
                .collection(departmentCode)
                .where('adviser', isEqualTo: teacherIdPath)
                .get();

            if (adviserQuery.docs.isNotEmpty) {
              for (DocumentSnapshot doc in adviserQuery.docs) {
                print('Removing adviser from ${doc.id} via adviser field');
                await doc.reference.update({'adviser': FieldValue.delete()});
              }
            } else {
              QuerySnapshot classCodeQuery = await FirebaseFirestore.instance
                  .collection(departmentCode)
                  .where('class-code', isEqualTo: classCode)
                  .get();

              for (DocumentSnapshot doc in classCodeQuery.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                if (data['adviser'] == teacherIdPath) {
                  print('Removing adviser from ${doc.id} via class-code field');
                  await doc.reference.update({'adviser': FieldValue.delete()});
                }
              }
            }
          } catch (e) {
            print('Error processing advisory class $advisoryClassCode: $e');
          }
        }
      }
      print('Completed processing advisory classes');

      print('Step 3: Cleaning up remaining departmental collections...');
      List<String> allDepartments = [
        'pre-dept',
        'pri-dept',
        'jhs-dept',
        'abm-dept',
        'humms-dept',
        'gas-dept',
        'ict-dept',
        'he-dept'
      ];

      List<Future<void>> deptCleanupTasks = [];
      for (String department in allDepartments) {
        deptCleanupTasks
            .add(_cleanupDepartmentCollection(department, teacherIdPath));
      }
      await Future.wait(deptCleanupTasks);
      print('Completed departmental cleanup');

      print('Step 4: Deleting faculty entity...');
      QuerySnapshot entityQuery = await FirebaseFirestore.instance
          .collection("entity")
          .where('userID', isEqualTo: facultyId)
          .where('entity', isEqualTo: 2)
          .limit(1)
          .get();

      if (entityQuery.docs.isNotEmpty) {
        String documentId = entityQuery.docs.first.id;
        await FirebaseFirestore.instance
            .collection("entity")
            .doc(documentId)
            .delete();
        print('Faculty entity deleted successfully');
      } else {
        throw Exception('Faculty entity not found in database');
      }

      Navigator.of(context).pop();
      widget.onRefresh();

      useToastify.showLoadingToast(
        context,
        "Deletion Successful",
        "Faculty $facultyId has been permanently deleted along with all associated records.",
      );

      print('Faculty deletion completed successfully');
    } catch (e) {
      print('Faculty deletion error: $e');
      useToastify.showErrorToast(
        context,
        "Deletion Failed",
        "An error occurred while deleting the faculty. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cleanupDepartmentCollection(
      String departmentCode, String teacherIdPath) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(departmentCode)
          .where('adviser', isEqualTo: teacherIdPath)
          .get();

      List<Future<void>> updateTasks = [];
      for (DocumentSnapshot doc in querySnapshot.docs) {
        print('Cleaning up adviser from $departmentCode: ${doc.id}');
        updateTasks.add(doc.reference.update({'adviser': FieldValue.delete()}));
      }

      if (updateTasks.isNotEmpty) {
        await Future.wait(updateTasks);
      }
    } catch (e) {
      print('Error cleaning up department $departmentCode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showDeleteConfirmation) return _buildDeleteConfirmationDialog();

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Container(
          width: DynamicSizeService.calculateWidthSize(context, 0.5),
          height: DynamicSizeService.calculateHeightSize(context, 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: _currentPage == 0
                      ? _buildBasicDetailsPage()
                      : _currentPage == 1
                          ? _buildAccountDetailsPage()
                          : _buildDepartmentSelectionPage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = '';
    IconData iconData = Icons.person_add;

    switch (_currentPage) {
      case 0:
        title = 'Basic Details';
        iconData = Icons.edit;
        break;
      case 1:
        title = 'Account Setup';
        iconData = Icons.account_circle;
        break;
      case 2:
        title = 'Department Assignment';
        iconData = Icons.business;
        break;
    }

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
            child: Icon(
              iconData,
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
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Faculty Modification - Step ${_currentPage + 1} of 3',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1}/3',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, Widget content, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().subtract(Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(255, 36, 66, 117),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? customValidator,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        onTap: readOnly ? onTap : null,
        controller: controller,
        keyboardType: inputType,
        style: GoogleFonts.montserrat(
          color: Colors.black87,
          fontSize: 14,
        ),
        readOnly: readOnly,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color.fromARGB(255, 36, 66, 117),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 36, 66, 117),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
        ),
        validator: customValidator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label cannot be empty';
              }
              return null;
            },
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validateContactNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number cannot be empty';
    }

    if (value.trim().length < 10) {
      return 'Contact number must be at least 10 digits';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Widget _buildBasicDetailsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Personal Information',
            Column(
              children: [
                _buildModernTextField(
                  controller: _facultyIdController,
                  label: 'Faculty ID',
                  icon: Icons.badge_outlined,
                  readOnly: true,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _middleNameController,
                        label: 'Middle Name',
                        icon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                _buildModernTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _dateOfBirthController,
                  label: 'Date of Birth',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: _selectDate,
                ),
                _buildModernTextField(
                  controller: _contactNumberController,
                  label: 'Contact Number',
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  customValidator: _validateContactNumber,
                ),
              ],
            ),
            icon: Icons.person_outline,
          ),
          _buildNavigationButtons(pageIndex: 0),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Account Credentials',
            Column(
              children: [
                _buildModernTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  customValidator: _validateEmail,
                ),
                _buildModernTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  customValidator: _validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are modifying existing faculty information. Changes will be saved to the database.',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            icon: Icons.account_circle_outlined,
          ),
          _buildNavigationButtons(pageIndex: 1),
        ],
      ),
    );
  }

  Widget _buildDepartmentSelectionPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Department Assignment',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please select the departments where this faculty will be assigned:',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ..._departmentOptions.keys.map((department) {
                  bool isSelected = _selectedDepartments.contains(department);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDepartments.remove(department);
                            } else {
                              _selectedDepartments.add(department);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(255, 36, 66, 117)
                                    .withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color.fromARGB(255, 36, 66, 117)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: isSelected
                                    ? const Color.fromARGB(255, 36, 66, 117)
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      department,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color.fromARGB(
                                                255, 36, 66, 117)
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                    Text(
                                      'Department Code: ${_departmentOptions[department]}',
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
                        ),
                      ),
                    ),
                  );
                }).toList(),
                if (_selectedDepartments.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orange.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please select at least one department to continue with the registration.',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            icon: Icons.business_outlined,
          ),
          _buildNavigationButtons(pageIndex: 2),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons({required int pageIndex}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (pageIndex == 0)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Color.fromARGB(255, 244, 67, 54)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _showDeleteConfirmation = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => setState(() => _currentPage = pageIndex - 1),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(
                'Back',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : (pageIndex < 2
                        ? () => _nextPage(pageIndex)
                        : _modifyFaculty),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        pageIndex < 2 ? Icons.arrow_forward : Icons.check,
                        size: 18,
                      ),
                label: Text(
                  _isLoading
                      ? 'Processing...'
                      : (pageIndex < 2 ? 'Next' : 'Update Faculty'),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 36, 66, 117),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _nextPage(int currentPageIndex) {
    if (currentPageIndex == 0) {
      if (_formKey.currentState!.validate()) {
        if (_selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select date of birth',
                style: GoogleFonts.montserrat(),
              ),
              backgroundColor: Colors.orange.shade600,
            ),
          );
          return;
        }
        setState(() => _currentPage = 1);
      }
    } else if (currentPageIndex == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentPage = 2);
      }
    }
  }

  Future<void> _removeFacultyFromCollections(String facultyId) async {
    List<String> departmentalCollections = [
      'pre-dept',
      'pri-dept',
      'jhs-dept',
      'abm-dept',
      'humms-dept',
      'gas-dept',
      'ict-dept',
      'he-dept'
    ];

    for (String collection in departmentalCollections) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('adviser', isEqualTo: '/entity/$facultyId')
          .get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.update({'adviser': FieldValue.delete()});
      }
    }

    QuerySnapshot classSubjectsSnapshot =
        await FirebaseFirestore.instance.collection('class-subjects').get();

    for (DocumentSnapshot doc in classSubjectsSnapshot.docs) {
      if (doc['teacherId'] == '/entity/$facultyId') {
        await doc.reference.update({'teacherId': FieldValue.delete()});
      }
    }
  }

  Future<void> _modifyFaculty() async {
    if (_selectedDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one department',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String facultyId = _facultyIdController.text.trim();
      String firstName = _firstNameController.text.trim();
      String middleName = _middleNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String contactNumber = _contactNumberController.text.trim();

      List<String> departmentCodes = _selectedDepartments
          .map((dept) => _departmentOptions[dept]!)
          .toList();

      await _removeFacultyFromCollections(facultyId);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("entity")
          .where('userID', isEqualTo: facultyId)
          .where('entity', isEqualTo: 2)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String documentId = querySnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection("entity")
            .doc(documentId)
            .update({
          'userName00': firstName,
          'userName01': lastName,
          'userName02': middleName,
          'birthday': Timestamp.fromDate(_selectedDate!),
          'contactNumber': contactNumber,
          'userMail': email,
          'userKey': password,
          'lastSession': Timestamp.fromDate(DateTime.now()),
          'department': departmentCodes,
        });

        Navigator.of(context).pop();
        widget.onRefresh();

        useToastify.showLoadingToast(
          context,
          "Update Successful",
          "Faculty $facultyId has been successfully updated!",
        );
      } else {
        throw Exception('Faculty with ID $facultyId not found');
      }
    } catch (e) {
      print('Modification error: $e');
      useToastify.showErrorToast(
        context,
        "Update Failed",
        "An error occurred during update. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
