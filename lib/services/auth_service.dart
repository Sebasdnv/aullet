import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  //* registrazione
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signUp(email: email ,password: password);
  }

  //* login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(email: email ,password: password);
  }

  //* logout
  Future<void> signOut() {
    return _supabase.auth.signOut();
  }

  //* ritorna il dato dell'utente loggatto o null se non loggato
  User? get currentUser => _supabase.auth.currentUser;
}