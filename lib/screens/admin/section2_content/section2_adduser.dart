import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class AddUserDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<AuthModel> userDataDeployed;

  AddUserDialog({required this.onRefresh, required this.userDataDeployed});

  @override
  _AddUserDialogState createState() => _AddUserDialogState(
      onRefresh: onRefresh, userDataDeployed: userDataDeployed);
}

class _AddUserDialogState extends State<AddUserDialog> {
  final VoidCallback onRefresh;
  final List<AuthModel> userDataDeployed;
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userKeyController = TextEditingController();

  String _entityType = 'Admin';
  bool _obscureText = true;

  _AddUserDialogState(
      {required this.onRefresh, required this.userDataDeployed});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Container(
              width: DynamicSizeService.calculateWidthSize(context, 0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User Registration",
                      style: TextStyle(
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                              context, 0.025),
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(200, 0, 0, 0))),
                  SizedBox(height: 16),
                  _buildTextField(_userIdController, 'User ID'),
                  SizedBox(height: 12),
                  _buildTextField(_firstNameController, 'First Name'),
                  SizedBox(height: 12),
                  _buildTextField(_lastNameController, 'Last Name'),
                  SizedBox(height: 12),
                  _buildDropdown(),
                  SizedBox(height: 12),
                  _buildTextField(_emailController, 'User Email',
                      inputType: TextInputType.emailAddress),
                  SizedBox(height: 12),
                  _buildUserKeyField(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel',
                            style: GoogleFonts.montserrat(color: Colors.black)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => userRegistration(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 36, 66, 117),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('Submit',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: GoogleFonts.montserrat(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Color.fromARGB(179, 3, 3, 3)),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Color.fromARGB(255, 26, 26, 26), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label cannot be empty';
        } else {
          if (label == 'User ID') {
            for (var user in userDataDeployed) {
              if (user.userID == value.trim()) {
                return 'This ID is already being used by existing entity';
              }
            }
          } else if (label == 'User Email') {
            for (var user in userDataDeployed) {
              if (user.userMail == value.trim()) {
                return 'This email is already being used by existing entity';
              }
            }
          }
        }
        return null;
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _entityType,
      items: ['Admin', 'Teacher', 'Student']
          .map((type) => DropdownMenuItem<String>(
                value: type,
                child: Text(type,
                    style: GoogleFonts.montserrat(color: Colors.black)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _entityType = value!;
        });
      },
      decoration: InputDecoration(
        labelText: 'Entity Type',
        labelStyle: GoogleFonts.montserrat(color: Color.fromARGB(179, 3, 3, 3)),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Color.fromARGB(255, 26, 26, 26), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildUserKeyField() {
    return TextFormField(
      controller: _userKeyController,
      obscureText: _obscureText,
      style: GoogleFonts.montserrat(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'User Key',
        labelStyle: GoogleFonts.montserrat(color: Color.fromARGB(179, 3, 3, 3)),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Color.fromARGB(255, 26, 26, 26), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.black),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'User Key cannot be empty';
        }
        return null;
      },
    );
  }

  Future<void> userRegistration() async {
    if (_formKey.currentState!.validate()) {
      CollectionReference entityCollection =
          FirebaseFirestore.instance.collection("entity");

      String userId = _userIdController.text.trim();
      String firstName = _firstNameController.text.trim();
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
          entityCollection.add({
            'userID': userId,
            'userName00': firstName,
            'userName01': lastName,
            'entity': _getEntityValue(_entityType),
            'userMail': email,
            'userKey': userKey,
            'userPhotoID': 'default',
            'lastSession': Timestamp.fromDate(DateTime.now())
          });
        } catch (e) {
        } finally {
          await tempApp.delete();
        }

        Navigator.of(context).pop();
        onRefresh();
        useToastify.showLoadingToast(context, "Successful Registration",
            "$userId is now official registered!");
      } catch (e) {
        Navigator.of(context).pop();
        onRefresh();
        useToastify.showErrorToast(context, "Error",
            "Fail to register the entity. Please contact the developer for investigation.");
      }
    }
  }

  double _getEntityValue(String entityType) {
    switch (entityType) {
      case 'Admin':
        return 0;
      case 'Teacher':
        return 1;
      default:
        return 2;
    }
  }
}
