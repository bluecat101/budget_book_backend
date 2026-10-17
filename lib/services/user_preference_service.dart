import 'package:shared_preferences/shared_preferences.dart';

class UserPreferenceService {
  static const String _keyLastUser = 'last_entered_user';
  static const String _keyRecentItems = 'recent_expense_items';
  static const String _keyIntroductionSeen = 'introduction_seen';
  // ==========================
  // 直近のユーザー名を保存するためのメソッド
  // ==========================
  static Future<void> saveLastUser(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUser, name);
  }

  // 直近のユーザー名取得
  static Future<String> getLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUser) ?? '';
  }

  // ==========================
  // 直近の用途リストの保存と取得
  // ==========================
  static Future<void> saveRecentItems(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyRecentItems, items);
  }

  // 直近の用途リストを取得（保存されていなければ空リストを返す）
  static Future<List<String>> getRecentItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentItems) ?? [];
  }

  // ==========================
  // 初回起動時のチュートリアル表示済みフラグの保存と取得
  // ==========================

  // Introduction を表示したことがあるか確認
  static Future<bool> hasSeenIntroduction() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIntroductionSeen) ?? false;
  }

  // Introduction を表示済みにする
  static Future<void> setIntroductionSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroductionSeen, true);
  }
}
