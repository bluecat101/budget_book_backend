class ExpenseItem {
  final DateTime date;
  final String user;
  final int price;
  final String item;

  ExpenseItem({
    required this.date,
    required this.user,
    required this.price,
    required this.item,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      date: DateTime.parse(json['date']),
      user: json['user'] ?? '',
      price: json['price'] is int
          ? json['price']
          : int.tryParse(json['price'].toString()) ?? 0,
      item: json['item'] ?? '',
    );
  }
}
