import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view/auth_screen.dart';
import '../view/edit_budget_screen.dart';
import '../view/transactions_list_screen.dart';
import '../view/home.dart';
import '../view/onboarding_screen.dart';
import '../view/savings_page.dart';
import '../viewmodel/onboarding_viewmodel.dart';
import '../viewmodel/expenses_viewmodel.dart';
import '../viewmodel/savings_viewmodel.dart';
import 'AuthChecker.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => OnboardingViewModel()..initializeOnboarding(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => SavingsViewModel(), // Add SavingsViewModel provider
        ),
      ],
      child: MaterialApp(
        title: 'GRANT',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthChecker(),
          '/signin': (context) => const AuthScreen(),
          '/home': (context) => Consumer<OnboardingViewModel>(
            builder: (context, onboardingVm, child) {
              if (!onboardingVm.onboardingComplete &&
                  onboardingVm.userId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/onboarding');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const HomeScreen();
            },
          ),
          '/transactionslistscreen': (context) => const TransactionsListScreen(),
          '/onboarding': (context) => const OnboardingScreen(), // No alias
          '/savings': (context) => const SavingsPage(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        ),
      ),
    );
  }
}