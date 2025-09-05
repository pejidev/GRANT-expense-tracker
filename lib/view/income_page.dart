import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/onboarding_viewmodel.dart';

class IncomePage extends StatelessWidget {
  final VoidCallback onNext;

  const IncomePage({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OnboardingViewModel>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What is your monthly income?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please enter your average monthly income after taxes. This helps us create a realistic budget for you.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly Income',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                viewModel.updateIncome(double.tryParse(value) ?? 0.0);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'What is your savings goal?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'How much would you like to save each month? We recommend saving at least 20% of your income.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly Savings Goal',
              prefixIcon: Icon(Icons.savings),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                viewModel.updateSavingsGoal(double.tryParse(value) ?? 0.0);
              }
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: viewModel.monthlyIncome > 0 ? onNext : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}