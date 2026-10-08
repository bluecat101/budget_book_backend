import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:budget_book/models/expense_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExpenseService {
  static final String _url = dotenv.env['API_URL'] ?? '';

  static Future<List<ExpenseItem>> fetchExpenses() async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        print("Raw response: ${response.body}"); // デバッグ用に追加
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        print("Decoded response: $decodedBody"); // デバッグ用に追加
        final List<dynamic> data = decodedBody['data'] ?? [];
        return data.map((json) => ExpenseItem.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load expenses");
      }
    } catch (e) {
      print("Error fetching data: $e");
      return [];
    }
  }
}
