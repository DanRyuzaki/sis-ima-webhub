import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/studentProfileModel.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class ViewAdvisoryDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<studentProfileModel> studentDataDeployed;
  final List<AuthenticationModel> authDataDeployed;
  final studentProfileModel studentToModify;
  final AuthenticationModel authDataToModify;

  const ViewAdvisoryDialog({
    Key? key,
    required this.onRefresh,
    required this.studentDataDeployed,
    required this.authDataDeployed,
    required this.studentToModify,
    required this.authDataToModify,
  }) : super(key: key);

  @override
  _ViewAdvisoryDialogState createState() => _ViewAdvisoryDialogState();
}

class _ViewAdvisoryDialogState extends State<ViewAdvisoryDialog> {
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  bool _isLoading = false;

  final _studentIdController = TextEditingController();
  final _entryYearController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _addressController = TextEditingController();
  final _religionController = TextEditingController();
  final _contactNumberController = TextEditingController();

  final _fatherFirstNameController = TextEditingController();
  final _fatherMiddleNameController = TextEditingController();
  final _fatherLastNameController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _fatherContactController = TextEditingController();

  final _motherFirstNameController = TextEditingController();
  final _motherMiddleNameController = TextEditingController();
  final _motherLastNameController = TextEditingController();
  final _motherOccupationController = TextEditingController();
  final _motherContactController = TextEditingController();

  final _guardianFirstNameController = TextEditingController();
  final _guardianMiddleNameController = TextEditingController();
  final _guardianLastNameController = TextEditingController();
  final _guardianOccupationController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _guardianRelationController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  DateTime? _selectedDate;
  bool _obscurePassword = true;
  bool _birthCertificate = false;
  bool _form137 = false;
  String _captchaWord = '';
  bool _showDeleteConfirmation = false;
  String? _selectedClass;
  List<Map<String, dynamic>> _availableClasses = [];
  String _gradeStatus = 'Not Calculated';
  List<Map<String, dynamic>> _gradeData = [];
  bool _isLoadingGrades = false;
  @override
  void initState() {
    super.initState();
    _initializeFields();
    _fetchAvailableClasses();
    _calculateGradeStatus();
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
      Set<String> seenClassCodes = {};

      for (String dept in departments) {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection(dept).get();

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String classCode = data['class-code'] ?? '';

          if (classCode.isNotEmpty && !seenClassCodes.contains(classCode)) {
            seenClassCodes.add(classCode);
            classes.add({
              'classCode': classCode,
              'adviser': data['adviser'] ?? '',
              'department': dept,
              'docId': doc.id,
              'enrolledSubjects': data['enrolled-subjects'] ?? [],
            });
          }
        }
      }

