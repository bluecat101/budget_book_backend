import 'package:budget_book/models/expense_model.dart';
import 'package:budget_book/widgets/expense_summary_list.dart';

Map<String, int> calculateCategoryTotals(List<ExpenseItem> expenses) {
  final totals = <String, int>{};

  for (final expense in expenses) {
    final category = expense.category.trim().isEmpty ? '未分類' : expense.category;

    totals[category] = (totals[category] ?? 0) + expense.price;
  }

  return totals;
}

Map<String, int> calculateMonthlyTotals(List<ExpenseItem> expenses) {
  final totals = <String, int>{};

  for (final expense in expenses) {
    final month =
        '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';

    totals[month] = (totals[month] ?? 0) + expense.price;
  }

  return totals;
}

List<ExpenseSummary> buildExpenseSummaries({
  required List<ExpenseItem> expenses,
  required bool isCategoryMode,
  required bool sortByAmount,
  required bool sortAscending,
}) {
  final grouped = <String, ExpenseSummary>{};

  for (final expense in expenses) {
    final rawKey = isCategoryMode ? expense.category : expense.item;

    final key = rawKey.trim().isEmpty
        ? (isCategoryMode ? '未分類' : '品目未設定')
        : rawKey;

    final current = grouped[key];

    if (current == null) {
      grouped[key] = ExpenseSummary(
        name: key,
        total: expense.price,
        latestDate: expense.date,
        count: 1,
      );
    } else {
      grouped[key] = ExpenseSummary(
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
    final comparison = sortByAmount
        ? a.total.compareTo(b.total)
        : a.latestDate.compareTo(b.latestDate);

    return sortAscending ? comparison : -comparison;
  });

  return summaries;
}
