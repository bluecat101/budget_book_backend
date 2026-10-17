import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseSummary {
  final String name;
  final int total;
  final DateTime latestDate;
  final int count;

  const ExpenseSummary({
    required this.name,
    required this.total,
    required this.latestDate,
    required this.count,
  });
}

class ExpenseSummaryList extends StatelessWidget {
  final List<ExpenseSummary> summaries;
  final String detailMode;
  final NumberFormat yenFormat;

  const ExpenseSummaryList({
    super.key,
    required this.summaries,
    required this.detailMode,
    required this.yenFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '詳細データ一覧',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      detailMode == 'category'
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
                    '¥${yenFormat.format(summary.total)}',
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
