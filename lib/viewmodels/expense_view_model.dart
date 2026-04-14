import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final _repo = ExpenseRepository();
  List<Expense> _expenses = [];
  String? _error;
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadExpenses() async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _expenses = await _repo.fetchExpenses(user.id);
      }
    } catch (e) {
      debugPrint("Errore Load: $e");
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addExpense(Expense expense) async {
    _setLoading(true);
    try {
      await _repo.insertExpense(expense);
      await loadExpenses(); 
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExpense(Expense exp) async {
    _setLoading(true);
    _error = null;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utente non autenticato');
      
      await _repo.updateExpense(exp);
      
      _expenses = await _repo.fetchExpenses(user.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExpense(String id) async {
    _setLoading(true);
    _error = null;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utente non autenticato');

      await _repo.deleteExpense(id);
      _expenses = await _repo.fetchExpenses(user.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    if (v) _error = null;
    notifyListeners();
  }
}