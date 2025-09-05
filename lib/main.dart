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
    url: 'https://tncxzuzjmnfeqowwvuvm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRuY3h6dXpqbW5mZXFvd3d2dXZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMyMzYwMDEsImV4cCI6MjA1ODgxMjAwMX0.C4HcLahiBXakdxTca8bEJAgWYaQLKbIwthW_mSPki2w',
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
