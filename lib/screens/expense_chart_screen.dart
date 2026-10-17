import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:budget_book/models/expense_model.dart';
import 'package:budget_book/services/expense_service.dart';

class ExpenseChartScreen extends StatefulWidget {
  final TextEditingController userNameController;

  const ExpenseChartScreen({super.key, required this.userNameController});

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  final NumberFormat _yenFormat = NumberFormat('#,###');
  final DateFormat _monthFormat = DateFormat('yyyy-MM');

  List<ExpenseItem> _allExpenses = [];
  bool _isLoading = true;
  String? _loadError;

  // 月別表示では選択した1か月、期間表示では開始日〜終了日で絞り込む。
  String _viewMode = 'month';
  String _selectedMonth = '';
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  String _detailMode = 'item'; // item / category
  String _chartMode = 'category'; // category / monthly
  String _sortField = 'amount'; // amount / date
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      // API側でユーザー名を指定して取得するため、ExpenseItemにuserは不要。
      final items = await ExpenseService.fetchExpenses(
        widget.userNameController.text,
      );
      final months =
          items.map((item) => _monthFormat.format(item.date)).toSet().toList()
            ..sort((a, b) => b.compareTo(a));

      if (!mounted) return;
      setState(() {
        _allExpenses = items;
        if (months.isNotEmpty) {
          if (_selectedMonth.isEmpty || !months.contains(_selectedMonth)) {
            final nowMonth = _monthFormat.format(DateTime.now());
            _selectedMonth = months.contains(nowMonth)
                ? nowMonth
                : months.first;
          }
          _setMonthRange(_selectedMonth, updateState: false);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'データを取得できませんでした。通信状況を確認して再試行してください。';
      });
    }
  }

  List<String> get _availableMonths =>
      _allExpenses
          .map((item) => _monthFormat.format(item.date))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

  void _setMonthRange(String month, {bool updateState = true}) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNumber = int.parse(parts[1]);
    final firstDay = DateTime(year, monthNumber, 1);
    final lastDay = DateTime(year, monthNumber + 1, 0);
    void update() {
      _selectedMonth = month;
      _startDate = firstDay;
      _endDate = lastDay;
      _viewMode = 'month';
    }

    if (updateState) {
      setState(update);
    } else {
      update();
    }
  }

  void _setPreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _viewMode = 'range';
      if (preset == 'thisMonth') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = today;
      } else if (preset == 'lastMonth') {
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
      } else {
        // 過去3ヶ月＝今月を含む3暦月の初日から今日まで。
        _startDate = DateTime(now.year, now.month - 2, 1);
        _endDate = today;
      }
    });
  }

  Future<void> _chooseDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      // 初期表示期間がデータの最古日より前でも、範囲選択ダイアログが開けるようにする。
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ja'),
      helpText: '表示する期間を選択',
      saveText: 'この期間で表示',
      cancelText: 'キャンセル',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: theme.colorScheme.surface,
            ),
            datePickerTheme: DatePickerThemeData(
              headerHeadlineStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              rangeSelectionBackgroundColor: Colors.blue.shade100,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _viewMode = 'range';
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
    }
  }

  bool get _isSingleMonth =>
      _startDate.year == _endDate.year && _startDate.month == _endDate.month;

  void _selectSortField(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        // 列を切り替えた最初の表示は、金額なら高い順・日付なら新しい順。
        _sortAscending = false;
      }
    });
  }

  List<ExpenseItem> get _filteredExpenses {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endExclusive = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day + 1,
    );
    return _allExpenses.where((item) {
      return !item.date.isBefore(start) && item.date.isBefore(endExclusive);
    }).toList();
  }

  Map<String, int> _categoryTotals(List<ExpenseItem> expenses) {
    final totals = <String, int>{};
    for (final expense in expenses) {
      final category = expense.category.trim().isEmpty
          ? '未分類'
          : expense.category;
      totals[category] = (totals[category] ?? 0) + expense.price;
    }
    return totals;
  }

  List<_ExpenseSummary> _buildSummaries(List<ExpenseItem> expenses) {
    final grouped = <String, _ExpenseSummary>{};
    for (final expense in expenses) {
      final isCategoryMode = _detailMode == 'category';
      final rawKey = isCategoryMode ? expense.category : expense.item;
      final key = rawKey.trim().isEmpty
          ? (isCategoryMode ? '未分類' : '品目未設定')
          : rawKey;
      final current = grouped[key];
      if (current == null) {
        grouped[key] = _ExpenseSummary(
          name: key,
          total: expense.price,
          latestDate: expense.date,
          count: 1,
        );
      } else {
        grouped[key] = _ExpenseSummary(
          name: key,
          total: current.total + expense.price,
          latestDate: expense.date.isAfter(current.latestDate)
              ? expense.date
              : current.latestDate,
          count: current.count + 1,
        );
      }
    }

    final summaries = grouped.values.toList();
    summaries.sort((a, b) {
      final comparison = _sortField == 'amount'
          ? a.total.compareTo(b.total)
          : a.latestDate.compareTo(b.latestDate);
      return _sortAscending ? comparison : -comparison;
    });
    return summaries;
  }

  Map<String, int> _monthlyTotals(List<ExpenseItem> expenses) {
    final totals = <String, int>{};
    for (final expense in expenses) {
      final month = _monthFormat.format(expense.date);
      totals[month] = (totals[month] ?? 0) + expense.price;
    }
    return totals;
  }

  Color _chartColor(int index) =>
      Colors.primaries[index % Colors.primaries.length];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredItems = _filteredExpenses;
    final visibleChartMode = _isSingleMonth ? 'category' : _chartMode;
    final total = filteredItems.fold<int>(0, (sum, item) => sum + item.price);
    final categoryTotals = _categoryTotals(filteredItems);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final summaries = _buildSummaries(filteredItems);
    // 月別表示では全期間の推移を見せ、期間指定時はその期間内の月別合計を表示する。
    final monthlyTotals = _monthlyTotals(
      _viewMode == 'month' ? _allExpenses : filteredItems,
    );
    final sortedMonths = monthlyTotals.keys.toList()..sort();
    final rangeLabel =
        '${DateFormat('yyyy/MM/dd').format(_startDate)} 〜 ${DateFormat('yyyy/MM/dd').format(_endDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '表示期間',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: _loadData,
              tooltip: 'データを更新',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('月別表示'),
              selected: _viewMode == 'month',
              onSelected: (_) {
                if (_selectedMonth.isNotEmpty) _setMonthRange(_selectedMonth);
              },
            ),
            ChoiceChip(
              label: const Text('今月'),
              selected: _viewMode == 'range' && _isPresetRange('thisMonth'),
              onSelected: (_) => _setPreset('thisMonth'),
            ),
            ChoiceChip(
              label: const Text('先月'),
              selected: _viewMode == 'range' && _isPresetRange('lastMonth'),
              onSelected: (_) => _setPreset('lastMonth'),
            ),
            ChoiceChip(
              label: const Text('過去3ヶ月'),
              selected: _viewMode == 'range' && _isPresetRange('last3Months'),
              onSelected: (_) => _setPreset('last3Months'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_viewMode == 'month' && _availableMonths.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: _availableMonths.contains(_selectedMonth)
                ? _selectedMonth
                : null,
            decoration: const InputDecoration(
              labelText: '対象月',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _availableMonths
                .map(
                  (month) => DropdownMenuItem(value: month, child: Text(month)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _setMonthRange(value);
            },
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _chooseDateRange,
          icon: const Icon(Icons.date_range),
          label: Text(
            _viewMode == 'month' ? '開始日・終了日を指定' : rangeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    _viewMode == 'month' ? '$_selectedMonth の総支出' : '選択期間の総支出',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${_yenFormat.format(total)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  Text(
                    '${filteredItems.length} 件',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'グラフ表示',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _chartMode = 'category'),
                icon: const Icon(Icons.pie_chart_outline),
                label: const Text('カテゴリ別割合'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: visibleChartMode == 'category'
                      ? Colors.blue.shade50
                      : null,
                  foregroundColor: visibleChartMode == 'category'
                      ? Colors.blue.shade800
                      : null,
                  side: BorderSide(
                    color: visibleChartMode == 'category'
                        ? Colors.blue.shade400
                        : Colors.grey.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSingleMonth
                    ? null
                    : () => setState(() => _chartMode = 'monthly'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('月ごとの支出額'),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      visibleChartMode == 'monthly' && !_isSingleMonth
                      ? Colors.blue.shade50
                      : null,
                  foregroundColor: _isSingleMonth
                      ? Colors.grey.shade400
                      : (visibleChartMode == 'monthly'
                            ? Colors.blue.shade800
                            : null),
                  disabledForegroundColor: Colors.grey.shade400,
                  side: BorderSide(
                    color: _isSingleMonth
                        ? Colors.grey.shade300
                        : (visibleChartMode == 'monthly'
                              ? Colors.blue.shade400
                              : Colors.grey.shade400),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isSingleMonth)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '月ごとの支出額は、複数の月を含む期間を選ぶと表示できます。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        const SizedBox(height: 12),
        if (visibleChartMode == 'category') ...[
          const Text(
            'カテゴリ別割合',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (sortedCategories.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('この期間のデータはありません')),
            )
          else ...[
            SizedBox(
              height: 210,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 42,
                  sections: sortedCategories.asMap().entries.map((
                    indexedEntry,
                  ) {
                    final index = indexedEntry.key;
                    final entry = indexedEntry.value;
                    return PieChartSectionData(
                      color: _chartColor(index),
                      value: entry.value.toDouble(),
                      title: '',
                      radius: 62,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...sortedCategories.asMap().entries.map((indexedEntry) {
              final index = indexedEntry.key;
              final entry = indexedEntry.value;
              final percent = total == 0 ? 0.0 : entry.value / total * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _chartColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key, overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      '¥${_yenFormat.format(entry.value)}  (${percent.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ] else ...[
          const Text(
            '月ごとの支出額',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (sortedMonths.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('表示できるデータはありません')),
            )
          else
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _niceMaxY(monthlyTotals.values),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Text(
                          _compactYen(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedMonths.length)
                            return const SizedBox.shrink();
                          if (sortedMonths.length > 7 && index.isOdd)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedMonths[index].substring(2),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: sortedMonths.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (monthlyTotals[entry.value] ?? 0).toDouble(),
                          color: Colors.blue.shade400,
                          width: sortedMonths.length > 10 ? 10 : 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
        const SizedBox(height: 28),
        const Text(
          '詳細データ一覧',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'item',
              label: Text('品目別'),
              icon: Icon(Icons.receipt_long),
            ),
            ButtonSegment(
              value: 'category',
              label: Text('カテゴリ別'),
              icon: Icon(Icons.category_outlined),
            ),
          ],
          selected: {_detailMode},
          onSelectionChanged: (selection) =>
              setState(() => _detailMode = selection.first),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              selected: _sortField == 'amount',
              onSelected: (_) => _selectSortField('amount'),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('金額順'),
                  const SizedBox(width: 4),
                  Icon(
                    _sortField == 'amount'
                        ? (_sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)
                        : Icons.swap_vert,
                    size: 18,
                  ),
                ],
              ),
            ),
            ChoiceChip(
              selected: _sortField == 'date',
              onSelected: (_) => _selectSortField('date'),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('日付順'),
                  const SizedBox(width: 4),
                  Icon(
                    _sortField == 'date'
                        ? (_sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)
                        : Icons.swap_vert,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (summaries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('該当するデータはありません')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
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
                    child: Icon(
                      _detailMode == 'category'
                          ? Icons.category_outlined
                          : Icons.receipt_long,
                      color: Colors.blue.shade900,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    summary.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '最新 ${DateFormat('yyyy/MM/dd').format(summary.latestDate)} ・ ${summary.count}件',
                  ),
                  trailing: Text(
                    '¥${_yenFormat.format(summary.total)}',
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

  bool _isPresetRange(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    late DateTime start;
    late DateTime end;
    if (preset == 'thisMonth') {
      start = DateTime(now.year, now.month, 1);
      end = today;
    } else if (preset == 'lastMonth') {
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(now.year, now.month, 0);
    } else {
      start = DateTime(now.year, now.month - 2, 1);
      end = today;
    }
    return _startDate == start && _endDate == end;
  }

  double _niceMaxY(Iterable<int> values) {
    final maxValue = values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    if (maxValue <= 0) return 100;
    return (maxValue * 1.2).ceilToDouble();
  }

  String _compactYen(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toInt().toString();
  }
}

class _ExpenseSummary {
  final String name;
  final int total;
  final DateTime latestDate;
  final int count;

  const _ExpenseSummary({
    required this.name,
    required this.total,
    required this.latestDate,
    required this.count,
  });
}
