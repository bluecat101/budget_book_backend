import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.sortedCategories,
    required this.total,
    required this.yenFormat,
  });

  final List<MapEntry<String, int>> sortedCategories;
  final int total;
  final NumberFormat yenFormat;

  Color _chartColor(int index) =>
      Colors.primaries[index % Colors.primaries.length];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                sections: sortedCategories.asMap().entries.map((indexedEntry) {
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
                    '¥${yenFormat.format(entry.value)}  (${percent.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
