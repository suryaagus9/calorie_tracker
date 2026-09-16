import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/auth_service.dart';
import 'register_screen.dart';
import '../../dashboard/presentation/main_navigation.dart';
import '../../../core/services/profile_service.dart';
import '../../onboarding/presentation/setup/personal_info_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final StreamSubscription<AuthState> _authSubscription;

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Tambahkan kata kunci async di sini
    _authSubscription = _authService.authStateChanges.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // CEGATAN: Cek kelengkapan profil saat baru login
        final isComplete = await ProfileService().isProfileComplete();

        if (mounted) {
          if (isComplete) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavigation()), (route) => false);
          } else {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()), (route) => false);
          }
        }
      }

      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          _showUpdatePasswordDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showErrorAlert(String message, {bool isNetworkError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle_outline : (isNetworkError ? Icons.wifi_off : Icons.error_outline), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.brandPrimary : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() { _emailError = null; _passwordError = null; });

    bool hasError = false;
    String emailText = _emailCtrl.text.trim();
    String passwordText = _passwordCtrl.text;

    if (emailText.isEmpty) { _emailError = tr('email_required'); hasError = true; }
    else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailText)) { _emailError = tr('invalid_email'); hasError = true; }

    if (passwordText.isEmpty) { _passwordError = tr('password_required'); hasError = true; }

    if (hasError) { setState(() {}); return; }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmail(emailText, passwordText);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || errorMessage.contains('Failed host lookup')) {
        _showErrorAlert(tr('no_internet'), isNetworkError: true);
      } else if (errorMessage.contains('Invalid login credentials')) {
        _showErrorAlert(tr('wrong_credentials'));
      } else {
        _showErrorAlert('${tr('login_failed')} ${errorMessage.split('] ').last}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || errorMessage.contains('Failed host lookup')) {
        _showErrorAlert(tr('no_internet'), isNetworkError: true);
      } else {
        _showErrorAlert('${tr('google_signin_failed')} ${errorMessage.split('] ').last}');
      }
    }
  }

  void _showForgotPasswordDialog() {
    final theme = Theme.of(context);
    final emailResetCtrl = TextEditingController(text: _emailCtrl.text);
    bool isSending = false;

    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(tr('reset_password'), style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('reset_password_desc'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailResetCtrl,
                        style: TextStyle(color: theme.textTheme.displayLarge?.color, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'example@email.com',
                          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true, fillColor: theme.scaffoldBackgroundColor,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandPrimary, width: 2)),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: isSending ? null : () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
                    ElevatedButton(
                      onPressed: isSending ? null : () async {
                        String emailReset = emailResetCtrl.text.trim();
                        if (emailReset.isEmpty || !emailReset.contains('@')) {
                          _showErrorAlert(tr('invalid_email')); return;
                        }
                        setStateDialog(() => isSending = true);
                        try {
                          await _authService.resetPasswordForEmail(emailReset);
                          if (mounted) { Navigator.pop(ctx); _showErrorAlert(tr('reset_link_sent'), isSuccess: true); }
                        } catch (e) {
                          _showErrorAlert('${tr('failed_send_link')} ${e.toString().split('] ').last}');
                        } finally {
                          setStateDialog(() => isSending = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: isSending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(tr('send_link'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  void _showUpdatePasswordDialog() {
    final theme = Theme.of(context);
    final newPasswordCtrl = TextEditingController();
    bool isUpdating = false;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(tr('update_password'), style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('update_password_desc'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: newPasswordCtrl, obscureText: true,
                        style: TextStyle(color: theme.textTheme.displayLarge?.color, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: tr('new_password'),
                          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true, fillColor: theme.scaffoldBackgroundColor,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandPrimary, width: 2)),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: isUpdating ? null : () async {
                        String newPassword = newPasswordCtrl.text;
                        if (newPassword.length < 6) { _showErrorAlert(tr('password_min_length')); return; }
                        setStateDialog(() => isUpdating = true);
                        try {
                          await _authService.updatePassword(newPassword);
                          if (mounted) { Navigator.pop(ctx); _showErrorAlert(tr('password_updated'), isSuccess: true); }
                        } catch (e) {
                          _showErrorAlert('${tr('failed_update_password')} ${e.toString().split('] ').last}');
                        } finally {
                          setStateDialog(() => isUpdating = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(tr('update_password'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.login_rounded, color: AppTheme.brandPrimary),
                        ),
                        Container(
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.language_rounded, color: theme.textTheme.displayLarge?.color),
                            color: theme.cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (String lang) { AppLocalizations.changeLocale(lang); },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem(value: 'en', child: Text(tr('english'), style: TextStyle(color: theme.textTheme.displayLarge?.color))),
                              PopupMenuItem(value: 'id', child: Text(tr('indonesian'), style: TextStyle(color: theme.textTheme.displayLarge?.color))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(tr('sign_in'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text(tr('sign_in_continue'), style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 32),

                    _buildInputLabel(tr('email'), theme),
                    _buildTextField(hintText: 'example@email.com', isPassword: false, controller: _emailCtrl, errorText: _emailError, theme: theme),
                    const SizedBox(height: 20),

                    _buildInputLabel(tr('password'), theme),
                    _buildTextField(hintText: tr('password'), isPassword: true, controller: _passwordCtrl, errorText: _passwordError, theme: theme),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text(tr('forgot_password'), style: const TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(tr('sign_in'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        onPressed: _signInWithGoogle,
                        style: OutlinedButton.styleFrom(side: BorderSide(color: theme.dividerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(width: 12),
                            Text(tr('sign_in_google'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tr('dont_have_account'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text(tr('sign_up'), style: const TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
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