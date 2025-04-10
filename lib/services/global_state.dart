import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GlobalState with ChangeNotifier {
  bool _isVisible = false;
  String _activeSection = 'HOME';

  bool get isVisible => _isVisible;
  String get activeSection => _activeSection;

  void toggleIsActive() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  void toggleActiveSection(String newSection) {
    _activeSection = newSection;
    notifyListeners();
  }

  String _userID = '';
  String _userName00 = '';
  String _userName01 = '';
  double _entityType = 0;
  String _userMail = '';
  String _userKey = '';
  String _userPhotoID = '';
  Timestamp _lastSession = Timestamp.fromDate(DateTime.now());
  String get userID => _userID;
  String get userName00 => _userName00;
  String get userName01 => _userName01;
  double get entityType => _entityType;
  String get userMail => _userMail;
  String get userKey => _userKey;
  String get userPhotoID => _userPhotoID;
  Timestamp get lastSession => _lastSession;

  void updateUserData(
      String userID,
      String userName00,
      String userName01,
      double entityType,
      String userMail,
      String userKey,
      String userPhotoID,
      Timestamp lastSession) {
    _userID = userID;
    _userName00 = userName00;
    _userName01 = userName01;
    _entityType = entityType;
    _userMail = userMail;
    _userKey = userKey;
    _userPhotoID = userPhotoID;
    _lastSession = lastSession;
    notifyListeners();
  }
}
