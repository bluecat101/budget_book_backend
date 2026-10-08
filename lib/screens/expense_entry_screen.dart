import 'package:budget_book/services/api_service.dart';
import 'package:budget_book/utils/thousands_separator_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpenseFormSnippet extends StatefulWidget {
  const ExpenseFormSnippet({super.key});

  @override
  _ExpenseFormSnippetState createState() => _ExpenseFormSnippetState();
}

class _ExpenseFormSnippetState extends State<ExpenseFormSnippet> {
  // ① フォーム全体を管理するキーを定義
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();

  // デフォルトの定番アイテム
  final List<String> _defaultItems = ['食費', 'カフェ', '交通費', '日用品', 'エンタメ'];

  // 常に表示する5つのボタン用リスト
  late List<String> _displayItems;

  @override
  void initState() {
    super.initState();
    _displayItems = List.from(_defaultItems);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  // ユーザーが新しい項目を入力して登録したときに呼ぶメソッド
  void _addNewItemToHistory(String newItem) {
    if (newItem.trim().isEmpty) return;

    setState(() {
      _displayItems.remove(newItem);
      _displayItems.insert(0, newItem);
      if (_displayItems.length > 5) {
        _displayItems.removeLast();
      }
    });
  }

  // --- 登録ボタンが押されたときに実行されるメイン処理 ---
  Future<void> _handleSubmit() async {
    // 1. バリデーションチェック
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final itemText = _itemController.text;
    final cleanPriceText = _priceController.text.replaceAll(',', '');
    final price = int.tryParse(cleanPriceText) ?? 0;

    try {
      final payload = {
        "userName": "ユーザー名", // 実際のユーザー名に合わせる
        "date": DateTime.now().toIso8601String().split('T')[0], // "YYYY-MM-DD"
        "price": price,
        "item": itemText,
      };

      // ApiServiceで送信する場合
      await ApiService.postExpense(payload);

      // 2. ローカルの履歴リストを更新
      _addNewItemToHistory(itemText);

      // 3. フォームをクリア
      _itemController.clear();
      _priceController.clear();

      // 4. 成功のスナックバー表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("データを登録しました！"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("エラー: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ② Formウィジェットで全体をラップして _formKey を渡す
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 金額入力フィールド ---
          const Text(
            '金額',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: '金額',
              suffixText: '円',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '金額を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // --- 用途入力フィールド ---
          const Text(
            '用途・カテゴリ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _itemController,
            decoration: const InputDecoration(
              labelText: '用途',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '用途を入力または選択してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // --- ローカルで管理されている最大5つのボタン群 ---
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _displayItems.map((item) {
              return ActionChip(
                label: Text(item),
                backgroundColor: Colors.grey.shade100,
                onPressed: () {
                  _itemController.text = item;
                  _itemController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _itemController.text.length),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // --- 登録ボタン ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              child: const Text('登録する'),
            ),
          ),
        ],
      ),
    );
  }
}
