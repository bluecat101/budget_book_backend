import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 入力が空の場合はそのまま返す
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 数字以外の文字をすべて削除（プレーンな数値にする）
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // 数値に変換してカンマ区切りフォーマットを適用
    final int parsedNumber = int.parse(cleanText);
    final formatter = NumberFormat('#,###');
    final String formattedText = formatter.format(parsedNumber);

    // カーソル位置が変なところに飛ばないように調整
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
