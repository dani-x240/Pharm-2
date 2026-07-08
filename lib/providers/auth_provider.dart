import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

class AuthProvider extends ChangeNotifier {
  bool _isSetupCompleted = false;
  bool _isAuthenticated = false;

  String _shopName = '';
  String _ownerName = '';
  String _shopAddress = '';
  String _phoneNumber = '';

  String _question1 = '';
  String _question2 = '';

  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;

  bool get isSetupCompleted => _isSetupCompleted;
  bool get isAuthenticated => _isAuthenticated;
  String get shopName => _shopName;
  String get ownerName => _ownerName;
  String get shopAddress => _shopAddress;
  String get phoneNumber => _phoneNumber;
  String get question1 => _question1;
  String get question2 => _question2;

  int get failedAttempts => _failedAttempts;
  bool get isLockedOut {
    if (_lockoutEndTime == null) return false;
    final now = DateTime.now();
    if (now.isAfter(_lockoutEndTime!)) {
      _lockoutEndTime = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  int get lockoutSecondsRemaining {
    if (_lockoutEndTime == null) return 0;
    final diff = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  AuthProvider() {
    init();
  }

  Future<void> init() async {
    await loadSettings();
  }

  Future<void> loadSettings() async {
    final settingsList = await DbHelper.instance.queryAll('settings');
    final Map<String, String> settings = {};
    for (var row in settingsList) {
      settings[row['key'] as String] = row['value'] as String? ?? '';
    }

    _isSetupCompleted = settings['is_setup_completed'] == 'true';
    _shopName = settings['shop_name'] ?? '';
    _ownerName = settings['owner_name'] ?? '';
    _shopAddress = settings['shop_address'] ?? '';
    _phoneNumber = settings['phone_number'] ?? '';
    _question1 = settings['security_q1'] ?? 'What is your favourite colour?';
    _question2 = settings['security_q2'] ?? 'What was the name of your first school?';

    notifyListeners();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  String _hashAnswer(String answer) {
    final bytes = utf8.encode(answer.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  Future<bool> setupApp({
    required String shopName,
    required String ownerName,
    required String shopAddress,
    required String phoneNumber,
    required String pin,
    required String q1,
    required String a1,
    required String q2,
    required String a2,
  }) async {
    try {
      final pinHash = _hashPin(pin);
      final a1Hash = _hashAnswer(a1);
      final a2Hash = _hashAnswer(a2);

      await DbHelper.instance.insert('settings', {'key': 'shop_name', 'value': shopName});
      await DbHelper.instance.insert('settings', {'key': 'owner_name', 'value': ownerName});
      await DbHelper.instance.insert('settings', {'key': 'shop_address', 'value': shopAddress});
      await DbHelper.instance.insert('settings', {'key': 'phone_number', 'value': phoneNumber});
      await DbHelper.instance.insert('settings', {'key': 'pin_hash', 'value': pinHash});
      await DbHelper.instance.insert('settings', {'key': 'security_q1', 'value': q1});
      await DbHelper.instance.insert('settings', {'key': 'security_a1_hash', 'value': a1Hash});
      await DbHelper.instance.insert('settings', {'key': 'security_q2', 'value': q2});
      await DbHelper.instance.insert('settings', {'key': 'security_a2_hash', 'value': a2Hash});
      await DbHelper.instance.insert('settings', {'key': 'is_setup_completed', 'value': 'true'});

      await loadSettings();
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Setup Error: $e');
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (isLockedOut) return false;

    final pinList = await DbHelper.instance.query('settings', where: 'key = ?', whereArgs: ['pin_hash']);
    if (pinList.isEmpty) return false;

    final savedPinHash = pinList.first['value'] as String;
    final inputHash = _hashPin(pin);

    if (savedPinHash == inputHash) {
      _isAuthenticated = true;
      _failedAttempts = 0;
      _lockoutEndTime = null;
      notifyListeners();
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutEndTime = DateTime.now().add(const Duration(seconds: 30));
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifySecurityQuestions(String a1, String a2) async {
    final a1List = await DbHelper.instance.query('settings', where: 'key = ?', whereArgs: ['security_a1_hash']);
    final a2List = await DbHelper.instance.query('settings', where: 'key = ?', whereArgs: ['security_a2_hash']);

    if (a1List.isEmpty || a2List.isEmpty) return false;

    final savedA1Hash = a1List.first['value'] as String;
    final savedA2Hash = a2List.first['value'] as String;

    final inputA1Hash = _hashAnswer(a1);
    final inputA2Hash = _hashAnswer(a2);

    return savedA1Hash == inputA1Hash && savedA2Hash == inputA2Hash;
  }

  Future<bool> resetPin(String newPin) async {
    try {
      final pinHash = _hashPin(newPin);
      await DbHelper.instance.insert('settings', {'key': 'pin_hash', 'value': pinHash});
      _failedAttempts = 0;
      _lockoutEndTime = null;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Reset PIN Error: $e');
      return false;
    }
  }

  Future<bool> updateShopDetails({
    required String shopName,
    required String ownerName,
    required String shopAddress,
    required String phoneNumber,
  }) async {
    try {
      await DbHelper.instance.insert('settings', {'key': 'shop_name', 'value': shopName});
      await DbHelper.instance.insert('settings', {'key': 'owner_name', 'value': ownerName});
      await DbHelper.instance.insert('settings', {'key': 'shop_address', 'value': shopAddress});
      await DbHelper.instance.insert('settings', {'key': 'phone_number', 'value': phoneNumber});

      await loadSettings();
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
