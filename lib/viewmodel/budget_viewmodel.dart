import 'package:flutter/material.dart';

import 'package:endterm/model/budget_model.dart';

class BudgetViewModel extends ChangeNotifier {
  Budget? _budget;

  Budget? get budget => _budget;

  void setBudget(Budget budget) {
    _budget = budget;
    notifyListeners();
  }

  void updateMonthlyIncome(double newIncome) {
    if (_budget != null) {
      _budget = Budget(
        id: _budget!.id,
        userId: _budget!.userId,
        monthlyIncome: newIncome,
        savingsGoal: _budget!.savingsGoal,
        totalExpenses: _budget!.totalExpenses,
        createdAt: _budget!.createdAt,
      );
      notifyListeners();
    }
  }

  void updateSavingsGoal(double newGoal) {
    if (_budget != null) {
      _budget = Budget(
        id: _budget!.id,
        userId: _budget!.userId,
        monthlyIncome: _budget!.monthlyIncome,
        savingsGoal: newGoal,
        totalExpenses: _budget!.totalExpenses,
        createdAt: _budget!.createdAt,
      );
      notifyListeners();
    }
  }

  void createBudget(int userId, double monthlyIncome, double savingsGoal) {
    final newBudget = Budget(
      userId: userId,
      monthlyIncome: monthlyIncome,
      savingsGoal: savingsGoal,
      createdAt: DateTime.now(),
    );
    _budget = newBudget;
    notifyListeners();
  }

  void fetchBudget(int userId) {


    final simulatedBudget = Budget(
      id: 1,
      userId: userId,
      monthlyIncome: 3000.0,
      savingsGoal: 500.0,
      totalExpenses: 0.0,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    );

    _budget = simulatedBudget;
    notifyListeners();
  }

  void deleteBudget() {
    _budget = null;
    notifyListeners();
  }

  void addExpense(double expenseAmount){
    if(_budget != null){
      double newTotal = _budget!.totalExpenses + expenseAmount;
      _budget = Budget(
        id: _budget!.id,
        userId: _budget!.userId,
        monthlyIncome: _budget!.monthlyIncome,
        savingsGoal: _budget!.savingsGoal,
        totalExpenses: newTotal,
        createdAt: _budget!.createdAt,
      );
      notifyListeners();
    }
  }
}