import 'package:aullet/repositories/category_repository.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:aullet/models/category.dart';

class CategoryViewModel extends ChangeNotifier{
  final _repo = CategoryRepository();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    _setLoading(true);
    try {
      _categories = await _repo.fetchAll();
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