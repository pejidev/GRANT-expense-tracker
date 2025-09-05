class TransactionModel {
  final int? id;
  final String type;
  final double amount;
  final DateTime date;
  final String? description;
  final String? categoryId;
  final String? fromAccountId;
  final String? toAccountId;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.categoryId,
    this.fromAccountId,
    this.toAccountId,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      amount: map['amount'].toDouble(),
      date: DateTime.parse(map['date']),
      description: map['description'],
      categoryId: map['category_id'],
      fromAccountId: map['from_account_id'],
      toAccountId: map['to_account_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'category_id': categoryId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
    };
  }
}
