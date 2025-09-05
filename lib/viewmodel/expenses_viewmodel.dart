import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:endterm/model/expensecategory_model.dart';
import 'package:endterm/model/expense_model.dart';
import 'package:endterm/model/budget_model.dart';
import 'dart:async';

class ExpenseViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;

  List<ExpenseCategory> expenseCategories = [];
  Budget? currentBudget;

  bool get getIsLoading => _isLoading;
  String? get getError => _error;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      debugPrint('--- setLoading: isLoading set to $loading ---');
      notifyListeners();
    }
  }

  void _setError(String? errorMsg) {
    if (_error != errorMsg) {
      _error = errorMsg;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    debugPrint('--- ExpenseViewModel: Initializing... ---');
    _setLoading(true);
    _setError(null);

    try {
      await supabase.auth.refreshSession();
      debugPrint('Session refreshed: ${supabase.auth.currentSession?.user.id}');
    } catch (e) {
      debugPrint('Session refresh failed: $e');
    }

    if (supabase.auth.currentSession == null) {
      _setError('User not authenticated');
      debugPrint('ERROR in initialize: $_error');
      _setLoading(false);
      return;
    }

    await fetchExpenseCategories();
    await loadUserExpenses();
    await fetchCurrentBudget();
    await updateBudgetTotalExpenses();

    debugPrint(
        '--- ExpenseViewModel: Initialization complete. Categories: ${expenseCategories.length}, Current Month Total: \$${currentMonthTotalExpenses.toStringAsFixed(2)} ---');
    _setLoading(false);
  }

  Future<void> manualRefresh() async {
    debugPrint('--- Manual refresh triggered ---');
    await initialize();
    debugPrint('--- Manual refresh completed ---');
  }

  Future<void> fetchCurrentBudget() async {
    debugPrint('--- fetchCurrentBudget: Starting ---');
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        _setError('User not authenticated or user ID not found');
        debugPrint('ERROR in fetchCurrentBudget: User ID is null');
        return;
      }

      debugPrint('Fetching budget for user ID: $userId');

      final response = await supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        currentBudget = Budget.fromMap(response);
        debugPrint(
            'Current budget found: ID: ${currentBudget!.id}, Income: ${currentBudget!.monthlyIncome}, TotalExpenses: ${currentBudget!.totalExpenses}');
      } else {
        debugPrint('No budget found for user, will need to create one when updating');
        currentBudget = null;
      }
    } catch (e, stackTrace) {
      _setError('Failed to fetch current budget: ${e.toString()}');
      debugPrint('ERROR fetching budget: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> updateBudgetTotalExpenses() async {
    debugPrint('--- updateBudgetTotalExpenses: Starting ---');
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        _setError('User not authenticated or user ID not found');
        debugPrint('ERROR in updateBudgetTotalExpenses: User ID is null');
        return;
      }

      final currentMonthTotal = currentMonthTotalExpenses;

      debugPrint('Current month total expenses: $currentMonthTotal');

      if (currentBudget != null) {
        currentBudget!.totalExpenses = currentMonthTotal;

        await supabase
            .from('budgets')
            .update({'totalExpenses': currentMonthTotal})
            .eq('id', currentBudget!.id!);

        debugPrint(
            'Updated existing budget (ID: ${currentBudget!.id}) with total expenses: $currentMonthTotal');
      } else {
        debugPrint(
            'No budget exists for the user. Budget needs to be created first in the budget screen.');
      }

      notifyListeners();
    } catch (e, stackTrace) {
      _setError('Failed to update budget total expenses: ${e.toString()}');
      debugPrint('ERROR updating budget total: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> fetchExpenseCategories() async {
    debugPrint('--- fetchExpenseCategories: Starting ---');
    try {
      final response = await supabase
          .from('expense_categories')
          .select('id, name')
          .order('name');

      debugPrint('Fetched ${response.length} categories from Supabase.');

      expenseCategories = response
          .map((item) {
        try {
          return ExpenseCategory.fromMap(item as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing category item: $item, Error: $e');
          return null;
        }
      })
          .where((category) => category != null)
          .cast<ExpenseCategory>()
          .toList();

      if (expenseCategories.isEmpty) {
        debugPrint('WARNING: No expense categories found or loaded.');
      } else {
        debugPrint(
            'Categories loaded successfully: ${expenseCategories.map((c) => "${c.id}: ${c.name}").join(', ')}');
      }

      debugPrint('--- fetchExpenseCategories finished successfully ---');
    } catch (e, stackTrace) {
      _setError('Failed to load categories: ${e.toString()}');
      debugPrint('ERROR loading categories: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> loadUserExpenses() async {
    debugPrint('--- loadUserExpenses: Starting ---');
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        _setError('User not authenticated or user ID not found');
        debugPrint('ERROR in loadUserExpenses: User ID is null when loading expenses');
        return;
      }

      debugPrint('Fetching expenses from Supabase for user ID: $userId');

      final response = await supabase
          .from('expenses')
          .select(
          'id, name, amount, categoryId, is_recurring, start_date, end_date, recurring_frequency, userId')
          .eq('userId', userId)
          .order('start_date', ascending: false);

      debugPrint('Supabase query for expenses executed. Count: ${response.length}');

      for (var category in expenseCategories) {
        category.expenses.clear();
      }
      debugPrint('Local expenses list within categories cleared.');

      final categoryMap = {for (var c in expenseCategories) c.id: c};
      int processedCount = 0;

      for (var item in response) {
        try {
          if (item is Map<String, dynamic>) {
            final expense = Expense.fromMap(item);

            if (categoryMap.containsKey(expense.categoryId)) {
              categoryMap[expense.categoryId]!.expenses.add(expense);
              processedCount++;
            } else {
              debugPrint(
                  'WARNING in loadUserExpenses: Category ID ${expense.categoryId} found in expense, but not in local category list. Expense "${expense.name}" ignored.');
            }
          } else {
            debugPrint('WARNING in loadUserExpenses: Invalid item structure received (not a Map): $item');
          }
        } catch (e, stackTrace) {
          debugPrint('Error processing individual expense item: $e');
          debugPrint('Problematic item data: $item');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      debugPrint('Finished processing response. Processed $processedCount expenses successfully.');
      _setError(null);
      notifyListeners();
      debugPrint('--- loadUserExpenses finished successfully ---');
    } catch (e, stackTrace) {
      _setError('Failed to load expenses: ${e.toString()}');
      debugPrint('ERROR in loadUserExpenses catch block: $e');
      debugPrint('Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    debugPrint('--- addExpense: Starting for "${expense.name}" ---');
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated or user ID not found');
      }

      final expenseWithUserId = Expense(
          id: expense.id,
          userId: expense.userId ?? userId,
          name: expense.name,
          amount: expense.amount,
          categoryId: expense.categoryId,
          isRecurring: expense.isRecurring,
          startDate: expense.startDate,
          endDate: expense.endDate,
          recurringFrequency: expense.recurringFrequency);

      debugPrint('Adding expense with details: ${expenseWithUserId.toMap()}');

      final response = await supabase
          .from('expenses')
          .insert(expenseWithUserId.toMap())
          .select('id')
          .single();

      final newExpense = Expense(
        id: response['id'] as int,
        userId: expenseWithUserId.userId,
        name: expenseWithUserId.name,
        amount: expenseWithUserId.amount,
        categoryId: expenseWithUserId.categoryId,
        isRecurring: expenseWithUserId.isRecurring,
        startDate: expenseWithUserId.startDate,
        endDate: expenseWithUserId.endDate,
        recurringFrequency: expenseWithUserId.recurringFrequency,
      );

      debugPrint('Expense added to Supabase with ID: ${newExpense.id}');

      final category = expenseCategories.firstWhere(
            (cat) => cat.id == newExpense.categoryId,
        orElse: () => throw Exception('Category not found locally'),
      );

      category.expenses.insert(0, newExpense);
      debugPrint('Expense added to local category "${category.name}".');

      await updateBudgetTotalExpenses();

      notifyListeners();
      debugPrint('--- addExpense finished successfully ---');
    } catch (e, stackTrace) {
      _setError('Failed to add expense: ${e.toString()}');
      debugPrint('ERROR adding expense: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    debugPrint('--- updateExpense: Starting for ID ${expense.id} ---');
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      if (expense.id == null) {
        throw Exception('Cannot update expense without ID');
      }

      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated or user ID not found');
      }

      final expenseToUpdate = Expense(
          id: expense.id,
          userId: expense.userId ?? userId,
          name: expense.name,
          amount: expense.amount,
          categoryId: expense.categoryId,
          isRecurring: expense.isRecurring,
          startDate: expense.startDate,
          endDate: expense.endDate,
          recurringFrequency: expense.recurringFrequency);

      debugPrint('Updating expense ID ${expenseToUpdate.id} with details: ${expenseToUpdate.toMap()}');

      await supabase
          .from('expenses')
          .update(expenseToUpdate.toMap())
          .eq('id', expenseToUpdate.id!);

      debugPrint('Expense updated in Supabase for ID: ${expenseToUpdate.id}');

      bool foundAndUpdated = false;
      int? oldCategoryIndex;
      int? expenseIndexInOldCategory;

      for (int i = 0; i < expenseCategories.length; i++) {
        final category = expenseCategories[i];
        final index = category.expenses.indexWhere((e) => e.id == expenseToUpdate.id);
        if (index != -1) {
          oldCategoryIndex = i;
          expenseIndexInOldCategory = index;
          break;
        }
      }

      if (oldCategoryIndex != null && expenseIndexInOldCategory != null) {
        final oldCategory = expenseCategories[oldCategoryIndex];
        if (oldCategory.id == expenseToUpdate.categoryId) {
          oldCategory.expenses[expenseIndexInOldCategory] = expenseToUpdate;
          debugPrint('Updated expense in local cache within category "${oldCategory.name}".');
          foundAndUpdated = true;
        } else {
          oldCategory.expenses.removeAt(expenseIndexInOldCategory);
          debugPrint('Removed expense from old category "${oldCategory.name}" cache.');
        }
      }

      if (!foundAndUpdated) {
        final newCategory = expenseCategories.firstWhere(
              (cat) => cat.id == expenseToUpdate.categoryId,
          orElse: () => throw Exception('Cannot update expense: Target category not found locally.'),
        );
        newCategory.expenses.insert(0, expenseToUpdate);
        debugPrint('Added updated expense to new category "${newCategory.name}" cache.');
      }

      await updateBudgetTotalExpenses();

      notifyListeners();
      debugPrint('--- updateExpense finished successfully ---');
    } catch (e, stackTrace) {
      _setError('Failed to update expense: ${e.toString()}');
      debugPrint('ERROR updating expense: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeExpense(Expense expense) async {
    debugPrint('--- removeExpense: Starting for ID ${expense.id} ---');
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      if (expense.id == null) {
        throw Exception('Cannot remove expense without ID');
      }

      debugPrint('Removing expense ID ${expense.id} from Supabase.');
      await supabase.from('expenses').delete().eq('id', expense.id!);
      debugPrint('Expense removed from Supabase for ID: ${expense.id}');

      bool removed = false;
      for (var category in expenseCategories) {
        final initialLength = category.expenses.length;
        category.expenses.removeWhere((e) => e.id == expense.id);
        if (category.expenses.length < initialLength) {
          debugPrint('Removed expense from local category "${category.name}" cache.');
          removed = true;
          break;
        }
      }
      if (!removed) {
        debugPrint('WARNING in removeExpense: Expense ID ${expense.id} not found in local cache for removal.');
      }

      await updateBudgetTotalExpenses();

      notifyListeners();
      debugPrint('--- removeExpense finished successfully ---');
    } catch (e, stackTrace) {
      _setError('Failed to remove expense: ${e.toString()}');
      debugPrint('ERROR removing expense: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<int?> getCurrentUserId() async {
    debugPrint('--- getCurrentUserId: Starting ---');
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        debugPrint('getCurrentUserId: No Supabase auth user found.');
        return null;
      }
      final authId = authUser.id;
      debugPrint('getCurrentUserId: Found Supabase auth user ID: $authId');

      try {
        final response = await supabase
            .from('user')
            .select('id')
            .eq('auth_id', authId)
            .maybeSingle();

        if (response == null) {
          debugPrint('getCurrentUserId: No record found in "user" table for auth_id: $authId');
          return null;
        } else {
          final numericId = response['id'] as int?;
          if (numericId == null) {
            debugPrint('getCurrentUserId: Record found in "user" table but numeric "id" is null.');
            return null;
          } else {
            debugPrint('getCurrentUserId: Successfully retrieved numeric user ID: $numericId');
            return numericId;
          }
        }
      } catch (dbError, stackTrace) {
        debugPrint('getCurrentUserId: Database error querying "user" table: $dbError');
        debugPrint('Stack trace: $stackTrace');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('getCurrentUserId: Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    } finally {
      debugPrint('--- getCurrentUserId: Finished ---');
    }
  }

  double calculateExpensesForMonth(int year, int month) {
    double monthlyTotal = 0.0;
    final targetMonthStart = DateTime(year, month, 1);
    final targetMonthEnd = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    debugPrint('Calculating expenses for $year-$month (Range: $targetMonthStart to $targetMonthEnd)');

    for (var category in expenseCategories) {
      for (var expense in category.expenses) {
        if (expense.isRecurring) {
          if (expense.startDate == null) {
            continue;
          }

          final effectiveStartDate =
          DateTime(expense.startDate!.year, expense.startDate!.month, expense.startDate!.day);

          DateTime? effectiveEndDate;
          if (expense.endDate != null) {
            effectiveEndDate = DateTime(
                expense.endDate!.year, expense.endDate!.month, expense.endDate!.day, 23, 59, 59, 999);
          }

          bool startedInTime = !effectiveStartDate.isAfter(targetMonthEnd);
          bool notEndedTooEarly = effectiveEndDate == null || !effectiveEndDate.isBefore(targetMonthStart);

          if (startedInTime && notEndedTooEarly) {
            if (expense.recurringFrequency == 'monthly') {
              monthlyTotal += expense.amount;
            }
          }
        } else {
          final transactionDate = expense.startDate;
          if (transactionDate != null &&
              transactionDate.year == year &&
              transactionDate.month == month) {
            monthlyTotal += expense.amount;
          }
        }
      }
    }
    debugPrint('=> Total calculated for $year-$month: \$${monthlyTotal.toStringAsFixed(2)}');
    return monthlyTotal;
  }

  double get currentMonthTotalExpenses {
    final now = DateTime.now();
    return calculateExpensesForMonth(now.year, now.month);
  }

  double get allStoredExpensesTotal {
    return expenseCategories.fold(
        0.0,
            (categorySum, category) => categorySum +
            category.expenses.fold(0.0, (expenseSum, expense) => expenseSum + expense.amount));
  }
}