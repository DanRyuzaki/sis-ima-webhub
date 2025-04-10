import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class EditUserDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<AuthModel> userDataDeployed;
  final AuthModel user;
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
  final List<AuthModel> userDataDeployed;
  final AuthModel user;

  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userKeyController = TextEditingController();
  final _userIdReTypeController = TextEditingController();

  String _entityType = 'Admin';
  bool _obscureText = true;
  late bool _delUser;

  _EditUserDialogState(
      {required this.onRefresh,
      required this.userDataDeployed,
      required this.user});

  @override
  void initState() {
    super.initState();
    _userIdController.text = user.userID;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.userMail;
    _userKeyController.text = user.userKey;
    _entityType = user.entityType == 0
        ? 'Admin'
        : (user.entityType == 1 ? 'Teacher' : 'Student');
    _delUser = false;
  }

  @override
  Widget build(BuildContext context) {
    return _delUser
        ? AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
                        Text("Delete User",
                            style: TextStyle(
                                fontSize:
                                    DynamicSizeService.calculateAspectRatioSize(
                                        context, 0.025),
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(200, 0, 0, 0))),
                        SizedBox(height: 16),
                        _buildTextField(
                            _userIdReTypeController, 'Re-type the User ID'),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.black)),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _handleDelete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 117, 36, 36),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Delete',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
                        Text("Modify User",
                            style: TextStyle(
                                fontSize:
                                    DynamicSizeService.calculateAspectRatioSize(
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
                        Row(children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel',
                                style: GoogleFonts.montserrat(
                                    color: Colors.black)),
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => setState(() {
                                  _delUser = true;
                                }),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 117, 36, 36),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text('Delete',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white)),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => userModification(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 36, 66, 117),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text('Submit',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white)),
                                ),
                              ),
                            ],
                          )
                        ]),
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

  Future<void> userModification() async {
    if (_formKey.currentState!.validate()) {
      CollectionReference entityCollection =
          FirebaseFirestore.instance.collection("entity");
      QuerySnapshot querySnapshot = await entityCollection
          .where("userMail", isEqualTo: user.userMail)
          .get();

      String userId = _userIdController.text.trim();
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String email = _emailController.text.trim();
      String userKey = _userKeyController.text.trim();

      try {
        print('Form Modification Submitted');
        print('User ID: $userId');
        print('First Name: $firstName');
        print('Last Name: $lastName');
        print('Email: $email');
        print('User Key: $userKey');
        print('Entity Type: $_entityType');
        entityCollection.doc(querySnapshot.docs.first.id).update({
          'userID': userId,
          'userName00': firstName,
          'userName01': lastName,
          'entity': _getEntityValue(_entityType),
          'userMail': email,
          'userKey': userKey,
          'userPhotoID': 'default',
          'lastSession': Timestamp.fromDate(DateTime.now())
        });

        Navigator.of(context).pop();
        onRefresh();
        useToastify.showLoadingToast(
            context, "Successful Modification", "$userId's account altered!");
      } catch (e) {
        Navigator.of(context).pop();
        onRefresh();
        useToastify.showErrorToast(context, "Error",
            "Failed to modify the entity. Please contact the developer.");
        print(e);
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

        if (querySnapshot.docs.isNotEmpty) {
          await entityCollection.doc(querySnapshot.docs.first.id).delete();

          Navigator.of(context).pop();
          onRefresh();
          useToastify.showLoadingToast(context, "Deleted Successfully",
              "$originalId has been removed from the database.");
        } else {
          Navigator.of(context).pop();
          useToastify.showErrorToast(context, "User Not Found",
              "No entity found with user ID: $originalId");
        }
      } catch (e) {
        Navigator.of(context).pop();
        useToastify.showErrorToast(context, "Error",
            "Failed to delete the user. Please contact the developer.");
        print("Delete Error: $e");
      }
    }
  }
}
