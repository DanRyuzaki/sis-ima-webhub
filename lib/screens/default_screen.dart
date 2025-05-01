import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/configModel.dart';
import 'package:sis_project/screens/admin/admin_screen.dart';
import 'package:sis_project/screens/student/student_screen.dart';
import 'package:sis_project/screens/faculty/faculty_screen.dart';
import 'package:sis_project/screens/welcome/welcome_screen.dart';
import 'package:sis_project/services/global_state.dart';

class DefaultWebScreen extends StatefulWidget {
  const DefaultWebScreen({super.key});

  @override
  State<DefaultWebScreen> createState() => _DefaultWebScreenState();
}

class _DefaultWebScreenState extends State<DefaultWebScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAndStoreConfigs(context);
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      await _fetchUserData(currentUser.email);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchAndStoreConfigs(BuildContext context) async {
    try {
      CollectionReference configCollection =
          FirebaseFirestore.instance.collection("config");
      QuerySnapshot configSnapshot = await configCollection.get();

      List<ConfigModel> configList = configSnapshot.docs.map((doc) {
        return ConfigModel(
          id: doc.get("id"),
          category: doc.get("category"),
          name: doc.get("name"),
          value: doc.get("value"),
        );
      }).toList();

      Provider.of<GlobalState>(context, listen: false)
          .updateGlobalConfigs(configList);
    } catch (e) {
      print("Error fetching configs: $e");
    }
  }

  Future<void> _fetchUserData(String? userEmail) async {
    try {
      CollectionReference entityCollection =
          FirebaseFirestore.instance.collection("entity");
      QuerySnapshot querySnapshot =
          await entityCollection.where("userMail", isEqualTo: userEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        AuthModel user = AuthModel(
            userID: doc.get("userID"),
            firstName: doc.get("userName00"),
            lastName: doc.get("userName01"),
            entityType: doc.get("entity"),
            userMail: doc.get("userMail"),
            userKey: doc.get("userKey"),
            userPhotoID: doc.get("userPhotoID"),
            lastSession: doc.get("lastSession"));

        await entityCollection
            .doc(querySnapshot.docs.first.id)
            .update({'lastSession': Timestamp.fromDate(DateTime.now())});

        Provider.of<GlobalState>(context, listen: false).updateUserData(
            user.userID,
            user.firstName,
            user.lastName,
            user.entityType,
            user.userMail,
            user.userKey,
            user.userPhotoID,
            user.lastSession);
      } else {
        useToastify.showErrorToast(
            context, "Error", "Error fetching user's data field");
      }
    } catch (e) {
      useToastify.showErrorToast(context, "Error", "Failed to fetch user data");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;
    final queryParams = Uri.base.queryParameters;
    final sessionActive = queryParams['session'] == "true";
    final page = queryParams['page'];
    final entityType = Provider.of<GlobalState>(context).entityType;

    if (user == null || !sessionActive) {
      return WelcomeScreen();
    }

    switch (page) {
      case '0':
        return entityType == 0 ? AdminScreen() : WelcomeScreen();
      case '1':
        return entityType == 1 ? TeacherScreen() : WelcomeScreen();
      case '2':
        return entityType == 2 ? StudentScreen() : WelcomeScreen();
      default:
        return WelcomeScreen();
    }
  }
}
