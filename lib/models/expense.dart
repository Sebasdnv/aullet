class Expense {
  final String? id;
  final String userId;
  final dynamic categoryId;
  final double amount;
  final DateTime date;
  final String? description;

  Expense({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.description,
  });

  // Questo metodo serve per Supabase
  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'category_id': categoryId,
    'amount': amount,
    'date': date.toIso8601String(),
    'description': description,
  };

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'].toString(),
      userId: map['user_id'] as String,
      categoryId: map['category_id'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      description: map['description'] as String?,
    );
  }
}