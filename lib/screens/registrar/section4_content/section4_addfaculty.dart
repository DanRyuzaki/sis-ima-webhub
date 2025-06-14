import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/models/facultyProfileModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class AddFacultyDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<facultyProfileModel> facultyDataDeployed;

  const AddFacultyDialog({
    Key? key,
    required this.onRefresh,
    required this.facultyDataDeployed,
  }) : super(key: key);

  @override
  _AddFacultyDialogState createState() => _AddFacultyDialogState();
}

class _AddFacultyDialogState extends State<AddFacultyDialog> {
  final _formKey = GlobalKey<FormState>();

  final _facultyIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _contactNumberController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _selectedDate;
  bool _obscurePassword = true;
  int _currentPage = 0;
  bool _isLoading = false;
  List<String> _selectedDepartments = [];

  // Department options mapping
  final Map<String, String> _departmentOptions = {
    'Pre-School': 'pre-dept',
    'Primary School': 'pri-dept',
    'Junior High School': 'jhs-dept',
    'ABM - Senior High School': 'abm-dept',
    'HUMMS - Senior High School': 'humms-dept',
    'GAS - Senior High School': 'gas-dept',
    'ICT - Senior High School': 'ict-dept',
    'HE - Senior High School': 'he-dept'
  };

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        iconData = Icons.person_add;
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
                  'Faculty Registration - Step ${_currentPage + 1} of 3',
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
      initialDate: DateTime.now().subtract(Duration(days: 6570)),
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
          fillColor: Colors.white,
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

  String? _validateFacultyId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Faculty ID cannot be empty';
    }

    for (var faculty in widget.facultyDataDeployed) {
      if (faculty.facultyId == value.trim()) {
        return 'This Faculty ID is already being used';
      }
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    for (var faculty in widget.facultyDataDeployed) {
      if (faculty.facultyEmail == value.trim()) {
        return 'This email is already being used';
      }
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

    for (var faculty in widget.facultyDataDeployed) {
      if (faculty.contactNumber == value.trim()) {
        return 'This contact number is already being used';
      }
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
                  customValidator: _validateFacultyId,
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Password should be at least 6 characters long for security.',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.blue.shade700,
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
        mainAxisAlignment: pageIndex == 0
            ? MainAxisAlignment.end
            : MainAxisAlignment.spaceBetween,
        children: [
          if (pageIndex > 0)
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
                        : _registerFaculty),
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
                      : (pageIndex < 2 ? 'Next' : 'Register Faculty'),
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
      // Validate basic details page
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
      // Validate account details page
      if (_formKey.currentState!.validate()) {
        setState(() => _currentPage = 2);
      }
    }
  }

  Future<void> _registerFaculty() async {
    // Validate department selection
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

      print('Registering faculty...');
      print('Faculty ID: $facultyId');
      print('Name: $firstName $middleName $lastName');
      print('Email: $email');
      print('Contact: $contactNumber');
      print('Date of Birth: $_selectedDate');
      print('Departments: $departmentCodes');

      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      try {
        await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance.collection("entity").add({
          'userID': facultyId,
          'userName00': firstName,
          'userName01': lastName,
          'userName02': middleName,
          'birthday': Timestamp.fromDate(_selectedDate!),
          'contactNumber': contactNumber,
          'advisoryClassId': <String>[],
          'subjectsList': <String>[],
          'userMail': email,
          'userKey': password,
          'entity': 2,
          'userPhotoID': 'default',
          'lastSession': Timestamp.fromDate(DateTime.now()),
          'department': departmentCodes,
        });

        Navigator.of(context).pop();
        widget.onRefresh();

        useToastify.showLoadingToast(
          context,
          "Registration Successful",
          "Faculty $facultyId has been successfully registered to ${_selectedDepartments.join(', ')}!",
        );
      } catch (authError) {
        print('Authentication error: $authError');
        useToastify.showErrorToast(
          context,
          "Registration Failed",
          "Failed to create user account. Please check the email and password.",
        );
      } finally {
        await tempApp.delete();
      }
    } catch (e) {
      print('Registration error: $e');
      useToastify.showErrorToast(
        context,
        "Registration Failed",
        "An error occurred during registration. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
