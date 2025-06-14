import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  late AuthenticationModel user;
  late TrafficLogModel traffic;

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
      useToastify.showErrorToast(context, "Authentication Failed",
          "Failed connection, invalid email or password.");
      print(e);
    }
  }

  Future<void> _fetchUserData(String? userEmail) async {
    try {
      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final querySnapshot =
          await entityCollection.where("userMail", isEqualTo: userEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        user = AuthenticationModel(
          userID: doc.get("userID"),
          firstName: doc.get("userName00"),
          lastName: doc.get("userName01"),
          middleName: doc.get("userName02"),
          entityType: doc.get("entity"),
          userMail: doc.get("userMail"),
          userKey: doc.get("userKey"),
          lastSession: doc.get("lastSession"),
        );
        Provider.of<GlobalState>(context, listen: false).updateUserData(
            user.userID,
            user.firstName,
            user.lastName,
            user.middleName,
            user.entityType,
            user.userMail,
            user.userKey,
            user.lastSession);
      }
    } catch (e) {
      print(e.toString());
      useToastify.showErrorToast(
          context, "Error", "Failed to fetch user data.");
      print(e);
    }
  }

  Future<void> _forgotPassword(String userEmail) async {
    final EMAILJS_SERVICE = dotenv.env['EMAILJS_SERVICE'] ?? '';
    final EMAILJS_TEMPLATE = dotenv.env['EMAILJS_TEMPLATE'] ?? '';
    final EMAILJS_PUBLICKEY = dotenv.env['EMAILJS_PUBLICKEY'] ?? '';
    final EMAILJS_PRIVATEKEY = dotenv.env['EMAILJS_PRIVATEKEY'] ?? '';
    if (userEmail.isEmpty) {
      useToastify.showErrorToast(context, 'Password Reminder',
          'Please enter your email address first.');
      return;
    }

    try {
      final entityCollection =
          await FirebaseFirestore.instance.collection("entity");
      final querySnapshot =
          await entityCollection.where("userMail", isEqualTo: userEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        try {
          await emailjs.send(
            EMAILJS_SERVICE,
            EMAILJS_TEMPLATE,
            {
              'email': userEmail,
              'password': querySnapshot.docs.first.get('userKey'),
            },
            emailjs.Options(
                publicKey: EMAILJS_PUBLICKEY, privateKey: EMAILJS_PRIVATEKEY),
          );

          useToastify.showLoadingToast(context, 'Password Reminder',
              'Your current password has been sent to your email.');
        } catch (emailError) {
          print('EmailJS Error: $emailError');
          useToastify.showErrorToast(context, 'Email Service Error',
              'Failed to send email. Please try again later or contact support.');
        }
      } else {
        useToastify.showErrorToast(context, 'Email Not Found',
            'No account found with this email address.');
      }
    } catch (e) {
      print('Database Error: $e');
      useToastify.showErrorToast(context, 'Password Reminder',
          'System error occurred. Please try again later.');
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
                color: Colors.black.withAlpha(51),
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
                  onTap: () => _forgotPassword(_InputUserController.text),
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
