import 'package:aullet/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool _isLoggedIn = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _isLoggedIn;

  AuthViewModel(){
    checkCurrentUser();
  }

  void checkCurrentUser() {
    _isLoggedIn = _authService.currentUser != null;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      _errorMessage = null;
      await _authService.signUp(email: email, password: password);
      _isLoggedIn = true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      _errorMessage = null;
      await _authService.signIn(email: email, password: password);
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }

  void _setLoading(bool value){
    _isLoading = value;
    if(value) _errorMessage = null;
    notifyListeners();
  }
}
