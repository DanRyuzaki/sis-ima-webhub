import 'package:cloud_firestore/cloud_firestore.dart';

class AuthModel {
  final String userID;
  final String firstName;
  final String lastName;
  final double entityType;
  final String userMail;
  final String userKey;
  final String userPhotoID;
  final Timestamp lastSession;

  AuthModel(
      {required this.userID,
      required this.firstName,
      required this.lastName,
      required this.entityType,
      required this.userMail,
      required this.userKey,
      required this.userPhotoID,
      required this.lastSession});
}
