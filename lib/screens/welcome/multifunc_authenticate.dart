import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

class WidgetAuthenticate extends StatefulWidget {
  const WidgetAuthenticate({Key? key}) : super(key: key);

  @override
  _WidgetAuthenticateState createState() => _WidgetAuthenticateState();
}

class _WidgetAuthenticateState extends State<WidgetAuthenticate> {
  final _InputUserController = TextEditingController();
  final _InputKeyController = TextEditingController();
  late AuthModel user;
  List<AuthModel> userDataFetch = [];

  // Authenticate user and fetch data
  Future<void> userAuthenticate(
      BuildContext context, String inputUser, String inputKey) async {
    try {
      // Sign in with FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: inputUser, password: inputKey);

      // Get ID Token and store it in a cookie
      await _fetchUserData(userCredential.user!.email);

      useToastify.showLoadingToast(context, "Welcome ${user.firstName}!",
          "You're successfully logged in");
      web.window.open(
          './?session=true&page=${Provider.of<GlobalState>(context, listen: false).entityType}',
          '_self');
    } catch (e) {
      // Authentication failed
      useToastify.showErrorToast(
          context, "Authentication Failed", "Invalid email or password.");
      print(e); //for debugging purpose
    }
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String? userEmail) async {
    try {
      // Query Firestore based on the email
      CollectionReference entityCollection =
          FirebaseFirestore.instance.collection("entity");

      // Fetch user data based on user email
      QuerySnapshot querySnapshot =
          await entityCollection.where("userMail", isEqualTo: userEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Process and store the data
        var doc = querySnapshot.docs.first;
        user = AuthModel(
          userID: doc.get("userID"),
          firstName: doc.get("userName00"),
          lastName: doc.get("userName01"),
          entityType: doc.get("entity"),
          userMail: doc.get("userMail"),
          userKey: doc.get("userKey"),
          userPhotoID: doc.get("userPhotoID"),
          lastSession: doc.get("lastSession"),
        );
        Provider.of<GlobalState>(context, listen: false).updateUserData(
            user.userID,
            user.firstName,
            user.lastName,
            user.entityType,
            user.userMail,
            user.userKey,
            user.userPhotoID,
            user.lastSession);
      } else {}
    } catch (e) {
      print(e.toString());
      useToastify.showErrorToast(
          context, "Error", "Failed to fetch user data.");
      print(e); //for debugging purpose
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 350,
          height: 270,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF2570ff),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: Offset(2, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Institutional Email:",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              SizedBox(height: 5),
              TextField(
                controller: _InputUserController,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                ),
                onSubmitted: (value) {
                  userAuthenticate(context, _InputUserController.text,
                      _InputKeyController.text);
                },
              ),
              SizedBox(height: 7),
              Text("Password:",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              SizedBox(height: 5),
              TextField(
                controller: _InputKeyController,
                obscureText: true,
                style: TextStyle(fontSize: 12, fontFamily: 'Monospace'),
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                ),
                onSubmitted: (value) {
                  userAuthenticate(context, _InputUserController.text,
                      _InputKeyController.text);
                },
              ),
              SizedBox(height: 10),
              InkWell(
                  onTap: () async {},
                  child: Text('forgot password?',
                      style: TextStyle(color: Colors.white, fontSize: 12))),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  userAuthenticate(context, _InputUserController.text,
                      _InputKeyController.text);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFd8d85d),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 50)),
                child: Text('SIGN IN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
