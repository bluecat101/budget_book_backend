import 'package:budget_book/utils/expense_chart_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budget_book/models/expense_model.dart';
import 'package:budget_book/services/expense_service.dart';
import 'package:budget_book/widgets/charts/category_pie_chart.dart';
import 'package:budget_book/widgets/charts/monthly_bar_chart.dart';
import 'package:budget_book/widgets/expense_summary_list.dart';

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
    final total = filteredItems.fold<int>(0, (sum, item) => sum + item.price);

    final categoryTotals = calculateCategoryTotals(filteredItems);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final summaries = buildExpenseSummaries(
      expenses: filteredItems,
      isCategoryMode: _detailMode == 'category',
      sortByAmount: _sortField == 'amount',
      sortAscending: _sortAscending,
    );

    // 月別表示では全期間、期間指定では選択期間の月別合計を表示する。
    final monthlyTotals = calculateMonthlyTotals(
      _viewMode == 'month' ? _allExpenses : filteredItems,
    );
    final sortedMonths = monthlyTotals.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 期間
        _buildPeriodSelector(),
        // 総支出の表示
        _buildExpenseTotalCard(total, filteredItems.length),
        // グラフ表示
        _buildChartSection(
          total: total,
          sortedCategories: sortedCategories,
          monthlyTotals: monthlyTotals,
          sortedMonths: sortedMonths,
        ),
        // 詳細データ一覧表示
        _buildSummarySection(summaries),
      ],
    );
  }

  // 2つの日付が同じ日かどうかを判定する。
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 期間指定のプリセット選択かどうかを判定する。
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
    return _isSameDay(_startDate, start) && _isSameDay(_endDate, end);
  }

  // 期間セレクタの構築
  Widget _buildPeriodSelector() {
    final rangeLabel =
        '${DateFormat('yyyy/MM/dd').format(_startDate)}'
        ' 〜 '
        '${DateFormat('yyyy/MM/dd').format(_endDate)}';

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
      ],
    );
  }

  // 総支出カードの構築
  Widget _buildExpenseTotalCard(int total, int count) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Text('$count 件', style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  // グラフ表示セクションの構築
  Widget _buildChartSection({
    required int total,
    required List<MapEntry<String, int>> sortedCategories,
    required Map<String, int> monthlyTotals,
    required List<String> sortedMonths,
  }) {
    final visibleChartMode = _isSingleMonth ? 'category' : _chartMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                onPressed: () {
                  setState(() => _chartMode = 'category');
                },
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
                    : () {
                        setState(() => _chartMode = 'monthly');
                      },
                icon: const Icon(Icons.bar_chart),
                label: const Text('月ごとの支出額'),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      visibleChartMode == 'monthly' && !_isSingleMonth
                      ? Colors.blue.shade50
                      : null,
                  foregroundColor: _isSingleMonth
                      ? Colors.grey.shade400
                      : visibleChartMode == 'monthly'
                      ? Colors.blue.shade800
                      : null,
                  disabledForegroundColor: Colors.grey.shade400,
                  side: BorderSide(
                    color: _isSingleMonth
                        ? Colors.grey.shade300
                        : visibleChartMode == 'monthly'
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
        if (visibleChartMode == 'category')
          CategoryPieChart(
            sortedCategories: sortedCategories,
            total: total,
            yenFormat: _yenFormat,
          )
        else
          MonthlyBarChart(
            monthlyTotals: monthlyTotals,
            sortedMonths: sortedMonths,
          ),
        const SizedBox(height: 28),
      ],
    );
  }

  // 詳細データ一覧セクションの構築
  Widget _buildSummarySection(List<ExpenseSummary> summaries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          onSelectionChanged: (selection) {
            setState(() => _detailMode = selection.first);
          },
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
        ExpenseSummaryList(
          summaries: summaries,
          detailMode: _detailMode,
          yenFormat: _yenFormat,
        ),
      ],
    );
  }
}