      setState(() {
        _availableClasses = classes;
        String? currentClass = widget.studentToModify.enrolledClass;
        if (currentClass.isNotEmpty) {
          bool classExists =
              classes.any((cls) => cls['classCode'] == currentClass);
          if (classExists) {
            _selectedClass = currentClass;
          } else {
            _selectedClass = null;
          }
        } else {
          _selectedClass = null;
        }
      });
    } catch (e) {
      print('Error fetching classes: $e');
      setState(() {
        _availableClasses = [];
        _selectedClass = null;
      });
    }
  }

  void _initializeFields() {
    final student = widget.studentToModify;
    final auth = widget.authDataToModify;

    _studentIdController.text = student.studentId;
    _entryYearController.text = student.entryYear;

    _firstNameController.text = auth.firstName;
    _middleNameController.text = auth.middleName;
    _lastNameController.text = auth.lastName;
    _selectedDate = student.dateOfBirth.toDate();
    _dateOfBirthController.text = _formatDate(_selectedDate!);
    _addressController.text = student.address;
    _religionController.text = student.religion;
    _contactNumberController.text = student.contactNumber;

    _fatherFirstNameController.text = student.fatherName00;
    _fatherMiddleNameController.text = student.fatherName02;
    _fatherLastNameController.text = student.fatherName01;
    _fatherOccupationController.text = student.fatherOccupation;
    _fatherContactController.text = student.fatherContact;

    _motherFirstNameController.text = student.motherName00;
    _motherMiddleNameController.text = student.motherName02;
    _motherLastNameController.text = student.motherName01;
    _motherOccupationController.text = student.motherOccupation;
    _motherContactController.text = student.motherContact;

    _guardianFirstNameController.text = student.guardianName00;
    _guardianMiddleNameController.text = student.guardianName02;
    _guardianLastNameController.text = student.guardianName01;
    _guardianOccupationController.text = student.guardianOccupation;
    _guardianContactController.text = student.guardianContact;
    _guardianRelationController.text = student.guardianRelation;

    _emailController.text = auth.userMail;
    _passwordController.text = auth.userKey;

    _birthCertificate = student.birthCertificate;
    _form137 = student.form137;
    _captchaWord = _generateRandomString(8);
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
        length,
        (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) %
            chars.length]).join();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    final controllers = [
      _studentIdController,
      _entryYearController,
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _dateOfBirthController,
      _addressController,
      _religionController,
      _contactNumberController,
      _fatherFirstNameController,
      _fatherMiddleNameController,
      _fatherLastNameController,
      _fatherOccupationController,
      _fatherContactController,
      _motherFirstNameController,
      _motherMiddleNameController,
      _motherLastNameController,
      _motherOccupationController,
      _motherContactController,
      _guardianFirstNameController,
      _guardianMiddleNameController,
      _guardianLastNameController,
      _guardianOccupationController,
      _guardianContactController,
      _guardianRelationController,
      _emailController,
      _passwordController,
      _captchaController,
    ];

    for (final controller in controllers) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showDeleteConfirmation
        ? _buildModernDeleteConfirmationDialog()
        : AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                ? _buildParentGuardianPage()
                                : _currentPage == 2
                                    ? _buildAccountDocumentsPage()
                                    : _buildGradeStatusPage(),
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
        title = 'Family Information';
        iconData = Icons.family_restroom;
        break;
      case 2:
        title = 'Account & Documents';
        iconData = Icons.description;
        break;
      case 3:
        title = 'Grade Status';
        iconData = Icons.grade;
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
                  'Manage Advisory Student - Step ${_currentPage + 1} of 4',
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
    bool readOnly = true,
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
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
        _dateOfBirthController.text = _formatDate(picked);
      });
    }
  }

  Widget _buildClassDropdown() {
    bool isCurrentClassValid = _availableClasses
        .any((cls) => cls['classCode'] == widget.studentToModify.enrolledClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
            ),
            items: _availableClasses.map((classData) {
              String classCode = classData['classCode'] ?? '';
              return DropdownMenuItem<String>(
                value: classCode,
                child: Text(
                  classCode,
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
        if (!isCurrentClassValid &&
            widget.studentToModify.enrolledClass.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(HugeIcons.strokeRoundedAlert01,
                    color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Current enrolled class ',
                        ),
                        TextSpan(
                          text: '"${widget.studentToModify.enrolledClass}"',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const TextSpan(
                          text:
                              ' is no longer available. Please select a new class to continue.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
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
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _entryYearController,
                  label: 'Entry Year',
                  icon: Icons.calendar_view_day_outlined,
                  readOnly: true,
                ),
                Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildClassDropdown()),
              ],
            ),
            icon: Icons.person_outline,
          ),
          _buildInfoCard(
            'Personal Information',
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline,
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _middleNameController,
                        label: 'Middle Name',
                        icon: Icons.person_outline,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                _buildModernTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _dateOfBirthController,
                  label: 'Date of Birth',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: _selectDate,
                ),
                _buildModernTextField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.home_outlined,
                  maxLines: 2,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _religionController,
                  label: 'Religion',
                  icon: Icons.church_outlined,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _contactNumberController,
                  label: 'Contact Number',
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  readOnly: true,
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
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _fatherMiddleNameController,
                  label: "Father's Middle Name",
                  icon: Icons.person_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _fatherLastNameController,
                  label: "Father's Last Name",
                  icon: Icons.person_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _fatherOccupationController,
                  label: "Father's Occupation",
                  icon: Icons.work_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _fatherContactController,
                  label: "Father's Contact",
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  readOnly: true,
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
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _motherMiddleNameController,
                  label: "Mother's Middle Name",
                  icon: Icons.person_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _motherLastNameController,
                  label: "Mother's Last Name",
                  icon: Icons.person_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _motherOccupationController,
                  label: "Mother's Occupation",
                  icon: Icons.work_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _motherContactController,
                  label: "Mother's Contact",
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  readOnly: true,
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
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _guardianMiddleNameController,
                  label: "Guardian's Middle Name",
                  icon: Icons.person_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _guardianLastNameController,
                  label: "Guardian's Last Name",
                  icon: Icons.person_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _guardianOccupationController,
                  label: "Guardian's Occupation",
                  icon: Icons.work_outline,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _guardianContactController,
                  label: "Guardian's Contact",
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _guardianRelationController,
                  label: "Relation to Student",
                  icon: Icons.people_outline,
                  readOnly: true,
                ),
              ],
            ),
            icon: Icons.person_outline,
          ),
          _buildNavigationButtons(pageIndex: 1),
        ],
      ),
    );
  }

  Widget _buildAccountDocumentsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Account Information',
            Column(
              children: [
                _buildModernTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  readOnly: true,
                ),
                _buildModernTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  readOnly: true,
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
          _buildInfoCard(
            'Document Requirements',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Please confirm the documents submitted:",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _birthCertificate,
                      onChanged: (value) {
                        setState(() => _birthCertificate = value!);
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
                        setState(() => _form137 = value!);
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
          _buildNavigationButtons(pageIndex: 2),
        ],
      ),
    );
  }

  Widget _buildGradeStatusPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Grade Status Overview',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Overall Grade Status:",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getGradeStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _getGradeStatusColor().withOpacity(0.3)),
                          ),
                          child: Text(
                            _gradeStatus,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getGradeStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_gradeData.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Overall Average:",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            "${_calculateOverallAverage().toStringAsFixed(2)}",
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getGradeStatusColor(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            icon: Icons.grade,
          ),
          _buildInfoCard(
            'Subject Grades',
            Column(
              children: [
                if (_isLoadingGrades)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_gradeData.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No grades available',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildGradesTable(),
              ],
            ),
            icon: Icons.table_chart,
          ),
          _buildNavigationButtons(pageIndex: 3),
        ],
      ),
    );
  }

  Widget _buildGradesTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 36, 66, 117),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Subject',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '1st Quarter',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '2nd Quarter',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '3rd Quarter',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '4th Quarter',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Average',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...(_gradeData.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> grade = entry.value;
            bool isEven = index % 2 == 0;

            return Container(
              decoration: BoxDecoration(
                color: isEven ? Colors.grey.shade50 : Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        grade['subject'].toString(),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        grade['firstQuarter'] != null
                            ? grade['firstQuarter'].toString()
                            : 'N/A',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        grade['secondQuarter'] != null
                            ? grade['secondQuarter'].toString()
                            : 'N/A',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        grade['thirdQuarter'] != null
                            ? grade['thirdQuarter'].toString()
                            : 'N/A',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        grade['fourthQuarter'] != null
                            ? grade['fourthQuarter'].toString()
                            : 'N/A',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getGradeColor(grade['average']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          grade['average'] != null
                              ? grade['average'].toStringAsFixed(1)
                              : 'N/A',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(grade['average']),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getGradeStatusColorForSubject(grade['average'])
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getSubjectStatus(grade['average']),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getGradeStatusColorForSubject(
                                grade['average']),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Color _getGradeStatusColor() {
    switch (_gradeStatus) {
      case 'Failed':
        return Colors.red;
      case 'Good':
        return Colors.green;
      case 'Very Good':
        return Colors.blue;
      case 'Excellent':
        return Colors.purple;
      case 'Outstanding':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  Color _getGradeColor(double? grade) {
    if (grade == null) return Colors.grey;
    if (grade < 75) return Colors.red;
    if (grade < 85) return Colors.orange;
    if (grade < 90) return Colors.blue;
    if (grade < 95) return Colors.green;
    return Colors.purple;
  }

  Color _getGradeStatusColorForSubject(double? grade) {
    if (grade == null) return Colors.grey;
    if (grade < 75) return Colors.red;
    return Colors.green;
  }

  String _getSubjectStatus(double? grade) {
    if (grade == null) return 'N/A';
    return grade >= 75 ? 'PASSED' : 'FAILED';
  }

  double _calculateOverallAverage() {
    if (_gradeData.isEmpty) return 0.0;

    double total = 0;
    int count = 0;

    for (var grade in _gradeData) {
      if (grade['average'] != null) {
        total += grade['average'];
        count++;
      }
    }

    return count > 0 ? total / count : 0.0;
  }

  double parseGrade(dynamic value) {
    if (value == null) {
      return 0.0;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }

  Future<void> _calculateGradeStatus() async {
    setState(() {
      _isLoadingGrades = true;
    });

    try {
      final studentId = widget.studentToModify.studentId;
      final enrolledClass = widget.studentToModify.enrolledClass;
      final classCodeParts = enrolledClass.split('-');
      final classDept = '${classCodeParts[0].toLowerCase()}-dept';

      final classQuery = await FirebaseFirestore.instance
          .collection(classDept)
          .where('class-code', isEqualTo: enrolledClass)
          .get();

      if (classQuery.docs.isNotEmpty) {
        final classDoc = classQuery.docs.first;
        final enrolledSubjects = classDoc['enrolled-subjects'] as List<dynamic>;
        double totalGrade = 0;
        int subjectCount = 0;
        List<Map<String, dynamic>> tempGradeData = [];

        for (var subject in enrolledSubjects) {
          final classSubjectCode = '$enrolledClass:$subject';

          Map<String, dynamic> subjectGradeData = {
            'subject': subject,
            'firstQuarter': null,
            'secondQuarter': null,
            'thirdQuarter': null,
            'fourthQuarter': null,
            'average': null,
          };

          try {
            final classSubjectDoc = await FirebaseFirestore.instance
                .collection('class-subjects')
                .doc(classSubjectCode)
                .get();

            final gradeDocQuery = await FirebaseFirestore.instance
                .collection('class-subjects')
                .doc(classSubjectCode)
                .collection('grades')
                .where('studentId', isEqualTo: studentId)
                .get();

            if (gradeDocQuery.docs.isNotEmpty && classSubjectDoc.exists) {
              final gradeData = gradeDocQuery.docs.first.data();
              final classSubjectData = classSubjectDoc.data()!;
              final subjectName = classSubjectData['subjectName'] ?? subject;

              final firstQuarter = parseGrade(gradeData['firstQuarter']);
              final secondQuarter = parseGrade(gradeData['secondQuarter']);
              final thirdQuarter = parseGrade(gradeData['thirdQuarter']);
              final fourthQuarter = parseGrade(gradeData['fourthQuarter']);

              final subjectGrade = (firstQuarter +
                      secondQuarter +
                      thirdQuarter +
                      fourthQuarter) /
                  4;

              subjectGradeData = {
                'subject': subjectName,
                'firstQuarter': firstQuarter,
                'secondQuarter': secondQuarter,
                'thirdQuarter': thirdQuarter,
                'fourthQuarter': fourthQuarter,
                'average': subjectGrade,
              };

              totalGrade += subjectGrade;
              subjectCount++;
            } else if (classSubjectDoc.exists) {
              final classSubjectData = classSubjectDoc.data()!;
              final subjectName = classSubjectData['subjectName'] ?? subject;
              subjectGradeData['subject'] = subjectName;
            }
          } catch (e) {
            print('Error processing subject $subject: $e');
          }

          tempGradeData.add(subjectGradeData);
        }

        setState(() {
          _gradeData = tempGradeData;
          _isLoadingGrades = false;
        });

        if (subjectCount > 0) {
          final averageGrade = totalGrade / subjectCount;
          setState(() {
            if (averageGrade <= 74) {
              _gradeStatus = 'Failed';
            } else if (averageGrade <= 84) {
              _gradeStatus = 'Good';
            } else if (averageGrade <= 90) {
              _gradeStatus = 'Very Good';
            } else if (averageGrade <= 97) {
              _gradeStatus = 'Excellent';
            } else {
              _gradeStatus = 'Outstanding';
            }
          });
        } else {
          setState(() {
            _gradeStatus = 'No Grades Available';
          });
        }
      } else {
        setState(() {
          _gradeData = [];
          _gradeStatus = 'Class Not Found';
          _isLoadingGrades = false;
        });
      }
    } catch (e) {
      print('Error calculating grade status: $e');
      setState(() {
        _gradeData = [];
        _gradeStatus = 'Error Loading Grades';
        _isLoadingGrades = false;
      });
    }
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
                        : () => Navigator.of(context).pop()),
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
                      : (pageIndex < 3 ? 'Next' : 'Finish'),
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
      if (_validateBasicInfo()) {
        setState(() => _currentPage = 1);
      }
    } else if (currentPageIndex == 1) {
      if (_validateFamilyInfo()) {
        setState(() => _currentPage = 2);
      }
    } else if (currentPageIndex == 2) {
      setState(() => _currentPage = 3);
    }
  }

  bool _validateBasicInfo() {
    final fields = [
      _firstNameController,
      _lastNameController,
      _addressController,
      _religionController,
      _contactNumberController,
    ];

    for (final field in fields) {
      if (field.text.trim().isEmpty) {
        useToastify.showErrorToast(
            context, "Validation Error", "Please fill all required fields");
        return false;
      }
    }

    if (_selectedDate == null) {
      useToastify.showErrorToast(
          context, "Validation Error", "Please select date of birth");
      return false;
    }

    return true;
  }

  bool _validateFamilyInfo() {
    final requiredFields = [
      _fatherFirstNameController,
      _fatherLastNameController,
      _motherFirstNameController,
      _motherLastNameController,
      _guardianFirstNameController,
      _guardianLastNameController,
      _guardianRelationController,
    ];

    for (final field in requiredFields) {
      if (field.text.trim().isEmpty) {
        useToastify.showErrorToast(
            context, "Validation Error", "Please fill all required fields");
        return false;
      }
    }

    return true;
  }

  Widget _buildModernDeleteConfirmationDialog() {
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
                            "This will permanently delete the records of '${widget.authDataToModify.lastName}, ${widget.authDataToModify.firstName} ${widget.authDataToModify.middleName.isNotEmpty ? widget.authDataToModify.middleName[0] : ''}'. This action cannot be undone.",
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
                      color: const Color.fromARGB(255, 36, 66, 117),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildModernTextField(
                    controller: _captchaController,
                    label: "Confirmation",
                    icon: Icons.text_fields,
                    customValidator: (value) {
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
                          Navigator.of(context).pop();
                        } else {
                          useToastify.showErrorToast(
                            context,
                            'Oops!',
                            "Incorrect confirmation word. Please try again.",
                          );
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
                            'Delete Student',
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
}
