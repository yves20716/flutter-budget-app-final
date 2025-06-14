class Transaction {
  final String id;
  final String name;
  final String note;
  final double amount;
  final String category; // e.g., 飲食、娛樂
  final String method;   // e.g., 現金、信用卡
  final bool isIncome;   // 收入或支出
  final DateTime date;

  Transaction({
    required this.id,
    required this.name,
    required this.note,
    required this.amount,
    required this.category,
    required this.method,
    required this.isIncome,
    required this.date,
  });
}
