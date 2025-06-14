import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationModel {
  final String userID;
  final String firstName;
  final String lastName;
  final String middleName;
  final double entityType;
  final String userMail;
  final String userKey;
  final Timestamp lastSession;

  AuthenticationModel(
      {required this.userID,
      required this.firstName,
      required this.lastName,
      required this.middleName,
      required this.entityType,
      required this.userMail,
      required this.userKey,
      required this.lastSession});
}
