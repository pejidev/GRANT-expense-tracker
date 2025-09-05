class Budget {
  final int? id;
  final int userId;
  final double monthlyIncome;
  final double savingsGoal;
  final double currentSavings;
  double totalExpenses;
  final DateTime? createdAt;

  Budget({
    this.id,
    required this.userId,
    required this.monthlyIncome,
    required this.savingsGoal,
    this.currentSavings = 0.0,
    this.totalExpenses = 0.0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'monthly_income': monthlyIncome,
      'savings_goal': savingsGoal,
      'currentSavings': currentSavings,
      'total_expenses': totalExpenses,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      monthlyIncome: (map['monthly_income'] as num).toDouble(),
      savingsGoal: map['savingsGoal']?.toDouble() ?? 0.0,
      totalExpenses: map['totalExpenses']?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
