import 'package:shared_preferences/shared_preferences.dart';

class UserPreferenceService {
  static const String _keyLastUser = 'last_entered_user';
  // ★ 追加: 用途履歴用のキー
  static const String _keyRecentItems = 'recent_expense_items';

  // 直近のユーザー名保存
  static Future<void> saveLastUser(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUser, name);
  }

  // 直近のユーザー名取得
  static Future<String> getLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUser) ?? '';
  }

  // === ★ここから用途履歴用の追加メソッド===

  // 直近の用途リストを保存
  static Future<void> saveRecentItems(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyRecentItems, items);
  }

  // 直近の用途リストを取得（保存されていなければ空リストを返す）
  static Future<List<String>> getRecentItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentItems) ?? [];
  }
}
