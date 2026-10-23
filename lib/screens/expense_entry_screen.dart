import 'package:budget_book/services/expense_service.dart';
import 'package:budget_book/services/user_preference_service.dart';
import 'package:budget_book/utils/thousands_separator_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpenseEntryScreen extends StatefulWidget {
  final TextEditingController userNameController;

  const ExpenseEntryScreen({super.key, required this.userNameController});

  @override
  _ExpenseEntryScreenState createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  // フォーム全体を管理するキーを定義
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();

  // 選択された日付の保持（デフォルトは今日）
  DateTime _selectedDate = DateTime.now();

  // デフォルトの定番アイテム
  final List<String> _defaultItems = ['食費', 'カフェ', '交通費', '日用品', 'エンタメ'];

  // 常に表示する5つのボタン用リスト
  late List<String> _displayItems;

  // フォーカス管理用の変数
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _itemFocusNode = FocusNode();

  bool _isSubmitting = false;

  final int MaxRecentItems = 5; // 最近使った項目の最大数

  @override
  void initState() {
    super.initState();
    _displayItems = List.from(_defaultItems);
    _loadRecentItems();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _itemController.dispose();
    _priceFocusNode.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  // 最近使った項目を読み込む
  void _loadRecentItems() async {
    final savedItems = await UserPreferenceService.getRecentItems();

    if (!mounted) return;

    _displayItems.removeWhere((item) => savedItems.contains(item));
    _displayItems.insertAll(0, savedItems);

    // 個数制限
    while (_displayItems.length > MaxRecentItems) {
      _displayItems.removeLast();
    }

    setState(() {});
  }

  // ユーザーが新しい項目を入力して登録したときに呼ぶメソッド
  void _addNewItemToHistory(String newItem) {
    if (newItem.trim().isEmpty) return;

    setState(() {
      _displayItems.remove(newItem);
      _displayItems.insert(0, newItem);

      // 個数制限
      while (_displayItems.length > MaxRecentItems) {
        _displayItems.removeLast();
      }
    });

    UserPreferenceService.saveRecentItems(_displayItems);
  }

  // カレンダーを表示して日付を変更するメソッド
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- 登録ボタンが押されたときに実行されるメイン処理 ---
  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final submittedItemText = _itemController.text;
    final submittedPriceText = _priceController.text;
    final price = int.tryParse(submittedPriceText.replaceAll(',', '')) ?? 0;
    final userName = widget.userNameController.text.trim();

    if (userName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名前を入力してください')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));

    try {
      final payload = {
        'userName': userName,
        // 選択された日付を YYYY-MM-DD 形式にして送信
        'date': _selectedDate.toIso8601String().split('T')[0],
        'price': price,
        'item': submittedItemText,
      };

      await ExpenseService.postExpense(payload);

      if (!mounted) return;

      _addNewItemToHistory(submittedItemText);

      if (_itemController.text == submittedItemText) {
        _itemController.clear();
      }

      if (_priceController.text == submittedPriceText) {
        _priceController.clear();
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('データを登録しました！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: ${e.toString().replaceFirst('Exception: ', '')}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付選択フィールド
          _buildDateField(),
          const SizedBox(height: 20),
          // 金額フィールド
          _buildPriceField(),
          const SizedBox(height: 20),
          // 用途フィールド
          _buildItemField(),
          const SizedBox(height: 8),
          // 最近使った用途表示
          _buildRecentItemChips(),
          const SizedBox(height: 20),
          // 登録ボタン
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // 日付選択フィールドの構築
  Widget _buildDateField() {
    // 見やすく「YYYY年M月D日」形式にフォーマットする文字列
    final formattedDateText =
        "${_selectedDate.year}年 ${_selectedDate.month}月 ${_selectedDate.day}日";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '日付',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '日付',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              formattedDateText,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  // 金額入力フィールドの構築
  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          focusNode: _priceFocusNode,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_itemFocusNode);
          },
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
      ],
    );
  }

  // 用途入力フィールドの構築
  Widget _buildItemField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          focusNode: _itemFocusNode,
          textInputAction: TextInputAction.done,
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
      ],
    );
  }

  // 最近使った用途の構築
  Widget _buildRecentItemChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _displayItems.map((item) {
        return ActionChip(
          label: Text(item),
          backgroundColor: Colors.grey.shade100,
          onPressed: () {
            _itemController.text = item;
            _itemController.selection = TextSelection.fromPosition(
              TextPosition(offset: _itemController.text.length),
            );

            FocusScope.of(context).unfocus();
          },
        );
      }).toList(),
    );
  }

  // 登録ボタンの構築
  Widget _buildSubmitButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: Text(_isSubmitting ? '登録中…' : '登録する'),
          ),
        ),
        if (_isSubmitting) ...[
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 12),
              Text(
                '登録中…',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
