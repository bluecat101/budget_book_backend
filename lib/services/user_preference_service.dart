import 'package:shared_preferences/shared_preferences.dart';

class UserPreferenceService {
  static const String _keyLastUser = 'last_entered_user';

  // 直近のユーザー名保存
  static Future<void> saveLastUser(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUser, name);
  }

  // 直近のユーザー名取得（デフォルト値は空文字など）
  static Future<String> getLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUser) ?? '';
  }
}
