import 'dart:convert';
import 'package:budget_book/models/expense_model.dart';
import 'package:http/http.dart' as http; // httpパッケージが必要になります
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExpenseService {
  static final String _url = dotenv.env['API_URL'] ?? '';

  // 支出データの取得
  static Future<List<ExpenseItem>> fetchExpenses(String userName) async {
    try {
      final uri = Uri.parse(
        _url,
      ).replace(queryParameters: {'userName': userName});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> decodedBody = jsonDecode(response.body);
        return decodedBody.map((json) => ExpenseItem.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load expenses");
      }
    } catch (e) {
      print("Error fetching data: $e");
      return [];
    }
  }

  // 支出データの登録
  static Future<void> postExpense(Map<String, dynamic> payload) async {
    // リダイレクトを自分で追跡できる Client を使う
    final client = http.Client();
    try {
      var requestUrl = Uri.parse(_url);
      var response = await client.post(
        requestUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      // もし 302 リダイレクトが返ってきた場合、Locationヘッダーに次のURLが入っている
      if (response.statusCode == 302 || response.statusCode == 301) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          // リダイレクト先へ GET（または再度POST）でアクセスし直して結果を取得する
          // ※GASの場合、リダイレクト先は通常 doGet や静的コンテンツになることが多いので GET になることがあります
          final redirectResponse = await client.get(Uri.parse(redirectUrl));
          response = redirectResponse; // レスポンスを差し替える
        }
      }

      if (response.statusCode != 200) {
        throw Exception('サーバーとの通信に失敗しました。（コード: ${response.statusCode}）');
      }

      final responseData = jsonDecode(response.body);
      if (responseData['status'] != 'success') {
        throw Exception(responseData['message'] ?? '登録に失敗しました。');
      }
    } finally {
      client.close();
    }
  }
}
