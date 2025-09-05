import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/transaction_model.dart';

class TransactionViewModel {
  final _supabase = Supabase.instance.client;

  // Fetch transactions
  // Fetch transactions from Supabase
  Future<List<TransactionModel>> fetchTransactions() async {
    final response = await _supabase
        .from('transactions')
        .select()
        .order('date', ascending: false); // Order by latest transactions

    return response.map((data) => TransactionModel.fromMap(data)).toList();
  }

  // Add transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _supabase.from('transactions').insert(transaction.toMap());
  }
}
