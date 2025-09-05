import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endterm/viewmodel/savings_viewmodel.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final _savingsAmountController = TextEditingController();
  final _savingsGoalController = TextEditingController();

  bool _isLoading = true;
  double _currentSavings = 0.0;
  double _savingsGoal = 0.0;
  DateTime? _targetDate;
  String _completionProjection = "";

  @override
  void initState() {
    super.initState();
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSavingsData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<SavingsViewModel>();
    viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    final viewModel = context.read<SavingsViewModel>();
    viewModel.removeListener(_onViewModelChanged);
    _savingsAmountController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      _loadData();
      _projectCompletion();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final viewModel = context.read<SavingsViewModel>();

      _currentSavings = await viewModel.getCurrentSavings();
      _savingsGoal = await viewModel.getSavingsGoal();
      _targetDate = await viewModel.getTargetDate();

      _savingsGoalController.text = _savingsGoal.toString();
    } catch (e) {
      _showErrorSnackbar('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshSavingsData() async {
    if (!mounted) return;

    try {
      debugPrint('_refreshSavingsData: Starting refresh...');
      await context.read<SavingsViewModel>().updateCurrentSavings();

      final current = await context.read<SavingsViewModel>().getCurrentSavings();
      debugPrint('_refreshSavingsData: Got current savings: $current');

      if (mounted) setState(() => _currentSavings = current);

      _projectCompletion();
      debugPrint('_refreshSavingsData: Refresh complete');
    } catch (e) {
      debugPrint('_refreshSavingsData: Error refreshing savings: $e');
      _showErrorSnackbar('Error refreshing savings: $e');
    }
  }

  Future<void> _addSavings() async {
    final amount = double.tryParse(_savingsAmountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackbar('Please enter a valid amount');
      return;
    }

    try {
      await context.read<SavingsViewModel>().addToSavings(amount: amount);
      _savingsAmountController.clear();
      await _refreshCurrentSavings();
      _showSuccessSnackbar('Savings added successfully!');
      _projectCompletion();
    } catch (e) {
      _showErrorSnackbar('Error adding savings: $e');
    }
  }

  Future<void> _updateSavingsGoal() async {
    final newGoal = double.tryParse(_savingsGoalController.text);
    if (newGoal == null || newGoal <= 0) {
      _showErrorSnackbar('Please enter a valid savings goal');
      return;
    }

    try {
      await context.read<SavingsViewModel>().updateSavingsGoal(
        newGoal: newGoal,
        targetDate: _targetDate,
      );
      await _refreshSavingsGoal();
      _showSuccessSnackbar('Savings goal updated successfully!');
      _projectCompletion();
    } catch (e) {
      _showErrorSnackbar('Error updating savings goal: $e');
    }
  }

  Future<void> _resetSavings() async {
    try {
      await context.read<SavingsViewModel>().resetCurrentSavings();
      await _refreshCurrentSavings();
      _showSuccessSnackbar('Savings reset successfully!');
      _projectCompletion();
    } catch (e) {
      _showErrorSnackbar('Error resetting savings: $e');
    }
  }

  Future<void> _refreshCurrentSavings() async {
    if (!mounted) return;
    final current = await context.read<SavingsViewModel>().getCurrentSavings();
    if (mounted) setState(() => _currentSavings = current);
  }

  Future<void> _refreshSavingsGoal() async {
    if (!mounted) return;
    final goal = await context.read<SavingsViewModel>().getSavingsGoal();
    if (mounted) setState(() => _savingsGoal = goal);
  }

  Future<void> _autoAddSavings() async {
    try {
      await context.read<SavingsViewModel>().autoAddSavings();
      await _refreshCurrentSavings();
      _projectCompletion();
    } catch (e) {
      _showErrorSnackbar('Error adding auto savings: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _targetDate) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _projectCompletion() async {
    try {
      final projection = await context.read<SavingsViewModel>().projectSavingsCompletion();
      setState(() {
        _completionProjection = projection;
      });
    } catch (e) {
      _showErrorSnackbar('Error projecting completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSavingsData,
            tooltip: 'Refresh Savings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildAddSavingsSection(),
            const SizedBox(height: 24),
            _buildSetGoalSection(),
            const SizedBox(height: 24),
            _buildResetButton(),
            const SizedBox(height: 24),
            Text(_completionProjection),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Savings Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSummaryRow('Current Savings', _currentSavings),
            _buildSummaryRow('Savings Goal', _savingsGoal),
            if (_targetDate != null)
              _buildSummaryRow('Target Date', _targetDate!.toLocal().toString().split(' ')[0]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _savingsGoal > 0 ? (_currentSavings / _savingsGoal).clamp(0.0, 1.0) : 0,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              _savingsGoal > 0 ? 'Progress: ${((_currentSavings / _savingsGoal) * 100).toStringAsFixed(1)}%' : 'Set a savings goal to track progress',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, dynamic value) {
    String displayValue;
    if (value is double) displayValue = '\$${value.toStringAsFixed(2)}';
    else displayValue = value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddSavingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Savings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _savingsAmountController,
          decoration: const InputDecoration(
            labelText: 'Enter amount to add',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addSavings,
            child: const Text('Add Savings'),
          ),
        ),
      ],
    );
  }

  Widget _buildSetGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set Savings Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _savingsGoalController,
          decoration: const InputDecoration(
            labelText: 'Enter your savings goal',
            prefixIcon: Icon(Icons.flag),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(_targetDate == null ? 'Select Target Date' : 'Target Date: ${_targetDate!.toLocal().toString().split(' ')[0]}'),
            IconButton(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateSavingsGoal,
            child: const Text('Update Goal'),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        onPressed: () => _showResetConfirmationDialog(),
        child: const Text('Reset Savings'),
      ),
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Savings'),
        content: const Text('Are you sure you want to reset your current savings to zero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSavings();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}