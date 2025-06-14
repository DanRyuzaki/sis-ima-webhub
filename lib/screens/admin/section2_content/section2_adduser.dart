import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class AddUserDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<AuthenticationModel> userDataDeployed;

  AddUserDialog({required this.onRefresh, required this.userDataDeployed});

  @override
  _AddUserDialogState createState() => _AddUserDialogState(
      onRefresh: onRefresh, userDataDeployed: userDataDeployed);
}

class _AddUserDialogState extends State<AddUserDialog> {
  final VoidCallback onRefresh;
  final List<AuthenticationModel> userDataDeployed;
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userKeyController = TextEditingController();

  String _entityType = 'Admin';
  bool _obscureText = true;
  bool _isSubmitting = false;

  // Color scheme matching main section
  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;
  static const Color _adminAccent = Color.fromARGB(255, 220, 53, 69);
  static const Color _successColor = Color.fromARGB(255, 40, 167, 69);

  _AddUserDialogState(
      {required this.onRefresh, required this.userDataDeployed});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: DynamicSizeService.calculateWidthSize(context, 0.45),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 3,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModernHeader(),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserTypeSelector(),
                        const SizedBox(height: 24),
                        _buildFormSection("Basic Information", [
                          _buildModernTextField(_userIdController, 'User ID', HugeIcons.strokeRoundedUserIdVerification),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernTextField(_firstNameController, 'First Name', HugeIcons.strokeRoundedUser),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModernTextField(_middleNameController, 'Middle Name', HugeIcons.strokeRoundedUser, isRequired: false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildModernTextField(_lastNameController, 'Last Name', HugeIcons.strokeRoundedUser),
                        ]),
                        const SizedBox(height: 24),
                        _buildFormSection("Account Credentials", [
                          _buildModernTextField(_emailController, 'Email Address', HugeIcons.strokeRoundedMail01, inputType: TextInputType.emailAddress),
                          const SizedBox(height: 20),
                          _buildPasswordField(),
                        ]),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              HugeIcons.strokeRoundedUserAdd01,
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
                  "Add New User",
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a new system user account',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select User Type",
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildUserTypeCard('Admin', HugeIcons.strokeRoundedUserShield01, _adminAccent),
            const SizedBox(width: 16),
            _buildUserTypeCard('Registrar', HugeIcons.strokeRoundedUserCheck01, _successColor),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeCard(String type, IconData icon, Color color) {
    bool isSelected = _entityType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _entityType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : _lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade600,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                type,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryColor,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(color: _adminAccent, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: _lightGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _adminAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _adminAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label cannot be empty';
            } else {
              if (label == 'User ID') {
                for (var user in userDataDeployed) {
                  if (user.userID == value!.trim()) {
                    return 'This ID is already being used by existing entity';
                  }
                }
              } else if (label == 'Email Address') {
                for (var user in userDataDeployed) {
                  if (user.userMail == value!.trim()) {
                    return 'This email is already being used by existing entity';
                  }
                }
                if (value != null && value.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(HugeIcons.strokeRoundedLockPassword, size: 16, color: _primaryColor),
            const SizedBox(width: 8),
            Text(
              'Password',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryColor,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: _adminAccent, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _userKeyController,
          obscureText: _obscureText,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Enter secure password',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: _lightGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _adminAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _adminAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? HugeIcons.strokeRoundedView : HugeIcons.strokeRoundedViewOff,
                color: Colors.grey.shade600,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password cannot be empty';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : userRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Creating...',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        HugeIcons.strokeRoundedUserAdd01,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Create User',
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
    );
  }

  Future<void> userRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      CollectionReference entityCollection =
          FirebaseFirestore.instance.collection("entity");

      String userId = _userIdController.text.trim();
      String firstName = _firstNameController.text.trim();
      String middleName = _middleNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String email = _emailController.text.trim();
      String userKey = _userKeyController.text.trim();
      
      try {
        print('Form submitted');
        print('User ID: $userId');
        print('First Name: $firstName');
        print('Last Name: $lastName');
        print('Email: $email');
        print('User Key: $userKey');
        print('Entity Type: $_entityType');

        FirebaseApp tempApp = await Firebase.initializeApp(
          name: 'TemporaryApp',
          options: Firebase.app().options,
        );

        try {
          await FirebaseAuth.instanceFor(app: tempApp)
              .createUserWithEmailAndPassword(email: email, password: userKey);
          await entityCollection.add({
            'userID': userId,
            'userName00': firstName,
            'userName01': lastName,
            'userName02': middleName,
            'entity': _getEntityValue(_entityType),
            'userMail': email,
            'userKey': userKey,
            'userPhotoID': 'default',
            'lastSession': Timestamp.fromDate(DateTime.now())
          });

          Navigator.of(context).pop();
          onRefresh();
          useToastify.showLoadingToast(context, "Successful Registration",
              "$userId is now officially registered!");
        } catch (e) {
          print('Error creating user: $e');
          useToastify.showErrorToast(context, "Error",
              "Failed to create user. Please check the details and try again.");
        } finally {
          await tempApp.delete();
        }
      } catch (e) {
        Navigator.of(context).pop();
        onRefresh();
        useToastify.showErrorToast(context, "Error",
            "Failed to register the entity. Please contact the developer for investigation.");
      }

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  double _getEntityValue(String entityType) {
    switch (entityType) {
      case 'Admin':
        return 0;
      case 'Registrar':
        return 1;
      default:
        return 0;
    }
  }
}