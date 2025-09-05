import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = false;
  String? error;

  double monthlyIncome = 0.0;
  double savingsGoal = 0.0;
  bool onboardingComplete = false;
  int? userId;
  String? userName; // Add userName variable to store the user's name

  bool get getIsLoading => isLoading;
  String? get getError => error;

  // This will initialize the onboarding flow and reload the data when necessary
  Future<void> initializeOnboarding() async {
    try {
      setLoading(true);
      userId = await getCurrentUserId(); // This will set onboardingComplete
      // If a user is authenticated, load their data.
      if (userId != null) {
        await loadUserData(); // Load user's name and budget data
      }
    } catch (e) {
      error = 'Failed to initialize onboarding: ${e.toString()}';
      debugPrint(error);
    } finally {
      setLoading(false);
    }
  }

  // Load user data including name and budget info
  Future<void> loadUserData() async {
    try {
      if (userId == null) throw Exception('User not authenticated');

      // Fetch the user's name and budget data from the database
      final userResponse =
      await supabase.from('user').select('name').eq('id', userId!).single();

      userName = userResponse['name']; // Store user's name
      debugPrint('User Name: $userName');

      await loadUserBudgetInfo(); // Load budget info after user name
    } catch (e) {
      error = 'Failed to load user data: ${e.toString()}';
      debugPrint(error);
    }
  }

  // Load the user's budget info (monthly income, savings goal)
  Future<void> loadUserBudgetInfo() async {
    try {
      if (userId == null) throw Exception('User not authenticated');

      final budgetResponse = await supabase
          .from('budgets')
          .select('monthly_income, savings_goal')
          .eq('user_id', userId!)
          .maybeSingle();

      if (budgetResponse != null) {
        monthlyIncome = (budgetResponse['monthly_income'] as num).toDouble();
        savingsGoal = (budgetResponse['savings_goal'] as num).toDouble();
        notifyListeners(); // Notify the view to rebuild
      }
    } catch (e) {
      error = 'Failed to load budget info: ${e.toString()}';
      debugPrint(error);
    }
  }

  // Fetch the current user ID using Supabase
  Future<int?> getCurrentUserId() async {
    try {
      final session = supabase.auth.currentSession;
      if (session == null) return null; // No logged-in session

      final response = await supabase
          .from('user')
          .select('id, onboarding_complete')
          .eq('auth_id', session.user.id)
          .single();

      onboardingComplete = response['onboarding_complete'] ?? false;
      debugPrint('Onboarding complete: $onboardingComplete');

      return response['id'] as int?;
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  Future<void> saveOnboardingData() async {
    try {
      setLoading(true);
      error = null;

      if (userId == null) {
        userId = await getCurrentUserId();
        if (userId == null) {
          throw Exception('User not authenticated');
        }
      }

      final existingBudget = await supabase
          .from('budgets')
          .select('id')
          .eq('user_id', userId!)
          .maybeSingle();

      if (existingBudget != null) {
        // Update existing budget
        await supabase.from('budgets').update({
          'monthly_income': monthlyIncome,
          'savings_goal': savingsGoal,
        }).eq('user_id', userId!);
      } else {
        // Insert new budget entry
        await supabase.from('budgets').insert({
          'user_id': userId!,
          'monthly_income': monthlyIncome,
          'savings_goal': savingsGoal,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Update onboarding status in the user table
      await supabase.from('user').update({
        'onboarding_complete': true,
      }).eq('id', userId!);

      onboardingComplete = true;
      notifyListeners();
      debugPrint('Onboarding data saved successfully');
    } catch (e) {
      error = 'Failed to save onboarding: ${e.toString()}';
      debugPrint(error);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Update the monthly income in the ViewModel
  void updateIncome(double value) {
    monthlyIncome = value;
    notifyListeners();
  }

  // Update the savings goal in the ViewModel
  void updateSavingsGoal(double value) {
    savingsGoal = value;
    notifyListeners();
  }

  // Set loading state for UI
  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }
}