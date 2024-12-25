import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perpustakaan/models/user_model.dart';

class UserPreferences {
  static const String _keyUser = 'user';
  static const String _keyIsLoggedIn = 'isLoggedIn';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toMap()));
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr != null) {
      final userMap = jsonDecode(userStr) as Map<String, dynamic>;
      return UserModel.fromMap(userMap);
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
