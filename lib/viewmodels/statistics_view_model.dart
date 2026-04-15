import 'package:aullet/models/category.dart';
import 'package:aullet/models/expense.dart';
import 'package:aullet/repositories/expense_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsViewModel extends ChangeNotifier{
  final _repo = ExpenseRepository();
  List<Expense> _allExpenses = [];
  List<Category> _allCategories = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _monthFilter;

  List<Expense> get allExpenses => _allExpenses;
  List<Category> get allCategories => _allCategories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get monthFilter => _monthFilter;

  set monthFilter(int? val) {
    _monthFilter = val;
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if(user == null) throw Exception('Utente non autenticato');
      _allExpenses = await _repo.fetchExpenses(user.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Map<Category, double> calculatedExpensesByCategory(int year) {
    final Map<String, double> temp = {};
    for (final exp in _allExpenses) {
      if(exp.date.year == year &&
      (_monthFilter == null || exp.date.month == monthFilter)) {
        temp.update(exp.categoryId, (v) => v + exp.amount, ifAbsent: () => exp.amount);
      }
    }
    final result = <Category, double>{};
    for (final cat in _allCategories) {
      final val = temp[cat.id] ?? 0.0;
      if (val > 0) result[cat] = val;
    }
    return result;
  }

  Map<int, double> calculateMothlyExpenses(int year) {
    final Map<int, double> totals = {for (var m=1; m<=12; m++) m: 0.0};
    for(final exp in _allExpenses) {
      if (exp.date.year == year) {
        totals[exp.date.month] = totals[exp.date.month]! + exp.amount;
      }
    }
    return totals;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}