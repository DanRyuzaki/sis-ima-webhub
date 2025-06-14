import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sis_project/models/configModel.dart';

class GlobalState with ChangeNotifier {
  // Visibility and active section controls
  bool _isVisible = false;
  String _activeSection = 'HOME';

  bool get isVisible => _isVisible;
  String get activeSection => _activeSection;

  // Individual configuration fields (for quick access)
  ConfigModel _configAddr = ConfigModel(
          id: '0',
          category: '1=main',
          name: 'address',
          value: 'Please wait...'),
      _configCont = ConfigModel(
          id: '1',
          category: '1=main',
          name: 'contact',
          value: 'Please wait...'),
      _configDept1 = ConfigModel(
          id: '2',
          category: '2=department',
          name: 'pre-school',
          value: 'Please wait...'),
      _configDept2 = ConfigModel(
          id: '3',
          category: '2=department',
          name: 'elementary',
          value: 'Please wait...'),
      _configDept3 = ConfigModel(
          id: '4',
          category: '2=department',
          name: 'junior high school',
          value: 'Please wait...'),
      _configDept4 = ConfigModel(
          id: '5',
          category: '2=department',
          name: 'senior high school',
          value: 'Please wait...'),
      _vmgo1 = ConfigModel(
          id: '6',
          category: '3=vmgo',
          name: 'mission',
          value: 'Please wait...'),
      _vmgo2 = ConfigModel(
          id: '7', category: '3=vmgo', name: 'vision', value: 'Please wait...'),
      _vmgo3 = ConfigModel(
          id: '8',
          category: '3=vmgo',
          name: 'objectives',
          value: 'Please wait...');

  ConfigModel get configAddr => _configAddr;
  ConfigModel get configCont => _configCont;
  ConfigModel get configDept1 => _configDept1;
  ConfigModel get configDept2 => _configDept2;
  ConfigModel get configDept3 => _configDept3;
  ConfigModel get configDept4 => _configDept4;
  ConfigModel get configVmgo1 => _vmgo1;
  ConfigModel get configVmgo2 => _vmgo2;
  ConfigModel get configVmgo3 => _vmgo3;

  // New: Global list for all config documents
  List<ConfigModel> _globalConfigs = [];
  List<ConfigModel> get globalConfigs => _globalConfigs;

  /// Update individual config based on id.
  void updateGlobalConfig(ConfigModel config, num id) {
    switch (id) {
      case 0:
        _configAddr = config;
        break;
      case 1:
        _configCont = config;
        break;
      case 2:
        _configDept1 = config;
        break;
      case 3:
        _configDept2 = config;
        break;
      case 4:
        _configDept3 = config;
        break;
      case 5:
        _configDept4 = config;
        break;
      case 6:
        _vmgo1 = config;
        break;
      case 7:
        _vmgo2 = config;
        break;
      case 8:
        _vmgo3 = config;
        break;
      default:
        _configAddr = config;
        break;
    }
    notifyListeners();
  }

  /// Update the entire global config list from Firestore.
  void updateGlobalConfigs(List<ConfigModel> newConfigs) {
    _globalConfigs = newConfigs;
    for (ConfigModel config in newConfigs) {
      int id = int.tryParse(config.id) ?? -1;
      switch (id) {
        case 0:
          _configAddr = config;
          break;
        case 1:
          _configCont = config;
          break;
        case 2:
          _configDept1 = config;
          break;
        case 3:
          _configDept2 = config;
          break;
        case 4:
          _configDept3 = config;
          break;
        case 5:
          _configDept4 = config;
          break;
        case 6:
          _vmgo1 = config;
          break;
        case 7:
          _vmgo2 = config;
          break;
        case 8:
          _vmgo3 = config;
          break;
        default:
          break;
      }
    }
    notifyListeners();
  }

  void toggleIsActive() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  void toggleActiveSection(String newSection) {
    _activeSection = newSection;
    notifyListeners();
  }

  // User data fields.
  String _userID = '';
  String _userName00 = '';
  String _userName01 = '';
  String _userName02 = '';
  double _entityType = 0;
  String _userMail = '';
  String _userKey = '';
  Timestamp _lastSession = Timestamp.fromDate(DateTime.now());

  String get userID => _userID;
  String get userName00 => _userName00;
  String get userName01 => _userName01;
  String get userName02 => _userName02;
  double get entityType => _entityType;
  String get userMail => _userMail;
  String get userKey => _userKey;
  Timestamp get lastSession => _lastSession;

  void updateUserData(
      String userID,
      String userName00,
      String userName01,
      String userName02,
      double entityType,
      String userMail,
      String userKey,
      Timestamp lastSession) {
    _userID = userID;
    _userName00 = userName00;
    _userName01 = userName01;
    _userName02 = userName02;
    _entityType = entityType;
    _userMail = userMail;
    _userKey = userKey;
    _lastSession = lastSession;
    notifyListeners();
  }
}
