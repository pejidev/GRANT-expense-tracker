import 'package:flutter/material.dart';

class EditBudgetScreen extends StatefulWidget {
  final String budgetAmount;
  const EditBudgetScreen({super.key, required this.budgetAmount});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  late TextEditingController _budgetAmountController;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _budgetAmountController = TextEditingController(text: widget.budgetAmount);
  }

  @override
  void dispose() {
    _budgetAmountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GRANT'), backgroundColor: Colors.blue),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Edit Budget',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              controller: _budgetAmountController,
              decoration: const InputDecoration(
                labelText: 'Budget',
                labelStyle: TextStyle(color: Color(0xFF6200EE)),
                helperText: 'Enter your budget',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Select date',
                labelStyle: TextStyle(color: Color(0xFF6200EE)),
                helperText: 'Set budget timeframe',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
              readOnly: true,
              onTap: _selectDate,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'budgetAmount': _budgetAmountController.text,
                'date': _dateController.text,
              });
            },
            child: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? _picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (_picked != null) {
      setState(() {
        _dateController.text = _picked.toString().split(" ")[0];
      });
    }
  }
}
