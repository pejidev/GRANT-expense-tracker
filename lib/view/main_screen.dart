import 'package:endterm/view/edit_budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endterm/viewmodel/onboarding_viewmodel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String budgetDate = '';

  // Initialize onboarding when the screen loads or the user logs in
  @override
  void initState() {
    super.initState();
    final onboardingVM = context.read<OnboardingViewModel>();
    onboardingVM
        .initializeOnboarding(); // Ensure data is loaded for the current user
  }

  void editBudget() async {
    final onboardingVM = context.read<OnboardingViewModel>();

    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBudgetScreen(
          budgetAmount: onboardingVM.monthlyIncome.toString(),
        ),
      ),
    );

    if (updatedData != null) {
      final newAmount = double.tryParse(updatedData['budgetAmount']);
      if (newAmount != null) {
        onboardingVM.updateIncome(newAmount);
        await onboardingVM.saveOnboardingData();
      }

      setState(() {
        budgetDate = updatedData['date'] ?? budgetDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingVM = context.watch<OnboardingViewModel>();
    final income = onboardingVM.monthlyIncome.toStringAsFixed(2);
    final userName = onboardingVM.userName ?? 'User'; // Display user's name

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            height: 32,
            margin: const EdgeInsets.all(10),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.access_alarm),
                const SizedBox(width: 10),
                Text(
                  userName, // Display the user's name here
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: editBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(5.0),
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Budget:",
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'P$income',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "until $budgetDate",
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "TAP TO EDIT",
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.black.withAlpha(155),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text('Recent Transactions: '),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, int i) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Test'),
                            ],
                          ),
                          Column(
                            children: const [
                              Text('Test1'),
                              Text('Test2'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}