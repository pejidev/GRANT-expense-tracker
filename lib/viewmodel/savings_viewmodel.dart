import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavingsViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  Future<int?> getCurrentUserId() async {
    debugPrint('--- getCurrentUserId: Starting ---');
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        debugPrint('getCurrentUserId: No Supabase auth user found.');
        return null;
      }
      final authId = authUser.id;
      debugPrint('getCurrentUserId: Found Supabase auth user ID: $authId');

      try {
        final response = await _supabase
            .from('user')
            .select('id')
            .eq('auth_id', authId)
            .maybeSingle();

        if (response == null) {
          debugPrint('getCurrentUserId: No user found in database.');
          return null;
        }

        return response['id'] as int?;
      } catch (e) {
        debugPrint('getCurrentUserId: Error fetching user ID: $e');
        return null;
      }
    } catch (e) {
      debugPrint('getCurrentUserId: Error getting auth user: $e');
      return null;
    }
  }

  Future<double> getCurrentSavings() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _supabase
          .from('budgets')
          .select('currentSavings')
          .eq('user_id', userId)
          .single();

      return (response['currentSavings'] as num).toDouble();
    } catch (e) {
      debugPrint('Error getting current savings: $e');
      throw Exception('Failed to get current savings');
    }
  }

  // Changed from private to public method
  Future<void> updateCurrentSavings() async {
    try {
      debugPrint('updateCurrentSavings: Starting update process');
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('updateCurrentSavings: No user ID found');
        return;
      }
      debugPrint('updateCurrentSavings: User ID found: $userId');

      final monthlyIncome = await getMonthlyIncome();
      debugPrint('updateCurrentSavings: Monthly income: $monthlyIncome');

      final totalExpenses = await getTotalExpenses();
      debugPrint('updateCurrentSavings: Total expenses: $totalExpenses');

      final newSavings = monthlyIncome - totalExpenses;
      debugPrint('updateCurrentSavings: Calculated new savings: $newSavings');

      debugPrint('updateCurrentSavings: Attempting to update database...');
      await _supabase
          .from('budgets')
          .update({'currentSavings': newSavings > 0 ? newSavings : 0})
          .eq('user_id', userId);
      debugPrint('updateCurrentSavings: Database update completed');

      notifyListeners();
      debugPrint('updateCurrentSavings: Notified listeners');
    } catch (e) {
      debugPrint('updateCurrentSavings: Error automatically updating savings: $e');
    }
  }

  Future<void> addToSavings({required double amount}) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final current = await getCurrentSavings();
      final newAmount = current + amount;

      await _supabase
          .from('budgets')
          .update({'currentSavings': newAmount})
          .eq('user_id', userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to savings: $e');
      throw Exception('Failed to add to savings');
    }
  }

  Future<void> updateSavingsGoal({
    required double newGoal,
    required DateTime? targetDate,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _supabase
          .from('budgets')
          .update({
        'savings_goal': newGoal,
        'target_date': targetDate?.toIso8601String(),
      })
          .eq('user_id', userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating savings goal: $e');
      throw Exception('Failed to update savings goal');
    }
  }

  Future<double> getSavingsGoal() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _supabase
          .from('budgets')
          .select('savings_goal')
          .eq('user_id', userId)
          .single();

      return (response['savings_goal'] as num).toDouble();
    } catch (e) {
      debugPrint('Error getting savings goal: $e');
      throw Exception('Failed to get savings goal');
    }
  }

  Future<DateTime?> getTargetDate() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _supabase
          .from('budgets')
          .select('target_date')
          .eq('user_id', userId)
          .single();

      if (response['target_date'] == null) {
        return null;
      }
      return DateTime.tryParse(response['target_date']);
    } catch (e) {
      debugPrint('Error getting target date: $e');
      throw Exception('Failed to get target date');
    }
  }

  Future<void> resetCurrentSavings() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _supabase
          .from('budgets')
          .update({'currentSavings': 0.0})
          .eq('user_id', userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting current savings: $e');
      throw Exception('Failed to reset current savings');
    }
  }

  Future<double> getMonthlyIncome() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _supabase
          .from('budgets')
          .select('monthly_income')
          .eq('user_id', userId)
          .single();

      return (response['monthly_income'] as num).toDouble();
    } catch (e) {
      debugPrint('Error getting monthly income: $e');
      throw Exception('Failed to get monthly income');
    }
  }

  Future<void> updateMonthlyIncome(double newIncome) async {
    try {
      debugPrint('updateMonthlyIncome: Starting with newIncome=$newIncome');
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _supabase
          .from('budgets')
          .update({'monthly_income': newIncome})
          .eq('user_id', userId);
      debugPrint('updateMonthlyIncome: Income updated in database');

      await updateCurrentSavings();
      debugPrint('updateMonthlyIncome: Current savings updated');

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating monthly income: $e');
      throw Exception('Failed to update monthly income');
    }
  }

  Future<double> getTotalExpenses() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _supabase
          .from('budgets')
          .select('totalExpenses')
          .eq('user_id', userId)
          .single();

      return (response['totalExpenses'] as num).toDouble();
    } catch (e) {
      debugPrint('Error getting total expenses: $e');
      throw Exception('Failed to get total expenses');
    }
  }

  Future<void> updateTotalExpenses(double newExpenses) async {
    try {
      debugPrint('updateTotalExpenses: Starting with newExpenses=$newExpenses');
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _supabase
          .from('budgets')
          .update({'totalExpenses': newExpenses})
          .eq('user_id', userId);
      debugPrint('updateTotalExpenses: Expenses updated in database');

      await updateCurrentSavings();
      debugPrint('updateTotalExpenses: Current savings updated');

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating total expenses: $e');
      throw Exception('Failed to update total expenses');
    }
  }

  Future<void> autoAddSavings() async {
    try {
      debugPrint('autoAddSavings: Starting...');
      await updateCurrentSavings();
      debugPrint('autoAddSavings: Savings updated');
      notifyListeners();
    } catch (e) {
      debugPrint('Error automatically setting savings: $e');
      throw Exception('Failed to automatically set savings');
    }
  }

  Future<String> projectSavingsCompletion() async {
    try {
      final savingsGoal = await getSavingsGoal();
      final currentSavings = await getCurrentSavings();
      final monthlyIncome = await getMonthlyIncome();
      final totalExpenses = await getTotalExpenses();

      final monthlySavings = monthlyIncome - totalExpenses;
      final remainingSavings = savingsGoal - currentSavings;

      if (monthlySavings <= 0) {
        return "Cannot project. Increase income or reduce expenses.";
      }

      final monthsToCompletion = (remainingSavings / monthlySavings).ceil();

      if (monthsToCompletion <= 0) {
        return "Savings goal already reached or set to 0.";
      }

      return "Approximately $monthsToCompletion months to complete savings goal.";
    } catch (e) {
      debugPrint('Error projecting savings completion: $e');
      return "Error projecting completion time.";
    }
  }
}