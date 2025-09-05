import 'expense_model.dart';

class OnboardingData {
  final double monthlyIncome;
  final List<Expense> expenses;
  final double savingsGoal;

  OnboardingData({
    required this.monthlyIncome,
    required this.expenses,
    required this.savingsGoal,
  });

  OnboardingData copyWith({
    double? monthlyIncome,
    List<Expense>? expenses,
    double? savingsGoal,
  }) {
    return OnboardingData(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      expenses: expenses ?? this.expenses,
      savingsGoal: savingsGoal ?? this.savingsGoal,
    );
  }
}