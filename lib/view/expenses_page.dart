import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodel/expenses_viewmodel.dart';
import '../model/expense_model.dart';
import '../model/expensecategory_model.dart'; // Make sure path is correct

class ExpensesPage extends StatefulWidget {
  final VoidCallback onNext; // Required callback for navigation

  const ExpensesPage({Key? key, required this.onNext}) : super(key: key);

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  int _currentPageIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to access Provider safely after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only initialize if not already done
      if (!_isInitialized && mounted) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    // Prevent re-initialization
    if (_isInitialized) return;
    _isInitialized = true; // Mark as initialized early

    final vm = Provider.of<ExpenseViewModel>(context, listen: false);
    // Show loading UI immediately if VM isn't already loading from somewhere else
    if (!vm.getIsLoading) {
      // Manually trigger loading state if needed, though initialize should do it
      // setState(() {}); // Rebuild to show potential loading indicator from Consumer
    }
    await vm.initialize();
    // No need for setState here, Consumer will rebuild based on VM changes
  }


  Future<void> _refreshData() async {
    final vm = Provider.of<ExpenseViewModel>(context, listen: false);
    await vm.manualRefresh();
    // Optional: Show a snackbar on completion
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data refreshed'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showEmptyWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please add at least one expense before proceeding'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseViewModel>(
      builder: (context, vm, child) {
        // Handle initial loading state (before categories are loaded)
        if (vm.getIsLoading && vm.expenseCategories.isEmpty && !_isInitialized) {
          return _buildLoadingScaffold('Initializing...');
        }

        // Handle error state when no categories loaded
        if (vm.getError != null && vm.expenseCategories.isEmpty) {
          return _buildErrorScaffold(vm);
        }

        // Handle case where initialization finished but no categories exist
        if (!vm.getIsLoading && vm.expenseCategories.isEmpty && _isInitialized) {
          return _buildEmptyScaffold();
        }

        // If we have categories, build the main UI
        // Clamp index just in case list changes during build
        if (vm.expenseCategories.isNotEmpty) {
          _currentPageIndex = _currentPageIndex.clamp(0, vm.expenseCategories.length - 1);
        } else {
          _currentPageIndex = 0; // Reset if categories disappear
          // Potentially show an empty state here too if categories become empty after init
        }


        // Avoid errors if categories list becomes empty unexpectedly
        if (vm.expenseCategories.isEmpty) {
          return _buildEmptyScaffold(); // Or another appropriate state
        }

        final currentCategory = vm.expenseCategories[_currentPageIndex];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Monthly Expenses'),
            actions: [
              // Show loading indicator in AppBar during any operation
              if (vm.getIsLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData, // Use the VM refresh method
                  tooltip: 'Refresh Data',
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData, // Link to VM refresh
            child: Column(
              children: [
                // Show persistent error banner if an error exists
                if (vm.getError != null)
                  _buildErrorBanner(vm.getError!),
                _buildCategorySelector(vm),
                Expanded(
                  // Use a ListView to handle potential overflow if content is large
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(), // Enable scroll even if content fits
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildCategoryContent(vm, currentCategory),
                        )
                      ]
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigation(vm),
        );
      },
    );
  }

  // --- Builder Methods for Different States ---

  Widget _buildLoadingScaffold(String message) => Scaffold(
    appBar: AppBar(title: const Text('Monthly Expenses')),
    body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(message),
      ],
    )),
  );

  Widget _buildErrorScaffold(ExpenseViewModel vm) => Scaffold(
    appBar: AppBar(title: const Text('Monthly Expenses')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error Loading Data', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(vm.getError ?? 'An unknown error occurred.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData, // Retry initialization
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildEmptyScaffold() => Scaffold(
    appBar: AppBar(title: const Text('Monthly Expenses')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('No expense categories found.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          const Text('Categories might be loading or none exist.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData, // Allow refresh even if empty
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    ),
  );


  // --- UI Component Builders ---

  Widget _buildErrorBanner(String error) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: Theme.of(context).colorScheme.errorContainer,
    child: Text(
      "Error: $error",
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildCategorySelector(ExpenseViewModel vm) {
    // Handle case where categories might be empty temporarily
    if (vm.expenseCategories.isEmpty) {
      return const SizedBox.shrink(); // Don't show selector if no categories
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: List.generate(vm.expenseCategories.length, (index) {
          final category = vm.expenseCategories[index];
          final isSelected = index == _currentPageIndex;
          final expenseCount = category.expenses.length; // Count expenses in this category

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.name),
                  // Show count badge only if > 0
                  if (expenseCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$expenseCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).primaryColorDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _currentPageIndex = index);
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade200, // Background for unselected
              elevation: isSelected ? 2 : 0,
            ),
          );
        }),
      ),
    );
  }


  Widget _buildCategoryContent(ExpenseViewModel vm, ExpenseCategory category) {
    // This Column is inside a ListView now, so padding is applied externally
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category ${_currentPageIndex + 1} of ${vm.expenseCategories.length}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600
          ),
        ),
        const SizedBox(height: 4),
        Text(category.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        if (category.expenses.isEmpty)
          _buildEmptyCategoryContent(category)
        else
          _buildExpenseList(category, vm),
        const SizedBox(height: 20),
        _buildActionButtons(category, vm),
        // No need for extra SizedBox height at bottom due to outer ListView
      ],
    );
  }

  Widget _buildEmptyCategoryContent(ExpenseCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)
      ),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No expenses added for ${category.name} yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Expense" below to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(ExpenseCategory category, ExpenseViewModel vm) {
    return Column(
      // Build the list of cards
      children: category.expenses
          .map((expense) => _buildExpenseCard(expense, category, vm))
          .toList(), // Explicitly convert to list
    );
  }

  Widget _buildExpenseCard(Expense expense, ExpenseCategory category, ExpenseViewModel vm) {
    // --- Date Formatter ---
    final DateFormat formatter = DateFormat('MMM d, yyyy'); // e.g., Apr 13, 2025

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: expense.isRecurring ? const Icon(Icons.repeat, color: Colors.blue) : null, // Recurring Icon
        title: Text(
          expense.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display start date (or transaction date for one-time)
            if (expense.startDate != null)
              Text('Date: ${formatter.format(expense.startDate!)}'),
            // Show recurring info if applicable
            if (expense.isRecurring)
              Text(
                'Recurring: ${expense.recurringFrequency ?? 'Yes'}${expense.endDate != null ? ' until ${formatter.format(expense.endDate!)}' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
          ],
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount Chip
            Chip(
              label: Text(
                '\$${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorDark, // Darker color for contrast
                ),
              ),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact, // Make chip smaller
            ),
            const SizedBox(width: 4), // Space before buttons
            // Edit Button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
              onPressed: () => _showExpenseDialog(category, vm, existingExpense: expense),
              tooltip: 'Edit Expense',
              visualDensity: VisualDensity.compact, // Make button smaller
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(expense, vm), // Pass VM directly
              tooltip: 'Delete Expense',
              visualDensity: VisualDensity.compact, // Make button smaller
            ),
          ],
        ),
        // isThreeLine: expense.isRecurring && expense.startDate != null, // Adjust height if subtitle is long
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    );
  }

  Widget _buildActionButtons(ExpenseCategory category, ExpenseViewModel vm) {
    // Calculate category total directly from the category object if it has the method
    // final categoryTotal = category.categoryTotal;
    // Or calculate here:
    final categoryTotal = category.expenses.fold<double>(
        0, (sum, expense) => sum + expense.amount
    );


    // Get the calculated current month total from the ViewModel
    final double currentMonthTotal = vm.currentMonthTotalExpenses;

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showExpenseDialog(category, vm),
          icon: const Icon(Icons.add),
          label: const Text('Add Expense to This Category'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50), // Make button taller
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16), // More space
        // Display Category Total
        ListTile(
          leading: const Icon(Icons.pie_chart_outline, color: Colors.orange),
          title: const Text('Category Total'),
          trailing: Text(
            '\$${categoryTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          dense: true,
          tileColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(height: 8),
        // Display Calculated Current Month Total
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined, color: Colors.green),
          title: const Text('Current Month Total (All Cats)'),
          trailing: Text(
            '\$${currentMonthTotal.toStringAsFixed(2)}', // Use calculated value
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          dense: true,
          tileColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(ExpenseViewModel vm) {
    // Check if there are *any* expenses across *all* categories
    final bool hasAnyExpenses = vm.expenseCategories.any((c) => c.expenses.isNotEmpty);

    return BottomAppBar(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            if (_currentPageIndex > 0)
              TextButton.icon(
                onPressed: () => setState(() => _currentPageIndex--),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              )
            else
              const SizedBox(width: 100), // Placeholder to balance layout

            const Spacer(), // Pushes buttons to edges

            // Next Button (if not last category)
            if (_currentPageIndex < vm.expenseCategories.length - 1)
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentPageIndex++),
                label: const Text('Next'),
                icon: const Icon(Icons.arrow_forward),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
              ),
            // Finish Button (if on last category)
            if (_currentPageIndex == vm.expenseCategories.length - 1)
              ElevatedButton(
                onPressed: hasAnyExpenses ? widget.onNext : _showEmptyWarning,
                style: ElevatedButton.styleFrom(
                    backgroundColor: hasAnyExpenses ? Colors.green : Colors.grey, // Conditional color
                    padding: const EdgeInsets.symmetric(horizontal: 16)
                ),
                child: const Text('Finish Setup'), // Or "Done", "Confirm" etc.
              ),
            // Placeholder if only one category and it's the last
            if (vm.expenseCategories.length == 1 && _currentPageIndex == 0 && !hasAnyExpenses)
              const SizedBox(width: 100), // Ensure Finish button is still pushed right


          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _showExpenseDialog(ExpenseCategory category, ExpenseViewModel vm, {Expense? existingExpense}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingExpense?.name ?? '');
    final amountController = TextEditingController(
        text: existingExpense?.amount.toStringAsFixed(2) ?? ''
    );

    // --- State variables for recurring fields within the dialog ---
    bool isRecurring = existingExpense?.isRecurring ?? false;
    DateTime? startDate = existingExpense?.startDate ?? DateTime.now(); // Default to now
    DateTime? endDate = existingExpense?.endDate; // Nullable
    String? recurringFrequency = existingExpense?.recurringFrequency ?? 'monthly'; // Default freq
    final List<String> frequencyOptions = ['monthly', 'weekly', 'yearly', 'daily']; // Example options
    // --- End state variables ---

    showDialog(
      context: context,
      // Use StatefulBuilder to manage state within the dialog
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {

          // Helper function to pick date
          Future<DateTime?> _pickDate(DateTime initialDate) async {
            return await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(2000), // Adjust range as needed
              lastDate: DateTime(2101),
            );
          }

          // Date Format for display
          final DateFormat formatter = DateFormat('MMM d, yyyy');

          return AlertDialog(
            title: Text(existingExpense == null ? 'Add Expense' : 'Edit Expense'),
            content: SingleChildScrollView( // Make content scrollable
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Take minimum height
                  children: [
                    // Expense Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Expense Name', border: OutlineInputBorder()),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    // Amount
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ ', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final amount = double.tryParse(value!);
                        if (amount == null) return 'Invalid amount';
                        if (amount <= 0) return 'Must be positive';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Recurring Section ---
                    CheckboxListTile(
                      title: const Text('Recurring Expense'),
                      value: isRecurring,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          isRecurring = value ?? false;
                          // Reset dates/freq if unchecked? Optional.
                          // if (!isRecurring) {
                          //   endDate = null;
                          //   recurringFrequency = 'monthly';
                          // }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Show recurring options only if checked
                    if (isRecurring) ...[
                      const SizedBox(height: 8),
                      // Start Date Picker
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Start Date'),
                        subtitle: Text(startDate != null ? formatter.format(startDate!) : 'Select Date'),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () async {
                          final pickedDate = await _pickDate(startDate ?? DateTime.now());
                          if (pickedDate != null) {
                            setDialogState(() {
                              startDate = pickedDate;
                              // Ensure end date is after start date if both exist
                              if (endDate != null && endDate!.isBefore(startDate!)) {
                                endDate = null; // Reset end date
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('End date reset (must be after start date)'), duration: Duration(seconds: 2)),
                                );
                              }
                            });
                          }
                        },
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),

                      // End Date Picker (Optional)
                      ListTile(
                        leading: const Icon(Icons.event_busy),
                        title: const Text('End Date (Optional)'),
                        subtitle: Text(endDate != null ? formatter.format(endDate!) : 'Runs indefinitely'),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () async {
                          final pickedDate = await _pickDate(endDate ?? startDate ?? DateTime.now());
                          if (pickedDate != null) {
                            if (startDate != null && pickedDate.isBefore(startDate!)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('End date must be on or after start date'), duration: Duration(seconds: 2)),
                              );
                            } else {
                              setDialogState(() => endDate = pickedDate);
                            }
                          }
                        },
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      // Button to clear End Date
                      if (endDate != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: const Text('Clear End Date'),
                            onPressed: () => setDialogState(() => endDate = null),
                          ),
                        ),

                      // Frequency Dropdown
                      DropdownButtonFormField<String>(
                        value: recurringFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: frequencyOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value[0].toUpperCase() + value.substring(1)), // Capitalize
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() => recurringFrequency = newValue);
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                    ], // End recurring options
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    // Additional validation for recurring fields if needed
                    if (isRecurring && startDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Start Date is required for recurring expenses'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final newExpense = Expense(
                      id: existingExpense?.id, // Keep existing ID for updates
                      userId: existingExpense?.userId, // Keep existing user ID
                      categoryId: category.id,
                      name: nameController.text.trim(),
                      amount: double.parse(amountController.text),
                      // --- Assign recurring values ---
                      isRecurring: isRecurring,
                      startDate: isRecurring ? startDate : startDate, // Assign startDate even if not recurring (as transaction date)
                      endDate: isRecurring ? endDate : null, // Only set end date if recurring
                      recurringFrequency: isRecurring ? recurringFrequency : null, // Only set frequency if recurring
                    );

                    Navigator.pop(context); // Close dialog first

                    // --- Call ViewModel ---
                    try {
                      if (existingExpense == null) {
                        await vm.addExpense(newExpense);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expense added successfully'), duration: Duration(seconds: 2)),
                        );
                      } else {
                        await vm.updateExpense(newExpense);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expense updated successfully'), duration: Duration(seconds: 2)),
                        );
                      }
                    } catch (e) {
                      // Show error SnackBar if mounted check passes
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(existingExpense == null ? 'Add' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _confirmDelete(Expense expense, ExpenseViewModel vm) async {
    // Use the context available in the state class
    if (!mounted) return;

    return showDialog(
      context: context, // Use the valid context
      builder: (dialogContext) => AlertDialog( // Use different context name for builder
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Use dialogContext
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first
              try {
                await vm.removeExpense(expense);
                // Check mount status again before showing SnackBar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense deleted'), duration: Duration(seconds: 2)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error), // Use theme error color
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}