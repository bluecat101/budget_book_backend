import 'dart:convert';
import 'package:budget_book/models/expense_model.dart';
import 'package:budget_book/utils/api_error_messages.dart';
import 'package:http/http.dart' as http; // httpパッケージが必要になります
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExpenseService {
  static final String _url = dotenv.env['API_URL'] ?? '';

  // 支出データの取得
  static Future<List<ExpenseItem>> fetchExpenses(String userName) async {
    final uri = Uri.parse(
      _url,
    ).replace(queryParameters: {'userName': userName});
    final response = await http.get(uri);
    // HTTP通信自体のエラー
    if (response.statusCode != 200) {
      throw Exception('通信エラーが発生しました。');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    print('Response body: $body'); // デバッグ用にレスポンスの内容を出力
    if (body['statusCode'] == 200) {
      final List<dynamic> data = body['data'];
      return data.map((json) => ExpenseItem.fromJson(json)).toList();
    } else {
      final String errorCode = body['code'];
      final message = ApiErrorMessages.getMessage(errorCode);
      throw Exception(message);
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
