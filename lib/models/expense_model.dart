class ExpenseItem {
  final DateTime date;
  final int price;
  final String item;
  final String category;

  ExpenseItem({
    required this.date,
    required this.price,
    required this.item,
    required this.category,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      date: DateTime.parse(json['date']),
      price: json['price'] is int
          ? json['price']
          : int.tryParse(json['price'].toString()) ?? 0,
      item: json['item'] ?? '',
      category: json['category'] ?? '',
    );
  }
}
