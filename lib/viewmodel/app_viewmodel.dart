import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/appmodel.dart';

class AppViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<AppUser> _users = [];
  bool _isLoading = false;
  String? _error;
  int? _currentUserId;

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentUserId => _currentUserId;

  Future<void> initialize() async {
    try {
      setLoading(true);
      await _refreshCurrentUserId();
      await fetchUsers();
    } catch (e) {
      _error = 'Initialization failed: ${e.toString()}';
      debugPrint(_error);
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchUsers() async {
    try {
      setLoading(true);
      final response = await supabase.from('user').select();
      _users = (response as List).map((e) => AppUser.fromMap(e)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load users: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      setLoading(true);
      _error = null;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Authentication failed - no user returned');
      }

      await _ensureUserProfileExists(response.user!);
      await _refreshCurrentUserId();
    } catch (e) {
      _error = 'Sign in failed: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<int> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      setLoading(true);
      _error = null;

      // 1. Create auth account
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Auth registration failed - no user returned');
      }

      // 2. Create user profile
      final numericId = _generateUserId();
      await _createUserProfile(
        id: numericId,
        authId: authResponse.user!.id,
        name: name,
        email: email,
      );

      // 3. Create initial budget
      await _createInitialBudget(numericId);

      _currentUserId = numericId;
      return numericId;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveOnboardingData({
    required double monthlyIncome,
    required double savingsGoal,
  }) async {
    try {
      setLoading(true);
      _error = null;

      if (_currentUserId == null) {
        throw Exception('No authenticated user');
      }

      // Update user onboarding status
      await supabase.from('user').update({
        'onboarding_complete': true,
      }).eq('id', _currentUserId!);

      // Update budget
      await supabase.from('budgets').update({
        'monthly_income': monthlyIncome,
        'savings_goal': savingsGoal,
      }).eq('user_id', _currentUserId!);
    } catch (e) {
      _error = 'Failed to save onboarding data: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> checkOnboardingStatus() async {
    if (_currentUserId == null) return false;

    try {
      final response = await supabase
          .from('user')
          .select('onboarding_complete')
          .eq('id', _currentUserId!)
          .single();

      return response['onboarding_complete'] ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      setLoading(true);
      _error = null;

      await supabase.auth.signOut();
      _currentUserId = null;
      _users = [];
    } catch (e) {
      _error = 'Sign out failed: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Private helper methods
  Future<void> _refreshCurrentUserId() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      _currentUserId = null;
      return;
    }

    try {
      final profile = await supabase
          .from('user')
          .select('id')
          .eq('auth_id', authUser.id)
          .maybeSingle();

      _currentUserId = profile?['id'] as int?;
    } catch (e) {
      debugPrint('Error refreshing current user ID: $e');
      _currentUserId = null;
    }
  }

  Future<void> _ensureUserProfileExists(User authUser) async {
    final existingProfile = await supabase
        .from('user')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();

    if (existingProfile == null) {
      debugPrint('No user profile found, creating one');
      final numericId = _generateUserId();
      await _createUserProfile(
        id: numericId,
        authId: authUser.id,
        name: authUser.email?.split('@').first ?? 'User',
        email: authUser.email ?? '',
      );
    }
  }

  Future<void> _createUserProfile({
    required int id,
    required String authId,
    required String name,
    required String email,
  }) async {
    try {
      await supabase.from('user').insert({
        'id': id,
        'auth_id': authId,
        'name': name,
        'email': email,
        'onboarding_complete': false,
      });
    } catch (e) {
      if (e is PostgrestException) {
        if (e.code == '404') {
          throw Exception('The "user" table does not exist. Please create it in Supabase dashboard.');
        } else if (e.code == '23505') { // Unique violation
          throw Exception('User profile already exists');
        }
      }
      rethrow;
    }
  }

  Future<void> _createInitialBudget(int userId) async {
    try {
      await supabase.from('budgets').insert({
        'user_id': userId,
        'monthly_income': 0,
        'savings_goal': 0,
      });
    } catch (e) {
      if (e is PostgrestException && e.code == '404') {
        debugPrint('Warning: budgets table does not exist');
      } else {
        debugPrint('Error creating initial budget: $e');
      }
    }
  }

  int _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch + (DateTime.now().microsecond % 1000);
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}