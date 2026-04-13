import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final _client = Supabase.instance.client;

  Future<void> insertExpense(Expense exp) async {
    await _client
        .from('expenses')
        .insert(exp.toMap());
  }

  Future<List<Expense>> fetchExpenses() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('expenses')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false);

    return (data as List<dynamic>).map((e) => Expense.fromMap(e)).toList();
  }
}