import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class EditUserDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<AuthenticationModel> userDataDeployed;
  final AuthenticationModel user;

  EditUserDialog(
      {required this.onRefresh,
      required this.userDataDeployed,
      required this.user});

  @override
  _EditUserDialogState createState() => _EditUserDialogState(
      onRefresh: onRefresh, userDataDeployed: userDataDeployed, user: user);
}

class _EditUserDialogState extends State<EditUserDialog> {
  final VoidCallback onRefresh;
  final List<AuthenticationModel> userDataDeployed;
  final AuthenticationModel user;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _userKeyController = TextEditingController();
  final _userIdReTypeController = TextEditingController();

  String _entityType = 'Admin';
  bool _obscureText = true;
  bool _isSubmitting = false;
  bool _showDeleteConfirmation = false;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;
  static const Color _adminAccent = Color.fromARGB(255, 220, 53, 69);
  static const Color _successColor = Color.fromARGB(255, 40, 167, 69);
  static const Color _warningColor = Color.fromARGB(255, 255, 193, 7);

  _EditUserDialogState(
      {required this.onRefresh,
      required this.userDataDeployed,
      required this.user});

  @override
  void initState() {
    super.initState();
    _emailController.text = user.userMail;
    _userKeyController.text = user.userKey;
    _entityType = user.entityType == 0
        ? 'Admin'
        : user.entityType == 1
            ? 'Registrar'
            : user.entityType == 2
                ? 'Faculty'
                : 'Student';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: DynamicSizeService.calculateWidthSize(
            context, _showDeleteConfirmation ? 0.35 : 0.45),
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
                    child: _showDeleteConfirmation
                        ? _buildDeleteConfirmation()
                        : _buildEditForm(),
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
          colors: _showDeleteConfirmation
              ? [_adminAccent, Color.fromARGB(255, 200, 35, 51)]
              : [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
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
              _showDeleteConfirmation
                  ? HugeIcons.strokeRoundedUserRemove01
                  : HugeIcons.strokeRoundedUserEdit01,
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
                  _showDeleteConfirmation ? "Delete User" : "Edit User",
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _showDeleteConfirmation
                      ? 'Permanently remove user from system'
                      : 'Modify user account credentials',
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

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserInfoDisplay(),
        const SizedBox(height: 24),
        _buildFormSection("Account Credentials", [
          _buildModernTextField(
              _emailController, 'Email Address', HugeIcons.strokeRoundedMail01,
              inputType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildPasswordField(),
        ]),
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildUserInfoDisplay() {
    Color entityColor = _getEntityColor(_entityType);
    IconData entityIcon = _getEntityIcon(_entityType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(HugeIcons.strokeRoundedUserCheck01,
                  size: 16, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                "User Information",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('User ID', user.userID,
              HugeIcons.strokeRoundedUserIdVerification),
          const SizedBox(height: 12),
          _buildInfoRow(
              'Full Name',
              '${user.firstName} ${user.middleName.isNotEmpty ? user.middleName + ' ' : ''}${user.lastName}',
              HugeIcons.strokeRoundedUser),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(HugeIcons.strokeRoundedUserGroup,
                  size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Entity Type',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: entityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: entityColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entityIcon, size: 14, color: entityColor),
                const SizedBox(width: 6),
                Text(
                  _entityType,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: entityColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
            }
            if (label == 'Email Address') {
              for (var userData in userDataDeployed) {
                if (userData.userMail == value!.trim() &&
                    userData.userID != user.userID) {
                  return 'This email is already being used by another entity';
                }
              }
              if (value != null &&
                  value.isNotEmpty &&
                  !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                return 'Please enter a valid email address';
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
            Icon(HugeIcons.strokeRoundedLockPassword,
                size: 16, color: _primaryColor),
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
                _obscureText
                    ? HugeIcons.strokeRoundedView
                    : HugeIcons.strokeRoundedViewOff,
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

  Widget _buildDeleteConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _adminAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _adminAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(HugeIcons.strokeRoundedAlert02,
                  color: _adminAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This action cannot be undone. The user will be permanently removed from the system.',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: _adminAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildFormSection("Confirmation", [
          Text(
            'To confirm deletion, please re-type the User ID below:',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.userID,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildModernTextField(_userIdReTypeController, 'Re-type User ID',
              HugeIcons.strokeRoundedUserIdVerification),
        ]),
        const SizedBox(height: 32),
        _buildDeleteActionButtons(),
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
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _showDeleteConfirmation = true;
                    });
                  },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _adminAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(HugeIcons.strokeRoundedUserRemove01,
                    color: _adminAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _adminAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : userModification,
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Updating...',
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
                        HugeIcons.strokeRoundedUserEdit01,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Update User',
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

  Widget _buildDeleteActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _showDeleteConfirmation = false;
                _userIdReTypeController.clear();
              });
            },
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
            onPressed: _handleDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: _adminAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  HugeIcons.strokeRoundedUserRemove01,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete User',
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

  Color _getEntityColor(String entityType) {
    switch (entityType) {
      case 'Admin':
        return _adminAccent;
      case 'Registrar':
        return _successColor;
      case 'Faculty':
        return _warningColor;
      default:
        return _primaryColor;
    }
  }

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'Admin':
        return HugeIcons.strokeRoundedUserShield01;
      case 'Registrar':
        return HugeIcons.strokeRoundedUserCheck01;
      case 'Faculty':
        return HugeIcons.strokeRoundedUserStar01;
      default:
        return HugeIcons.strokeRoundedUser;
    }
  }

  Future<void> userModification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      CollectionReference entityCollection =
          FirebaseFirestore.instance.collection("entity");

      QuerySnapshot querySnapshot = await entityCollection
          .where("userMail", isEqualTo: user.userMail)
          .get();

      String newEmail = _emailController.text.trim();
      String newUserKey = _userKeyController.text.trim();
      String oldEmail = user.userMail;
      String oldUserKey = user.userKey;

      try {
        FirebaseApp tempApp = await Firebase.initializeApp(
          name: 'TempAppForUpdate',
          options: Firebase.app().options,
        );

        UserCredential tempCredential = await FirebaseAuth.instanceFor(
                app: tempApp)
            .signInWithEmailAndPassword(email: oldEmail, password: oldUserKey);
        User tempUser = tempCredential.user!;

        await tempUser.delete();

        await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(
                email: newEmail, password: newUserKey);

        await tempApp.delete();
        await entityCollection.doc(querySnapshot.docs.first.id).update({
          'userMail': newEmail,
          'userKey': newUserKey,
          'lastSession': Timestamp.fromDate(DateTime.now()),
        });

        Navigator.of(context).pop();
        onRefresh();
        useToastify.showLoadingToast(context, "Successful Modification",
            "${user.userID}'s account credentials have been updated!");
      } catch (e) {
        Navigator.of(context).pop();
        onRefresh();
        useToastify.showErrorToast(context, "Error",
            "Failed to update the credentials. Please contact the developer.");
        print("Force Update Error: $e");
      }

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _handleDelete() async {
    if (_formKey.currentState!.validate()) {
      final retypedId = _userIdReTypeController.text.trim();
      final originalId = user.userID;

      if (retypedId != originalId) {
        useToastify.showErrorToast(context, "Delete Failed",
            "Re-typed User ID does not match the original User ID.");
        return;
      }

      try {
        CollectionReference entityCollection =
            FirebaseFirestore.instance.collection("entity");

        QuerySnapshot querySnapshot =
            await entityCollection.where("userID", isEqualTo: originalId).get();

        if (querySnapshot.docs.isEmpty) {
          Navigator.of(context).pop();
          useToastify.showErrorToast(context, "User Not Found",
              "No entity found with user ID: $originalId");
          return;
        }

        FirebaseApp tempApp = await Firebase.initializeApp(
          name: 'TempDeleteApp',
          options: Firebase.app().options,
        );

        try {
          String email = user.userMail;
          String password = user.userKey;

          UserCredential credential =
              await FirebaseAuth.instanceFor(app: tempApp)
                  .signInWithEmailAndPassword(email: email, password: password);

          await credential.user!.delete();
        } catch (authError) {
          print("Auth delete failed: $authError");
        } finally {
          await tempApp.delete();
        }

        await entityCollection.doc(querySnapshot.docs.first.id).delete();

        Navigator.of(context).pop();
        onRefresh();
        useToastify.showLoadingToast(context, "Deleted Successfully",
            "$originalId has been removed from the system.");
      } catch (e) {
        Navigator.of(context).pop();
        useToastify.showErrorToast(context, "Error",
            "Failed to delete the user. Please contact the developer.");
        print("Full Delete Error: $e");
      }
    }
  }
}
