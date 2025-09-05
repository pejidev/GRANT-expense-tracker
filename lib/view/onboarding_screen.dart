import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodel/app_viewmodel.dart';
import 'package:endterm/viewmodel/onboarding_viewmodel.dart';
import 'income_page.dart';
import 'package:endterm/view/expenses_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();
  int currentPageIndex = 0;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OnboardingViewModel>(context, listen: false).initializeOnboarding();
    });
  }

  void goToNextPage() {
    if (currentPageIndex < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingViewModel = Provider.of<OnboardingViewModel>(context);

    // Show loading indicator if the ViewModel is loading
    if (onboardingViewModel.getIsLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    pages = [
      IncomePage(onNext: goToNextPage),
      ExpensesPage(onNext: goToNextPage),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Budget'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (currentPageIndex + 1) / pages.length,
            minHeight: 4,
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => currentPageIndex = index),
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomBar(),
    );
  }

  Widget buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (currentPageIndex > 0)
            TextButton(
              onPressed: () => pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text('BACK'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              if (currentPageIndex < pages.length - 1) {
                pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                await completeOnboarding();
              }
            },
            child: Text(
              currentPageIndex == pages.length - 1 ? 'FINISH' : 'NEXT',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> completeOnboarding() async {
    final onboardingViewModel = Provider.of<OnboardingViewModel>(context, listen: false);

    try {
      await onboardingViewModel.saveOnboardingData();

      final isDataSaved = onboardingViewModel.getError == null;
      if (isDataSaved) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception("Onboarding data failed to save");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete onboarding: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}