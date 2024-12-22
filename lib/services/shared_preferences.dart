import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  // Singleton Pattern
  static final SharedPrefsService _instance = SharedPrefsService._internal();

  factory SharedPrefsService() {
    return _instance;
  }

  SharedPrefsService._internal();

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', json.encode(userData));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  // Clear user data
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
  }
}
