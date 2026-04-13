import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final _repo = ExpenseRepository();
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenses = await _repo.fetchExpenses();
    } catch (e) {
      debugPrint("Errore: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.insertExpense(expense);
    } catch (e) {
      debugPrint("Errore: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}