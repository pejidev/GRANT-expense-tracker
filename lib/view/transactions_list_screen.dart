import 'package:flutter/material.dart';
import '../viewmodel/transaction_viewmodel.dart';
import '../model/transaction_model.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final TransactionViewModel _viewModel = TransactionViewModel();
  late Future<List<TransactionModel>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _viewModel.fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transactions')),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No transactions found'));
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    transaction.type == 'income'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color:
                        transaction.type == 'income'
                            ? Colors.green
                            : Colors.red,
                  ),
                  title: Text(
                    'P${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${transaction.description ?? 'No description'}\n${transaction.date.toLocal().toString().split(' ')[0]}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
