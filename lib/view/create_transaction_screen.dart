import 'package:flutter/material.dart';
import '../viewmodel/transaction_viewmodel.dart';
import '../model/transaction_model.dart';

class CreateTransactionScreen extends StatefulWidget {
  const CreateTransactionScreen({super.key});

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Expense'; // Default type
  final TransactionViewModel _viewModel = TransactionViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Transaction'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Text(
            'New Transaction',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Color(0xFF6200EE)),
                helperText: 'Enter transaction amount',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30),
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              items:
                  ['Income', 'Expense']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Transaction Type',
                labelStyle: TextStyle(color: Color(0xFF6200EE)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Select Date',
                labelStyle: TextStyle(color: Color(0xFF6200EE)),
                helperText: 'Pick transaction date',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
              readOnly: true,
              onTap: () {
                _selectDate();
              },
            ),
          ),
          SizedBox(height: 16),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30),
            child: TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: Color(0xFF6200EE)),
                helperText: 'Add transaction details',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(onPressed: _saveTransaction, child: Icon(Icons.check)),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = pickedDate.toString().split(" ")[0];
      });
    }
  }

  void _saveTransaction() {
    if (_amountController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all required fields')),
      );
      return;
    }

    final newTransaction = TransactionModel(
      type: _selectedType.toLowerCase(),
      amount: double.parse(_amountController.text),
      date: DateTime.parse(_dateController.text),
      description: _descriptionController.text,
      categoryId: null,
      fromAccountId: null,
      toAccountId: null,
    );

    _viewModel
        .addTransaction(newTransaction)
        .then((_) {
          Navigator.pop(context);
        })
        .catchError((error) {
          print('$error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving transaction: $error')),
          );
        });
  }
}
