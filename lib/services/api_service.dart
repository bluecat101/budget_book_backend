import 'dart:convert';
import 'package:http/http.dart' as http; // httpパッケージが必要になります
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String _url = dotenv.env['API_URL'] ?? '';
  static Future<void> postExpense(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    // ステータスコードが200番台以外、または返却されたJSONがerrorの場合
    if (response.statusCode != 200) {
      throw Exception('サーバーとの通信に失敗しました。（コード: ${response.statusCode}）');
    }

    final responseData = jsonDecode(response.body);
    if (responseData['status'] != 'success') {
      throw Exception(responseData['message'] ?? '登録に失敗しました。');
    }
  }
}
