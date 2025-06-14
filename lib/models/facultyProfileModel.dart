import 'package:cloud_firestore/cloud_firestore.dart';

class facultyProfileModel {
  String facultyId;

  String facultyName00;
  String facultyName01;
  String facultyName02;
  Timestamp dateOfBirth;
  String contactNumber;
  List<dynamic> advisoryClassId;
  List<dynamic> subjectsList;
  String facultyEmail;
  String facultyKey;
  Timestamp lastSession;
  List<String> department;

  facultyProfileModel(
      {required this.facultyId,
      required this.facultyName00,
      required this.facultyName01,
      required this.facultyName02,
      required this.dateOfBirth,
      required this.contactNumber,
      required this.advisoryClassId,
      required this.subjectsList,
      required this.facultyEmail,
      required this.facultyKey,
      required this.lastSession,
      required this.department});
}
