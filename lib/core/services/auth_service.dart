import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Mendengarkan perubahan status otentikasi (login/logout/reset)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Fungsi Login dengan Email & Password
  Future<void> signInWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Fungsi Register (Daftar) dengan Email, Password, & Nama
  Future<void> signUpWithEmail(String email, String password, String name) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  // Fungsi Login / Register menggunakan Akun Google
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.caltrack://login-callback/',
      queryParams: {'prompt': 'select_account'},
    );
  }

  // Fungsi Kirim Link Reset Password ke Email
  Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.caltrack://reset-callback/',
    );
  }

  // Fungsi Perbarui Kata Sandi Baru
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Fungsi Logout (Keluar)
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}