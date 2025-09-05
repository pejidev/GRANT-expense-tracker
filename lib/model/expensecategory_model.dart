import 'package:endterm/model/expense_model.dart';

class ExpenseCategory {
  final int id;
  final String name;
  List<Expense> expenses;

  ExpenseCategory({
    required this.id,
    required this.name,
    List<Expense>? expenses,
  }) : expenses = expenses ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}