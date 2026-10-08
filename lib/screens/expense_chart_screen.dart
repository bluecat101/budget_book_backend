import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:budget_book/models/expense_model.dart'; // ご自身のモデルに合わせて調整
import 'package:budget_book/services/expense_service.dart'; // または api_service.dart

class ExpenseChartScreen extends StatefulWidget {
  const ExpenseChartScreen({super.key});

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  List<ExpenseItem> _allExpenses = [];
  bool _isLoading = true;
  String _selectedMonth = ''; // 例: "2026-10"
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // サーバーやローカルから全データを取得するサービス
      final items = await ExpenseService.fetchExpenses();

      // 存在する月を抽出して降順ソート
      final months =
          items
              .map((item) => DateFormat('yyyy-MM').format(item.date))
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

      setState(() {
        _allExpenses = items;
        _availableMonths = months;
        if (_availableMonths.isNotEmpty && _selectedMonth.isEmpty) {
          _selectedMonth = _availableMonths.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // 必要に応じてエラー処理
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_availableMonths.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text("データがありません", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // 選択された月のデータのみをフィルタリング
    final filteredItems = _allExpenses.where((item) {
      return DateFormat('yyyy-MM').format(item.date) == _selectedMonth;
    }).toList();

    // カテゴリごとの集計
    final Map<String, int> categoryTotals = {};
    int monthlyTotal = 0;
    for (var item in filteredItems) {
      categoryTotals[item.item] = (categoryTotals[item.item] ?? 0) + item.price;
      monthlyTotal += item.price;
    }

    // RefreshIndicatorは親がSingleChildScrollViewの場合に競合することがあるため、通常のColumn/ListViewで構成
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 月選択ドロップダウン & 更新ボタン ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "表示月:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedMonth.isNotEmpty ? _selectedMonth : null,
                  items: _availableMonths.map((month) {
                    return DropdownMenuItem(value: month, child: Text(month));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadData,
                  tooltip: 'データを更新',
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 30),

        // --- 月ごとの合計金額カード ---
        Card(
          elevation: 0,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    "$_selectedMonth の総支出",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "¥${NumberFormat('#,###').format(monthlyTotal)}",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- 月のカテゴリ別グラフ（円グラフ） ---
        const Text(
          "カテゴリ別割合",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        categoryTotals.isEmpty
            ? const SizedBox(
                height: 150,
                child: Center(child: Text("この月のデータはありません")),
              )
            : SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: categoryTotals.entries.map((entry) {
                      final index = categoryTotals.keys.toList().indexOf(
                        entry.key,
                      );
                      final color =
                          Colors.primaries[index % Colors.primaries.length];
                      final percentage = monthlyTotal > 0
                          ? (entry.value / monthlyTotal * 100).toStringAsFixed(
                              1,
                            )
                          : '0.0';

                      return PieChartSectionData(
                        color: color,
                        value: entry.value.toDouble(),
                        title: '${entry.key}\n$percentage%',
                        radius: 65,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
        const SizedBox(height: 24),

        // --- 月ごとのデータ一覧（表形式） ---
        const Text(
          "詳細データ一覧",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    item.user.isNotEmpty ? item.user[0] : '?',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
                title: Text(
                  item.item,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(DateFormat('yyyy/MM/dd').format(item.date)),
                trailing: Text(
                  "¥${NumberFormat('#,###').format(item.price)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
