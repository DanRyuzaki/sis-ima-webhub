import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/models/authModel.dart';

class EnrollStudentDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<AuthenticationModel> existingStudents;

  const EnrollStudentDialog({
    Key? key,
    required this.onRefresh,
    required this.existingStudents,
  }) : super(key: key);

  @override
  _EnrollStudentDialogState createState() => _EnrollStudentDialogState();
}

class _EnrollStudentDialogState extends State<EnrollStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  bool _isLoading = false;

  final _studentIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _religionController = TextEditingController();
  final _entryYearController = TextEditingController();
  DateTime? _selectedDate;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedClass;
  List<Map<String, dynamic>> _availableClasses = [];
  bool _obscurePassword = true;

  final _fatherFirstNameController = TextEditingController();
  final _fatherLastNameController = TextEditingController();
  final _fatherMiddleNameController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _fatherContactController = TextEditingController();
  final _motherFirstNameController = TextEditingController();
  final _motherLastNameController = TextEditingController();
  final _motherMiddleNameController = TextEditingController();
  final _motherOccupationController = TextEditingController();
  final _motherContactController = TextEditingController();
  final _guardianFirstNameController = TextEditingController();
  final _guardianLastNameController = TextEditingController();
  final _guardianMiddleNameController = TextEditingController();
  final _guardianOccupationController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _guardianRelationController = TextEditingController();

  bool _birthCertificate = false;
  bool _form137 = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableClasses();
    _entryYearController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchAvailableClasses() async {
    try {
      List<String> departments = [
        'pre-dept',
        'pri-dept',
        'jhs-dept',
        'abm-dept',
        'humms-dept',
        'gas-dept',
        'ict-dept',
        'he-dept'
      ];
      List<Map<String, dynamic>> classes = [];

      for (String dept in departments) {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection(dept).get();

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          classes.add({
            'classCode': data['class-code'] ?? '',
            'adviser': data['adviser'] ?? '',
            'department': dept,
            'docId': doc.id,
            'enrolledSubjects': data['enrolled-subjects'] ?? [],
          });
        }
      }

      setState(() {
        _availableClasses = classes;
      });
    } catch (e) {
      print('Error fetching classes: $e');
    }
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
                      ? _buildBasicInformationPage()
                      : _currentPage == 1
                          ? _buildClassAndAccountPage()
                          : _currentPage == 2
                              ? _buildParentGuardianPage()
                              : _buildDocumentsPage(),
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
        title = 'Basic Information';
        iconData = Icons.person_add;
        break;
      case 1:
        title = 'Class & Account';
        iconData = Icons.account_circle;
        break;
      case 2:
        title = 'Family Information';
        iconData = Icons.family_restroom;
        break;
      case 3:
        title = 'Documents';
        iconData = Icons.description;
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
                  'Student Enrollment - Step ${_currentPage + 1} of 4',
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
              '${_currentPage + 1}/4',
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
    int maxLines = 1,
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
        maxLines: maxLines,
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

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 4380)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 36, 66, 117),
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

  Widget _buildBasicInformationPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Student Information',
            Column(
              children: [
                _buildModernTextField(
                  controller: _studentIdController,
                  label: 'Student ID (LRN)',
                  icon: Icons.badge_outlined,
                  customValidator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Student ID cannot be empty';
                    }
                    for (var student in widget.existingStudents) {
                      if (student.userID == value.trim()) {
                        return 'This Student ID is already being used';
                      }
                    }
                    return null;
                  },
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
                ),
                _buildModernTextField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.home_outlined,
                  maxLines: 2,
                ),
                _buildModernTextField(
                  controller: _religionController,
                  label: 'Religion',
                  icon: Icons.church_outlined,
                ),
                _buildModernTextField(
                  controller: _entryYearController,
                  label: 'Entry Year',
                  icon: Icons.calendar_view_day_outlined,
                  inputType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

  Widget _buildClassAndAccountPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Class Enrollment',
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: InputDecoration(
                      labelText: 'Select Class',
                      labelStyle: GoogleFonts.montserrat(
                          color: Colors.grey.shade600, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.class_outlined,
                        color: Color.fromARGB(255, 36, 66, 117),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
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
                    ),
                    items: _availableClasses.map((classData) {
                      return DropdownMenuItem<String>(
                        value: classData['classCode'],
                        child: Text(
                          classData['classCode'],
                          style: GoogleFonts.montserrat(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a class';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            icon: Icons.class_outlined,
          ),
          _buildInfoCard(
            'Account Information',
            Column(
              children: [
                _buildModernTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  customValidator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email cannot be empty';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    for (var student in widget.existingStudents) {
                      if (student.userMail == value.trim()) {
                        return 'This email is already being used';
                      }
                    }
                    return null;
                  },
                ),
                _buildModernTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  customValidator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password cannot be empty';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
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

  Widget _buildParentGuardianPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            "Father's Information",
            Column(
              children: [
                _buildModernTextField(
                  controller: _fatherFirstNameController,
                  label: "Father's First Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _fatherLastNameController,
                  label: "Father's Last Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _fatherMiddleNameController,
                  label: "Father's Middle Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _fatherOccupationController,
                  label: "Father's Occupation",
                  icon: Icons.work_outline,
                ),
                _buildModernTextField(
                  controller: _fatherContactController,
                  label: "Father's Contact Number",
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
            icon: Icons.person_outline,
          ),
          _buildInfoCard(
            "Mother's Information",
            Column(
              children: [
                _buildModernTextField(
                  controller: _motherFirstNameController,
                  label: "Mother's First Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _motherLastNameController,
                  label: "Mother's Last Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _motherMiddleNameController,
                  label: "Mother's Middle Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _motherOccupationController,
                  label: "Mother's Occupation",
                  icon: Icons.work_outline,
                ),
                _buildModernTextField(
                  controller: _motherContactController,
                  label: "Mother's Contact Number",
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
            icon: Icons.person_outline,
          ),
          _buildInfoCard(
            "Guardian's Information",
            Column(
              children: [
                _buildModernTextField(
                  controller: _guardianFirstNameController,
                  label: "Guardian's First Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _guardianLastNameController,
                  label: "Guardian's Last Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _guardianMiddleNameController,
                  label: "Guardian's Middle Name",
                  icon: Icons.person_outline,
                ),
                _buildModernTextField(
                  controller: _guardianOccupationController,
                  label: "Guardian's Occupation",
                  icon: Icons.work_outline,
                ),
                _buildModernTextField(
                  controller: _guardianContactController,
                  label: "Guardian's Contact Number",
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _buildModernTextField(
                  controller: _guardianRelationController,
                  label: "Relation to Student",
                  icon: Icons.people_outline,
                ),
              ],
            ),
            icon: Icons.person_outline,
          ),
          _buildNavigationButtons(pageIndex: 2),
        ],
      ),
    );
  }

  Widget _buildDocumentsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            "Document Requirements",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Please confirm the documents submitted:",
                  style: GoogleFonts.montserrat(
                    fontSize: DynamicSizeService.calculateAspectRatioSize(
                        context, 0.018),
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _birthCertificate,
                      onChanged: (value) {
                        setState(() => _birthCertificate = value ?? false);
                      },
                      activeColor: const Color.fromARGB(255, 36, 66, 117),
                    ),
                    Text(
                      "Birth Certificate",
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _form137,
                      onChanged: (value) {
                        setState(() => _form137 = value ?? false);
                      },
                      activeColor: const Color.fromARGB(255, 36, 66, 117),
                    ),
                    Text(
                      "Form 137 (Report Card)",
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            icon: Icons.description,
          ),
          _buildNavigationButtons(pageIndex: 3),
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
                    : (pageIndex < 3
                        ? () => _nextPage(pageIndex)
                        : _enrollStudent),
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
                        pageIndex < 3 ? Icons.arrow_forward : Icons.check,
                        size: 18,
                      ),
                label: Text(
                  _isLoading
                      ? 'Processing...'
                      : (pageIndex < 3 ? 'Next' : 'Enroll Student'),
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
    } else if (currentPageIndex == 2) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentPage = 3);
      }
    }
  }

  Future<void> _enrollStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String studentId = _studentIdController.text.trim();
      String firstName = _firstNameController.text.trim();
      String middleName = _middleNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      try {
        await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance.collection("entity").add({
          'userID': studentId,
          'userName00': firstName,
          'userName01': lastName,
          'userName02': middleName,
          'entity': 3,
          'lastSession': Timestamp.fromDate(DateTime.now()),
          'userKey': password,
          'userMail': email,
        });

        await FirebaseFirestore.instance.collection("profile-information").add({
          'studentId': studentId,
          'entryYear': _entryYearController.text.trim(),
          'enrolledClass': _selectedClass,
          'address': _addressController.text.trim(),
          'birthday': Timestamp.fromDate(_selectedDate!),
          'religion': _religionController.text.trim(),
          'contactNumber': _contactNumberController.text.trim(),
          'fatherName00': _fatherFirstNameController.text.trim(),
          'fatherName01': _fatherLastNameController.text.trim(),
          'fatherName02': _fatherMiddleNameController.text.trim(),
          'fatherOccupation': _fatherOccupationController.text.trim(),
          'fatherContact': _fatherContactController.text.trim(),
          'motherName00': _motherFirstNameController.text.trim(),
          'motherName01': _motherLastNameController.text.trim(),
          'motherName02': _motherMiddleNameController.text.trim(),
          'motherOccupation': _motherOccupationController.text.trim(),
          'motherContact': _motherContactController.text.trim(),
          'guardianName00': _guardianFirstNameController.text.trim(),
          'guardianName01': _guardianLastNameController.text.trim(),
          'guardianName02': _guardianMiddleNameController.text.trim(),
          'guardianOccupation': _guardianOccupationController.text.trim(),
          'guardianContact': _guardianContactController.text.trim(),
          'guardianRelationship': _guardianRelationController.text.trim(),
          'birthCertificate': _birthCertificate,
          'form137': _form137,
        });

        await _updateClassEnrollment(studentId);

        Navigator.of(context).pop();
        widget.onRefresh();

        useToastify.showLoadingToast(
          context,
          "Enrollment Successful",
          "Student $studentId has been successfully enrolled in $_selectedClass!",
        );
      } catch (authError) {
        print('Authentication error: $authError');
        useToastify.showErrorToast(
          context,
          "Enrollment Failed",
          "Failed to create user account. Please check the email and password.",
        );
      } finally {
        await tempApp.delete();
      }
    } catch (e) {
      print('Enrollment error: $e');
      useToastify.showErrorToast(
        context,
        "Enrollment Failed",
        "An error occurred during enrollment. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateClassEnrollment(String studentId) async {
    try {
      Map<String, dynamic>? selectedClassData = _availableClasses
          .firstWhere((classData) => classData['classCode'] == _selectedClass);

      String department = selectedClassData['department'];
      String docId = selectedClassData['docId'];
      List<dynamic> enrolledSubjects = selectedClassData['enrolledSubjects'];

      DocumentReference classDoc =
          FirebaseFirestore.instance.collection(department).doc(docId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot classSnapshot = await transaction.get(classDoc);

        if (classSnapshot.exists) {
          Map<String, dynamic> classData =
              classSnapshot.data() as Map<String, dynamic>;
          List<dynamic> currentClassList = classData['class-list'] ?? [];

          if (!currentClassList.contains(studentId)) {
            currentClassList.add(studentId);
            transaction.update(classDoc, {'class-list': currentClassList});
          }
        }
      });

      for (dynamic subjectCode in enrolledSubjects) {
        String classSubjectCode = '$_selectedClass:$subjectCode';

        QuerySnapshot classSubjectsSnapshot = await FirebaseFirestore.instance
            .collection('class-subjects')
            .where('classSubjectCode', isEqualTo: classSubjectCode)
            .get();

        if (classSubjectsSnapshot.docs.isNotEmpty) {
          String classSubjectDocId = classSubjectsSnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('class-subjects')
              .doc(classSubjectDocId)
              .collection('grades')
              .add({
            'studentId': studentId,
            'firstQuarter': 0,
            'secondQuarter': 0,
            'thirdQuarter': 0,
            'fourthQuarter': 0,
          });
        }
      }

      print('Class enrollment updated successfully');
    } catch (e) {
      print('Error updating class enrollment: $e');
      throw e;
    }
  }
}
