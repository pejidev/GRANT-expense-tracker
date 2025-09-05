import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../view/auth_screen.dart';
import '../view/home.dart';
import '../view/onboarding_screen.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _determineInitialRoute();
  }

  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedOut) {
        _navigateToRoute('/signin');
      } else if (event == AuthChangeEvent.signedIn) {
        _determineInitialRoute();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _determineInitialRoute() async {
    try {
      // Check for an existing session
      final session = _supabase.auth.currentSession;
      if (session == null) {
        // No session means the user is not logged in
        _navigateToRoute('/signin');
        return;
      }

      // Verify if the user exists in the database
      final userExists = await _checkIfUserExists(session.user.id);
      if (!userExists) {
        await _supabase.auth.signOut();
        _navigateToRoute('/signin');
        return;
      }

      // Check the onboarding status
      final isOnboarded = await _checkOnboardingStatus(session.user.id);
      _navigateToRoute(isOnboarded ? '/home' : '/onboarding');
    } catch (e) {
      debugPrint('Error in auth checker: $e');
      _navigateToRoute('/signin'); // Fallback to sign-in if there's an error
    }
  }

  void _navigateToRoute(String route) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
            (route) => false,
      );
    });
  }

  Future<bool> _checkIfUserExists(String authId) async {
    try {
      final response = await _supabase
          .from('user')
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false; // Assume user doesn't exist in case of error
    }
  }

  Future<bool> _checkOnboardingStatus(String authId) async {
    try {
      final response = await _supabase
          .from('user')
          .select('onboarding_complete')
          .eq('auth_id', authId)
          .maybeSingle();
      return response?['onboarding_complete'] ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const Scaffold(
      body: Center(child: Text('Redirecting...')),
    );
  }
}