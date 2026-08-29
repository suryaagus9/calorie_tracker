import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/auth_service.dart';
import '../../onboarding/presentation/setup/personal_info_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late final StreamSubscription<AuthState> _authSubscription;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    // Gunakan listener dari AuthService
    _authSubscription = _authService.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()), (route) => false);
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showErrorAlert(String message, {bool isNetworkError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isNetworkError ? Icons.wifi_off : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _signUp() async {
    setState(() { _nameError = null; _emailError = null; _passwordError = null; _confirmError = null; });

    bool hasError = false;
    String nameText = _nameCtrl.text.trim();
    String emailText = _emailCtrl.text.trim();
    String passwordText = _passwordCtrl.text;
    String confirmText = _confirmCtrl.text;

    if (nameText.isEmpty) { _nameError = tr('name_required'); hasError = true; }
    if (emailText.isEmpty) { _emailError = tr('email_required'); hasError = true; }
    else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailText)) { _emailError = tr('invalid_email'); hasError = true; }
    if (passwordText.isEmpty) { _passwordError = tr('password_required'); hasError = true; }
    else if (passwordText.length < 6) { _passwordError = tr('password_min_length'); hasError = true; }
    if (confirmText.isEmpty) { _confirmError = tr('confirm_password_required'); hasError = true; }
    else if (confirmText != passwordText) { _confirmError = tr('passwords_not_match'); hasError = true; }

    if (hasError) { setState(() {}); return; }

    setState(() => _isLoading = true);

    try {
      // PANGGIL AUTH SERVICE
      await _authService.signUpWithEmail(emailText, passwordText, nameText);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || errorMessage.contains('Failed host lookup')) {
        _showErrorAlert(tr('no_internet'), isNetworkError: true);
      } else if (errorMessage.contains('User already registered')) {
        _showErrorAlert(tr('email_already_registered'));
      } else {
        _showErrorAlert('${tr('signup_failed')} ${errorMessage.split('] ').last}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    try {
      // PANGGIL AUTH SERVICE
      await _authService.signInWithGoogle();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || errorMessage.contains('Failed host lookup')) {
        _showErrorAlert(tr('no_internet'), isNetworkError: true);
      } else {
        _showErrorAlert('${tr('signup_failed')} ${errorMessage.split('] ').last}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(width: 8),
                          Text(tr('back'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(tr('create_account'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text(tr('start_tracking'), style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 32),

                    _buildInputLabel(tr('full_name'), theme),
                    _buildTextField(hintText: tr('your_name'), isPassword: false, controller: _nameCtrl, errorText: _nameError, theme: theme),
                    const SizedBox(height: 16),

                    _buildInputLabel(tr('email'), theme),
                    _buildTextField(hintText: 'example@email.com', isPassword: false, controller: _emailCtrl, errorText: _emailError, theme: theme),
                    const SizedBox(height: 16),

                    _buildInputLabel(tr('password'), theme),
                    _buildTextField(hintText: tr('password'), isPassword: true, controller: _passwordCtrl, errorText: _passwordError, theme: theme),
                    const SizedBox(height: 16),

                    _buildInputLabel(tr('confirm_password'), theme),
                    _buildTextField(hintText: tr('password'), isPassword: true, controller: _confirmCtrl, errorText: _confirmError, theme: theme),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(tr('create_account'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.dividerColor, thickness: 1)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(tr('or'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))),
                        Expanded(child: Divider(color: theme.dividerColor, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: OutlinedButton(
                        onPressed: _signUpWithGoogle,
                        style: OutlinedButton.styleFrom(side: BorderSide(color: theme.dividerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            const SizedBox(width: 12),
                            Text(tr('signup_google'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildInputLabel(String label, ThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)));
  }

  Widget _buildTextField({required String hintText, required bool isPassword, required TextEditingController controller, String? errorText, required ThemeData theme}) {
    return TextField(
      controller: controller, obscureText: isPassword, style: TextStyle(color: theme.textTheme.displayLarge?.color, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText, hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14), errorText: errorText,
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true, fillColor: theme.cardColor,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandPrimary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
      ),
    );
  }
}