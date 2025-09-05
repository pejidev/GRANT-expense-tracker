import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';
import 'viewmodel/app_viewmodel.dart';
import 'viewmodel/onboarding_viewmodel.dart';
import 'viewmodel/expenses_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: '****************',
    anonKey: '*********************',
  );



  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppViewModel()),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<ExpenseViewModel>().initialize(),  // Ensure initialization
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());  // Show loading indicator
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));  // Show error message
        }

        // Once data is initialized, show your app
        return const AppRouter();
      },
    );
  }
}
