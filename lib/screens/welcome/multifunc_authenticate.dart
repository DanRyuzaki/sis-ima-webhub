import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/trafficLogModel.dart';
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
  late TrafficLogModel traffic;
  // Authenticate user and fetch data
  Future<void> userAuthenticate(
      BuildContext context, String inputUser, String inputKey) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: inputUser, password: inputKey);

      await _fetchUserData(userCredential.user!.email);
      useToastify.showLoadingToast(context, "Welcome ${user.firstName}!",
          "You're successfully logged in");
      await _sisTrafficLog();

      web.window.open(
          './?session=true&page=${Provider.of<GlobalState>(context, listen: false).entityType}',
          '_self');
    } catch (e) {
      useToastify.showErrorToast(
          context, "Authentication Failed", "Invalid email or password.");
      print(e); //for debugging purpose
    }
  }

  Future<void> _fetchUserData(String? userEmail) async {
    try {
      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final querySnapshot =
          await entityCollection.where("userMail", isEqualTo: userEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
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
      }
    } catch (e) {
      print(e.toString());
      useToastify.showErrorToast(
          context, "Error", "Failed to fetch user data.");
      print(e); //for debugging purpose
    }
  }

  Future<void> _sisTrafficLog() async {
    try {
      String formattedDate = DateFormat('MMMM d, y').format(DateTime.now());
      CollectionReference trafficCollection =
          FirebaseFirestore.instance.collection("trafficlog");

      QuerySnapshot querySnapshot = await trafficCollection
          .where("timestamp", isEqualTo: formattedDate)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await trafficCollection.add({
          'timestamp': formattedDate,
          'social-traffic': 0,
          'sis-traffic': 1,
        });
        print('Traffic log created for $formattedDate');
      } else {
        var docSnapshot = querySnapshot.docs.first;
        var docData = docSnapshot.data() as Map<String, dynamic>;
        int currentSisTraffic = docData['sis-traffic'] ?? 0;
        int currentSocialTraffic = docData['social-traffic'] ?? 0;

        await docSnapshot.reference.set({
          'timestamp': formattedDate,
          'social-traffic': currentSocialTraffic,
          'sis-traffic': currentSisTraffic + 1,
        }, SetOptions(merge: true));

        print('Traffic log updated for $formattedDate: '
            '${currentSocialTraffic} social, ${currentSisTraffic + 1} sis');
      }
    } catch (e) {
      print('Error updating traffic log: $e');
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
                color: Colors.black.withAlpha(51), // 0.2 opacity approx.
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
              TextFormField(
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
                onFieldSubmitted: (value) {
                  userAuthenticate(context, _InputUserController.text,
                      _InputKeyController.text);
                },
              ),
              SizedBox(height: 7),
              Text("Password:",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              SizedBox(height: 5),
              TextFormField(
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
                onFieldSubmitted: (value) {
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

  @override
  void dispose() {
    _InputUserController.dispose();
    _InputKeyController.dispose();
    super.dispose();
  }
}
