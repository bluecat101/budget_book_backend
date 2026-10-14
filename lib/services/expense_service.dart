import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:budget_book/models/expense_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExpenseService {
  static final String _url = dotenv.env['API_URL'] ?? '';

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
}
