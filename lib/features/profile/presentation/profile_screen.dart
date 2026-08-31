import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/profile_service.dart';
import 'edit_profile_screen.dart';
import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  final int updateToken;

  const ProfileScreen({super.key, this.onDataChanged, this.updateToken = 0});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updateToken != oldWidget.updateToken) {
      _fetchProfileData(isSilent: false);
    }
  }

  Future<void> _fetchProfileData({bool isSilent = false}) async {
    if (!isSilent) setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) _email = user.email ?? '';

      final data = await _profileService.fetchProfileData();
      if (mounted) setState(() => _profileData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${tr('failed')}: Check your internet connection'),
                backgroundColor: Colors.red
            )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return '-';
    try {
      DateTime dob = DateTime.parse(dobString);
      int age = DateTime.now().year - dob.year;
      return age.toString();
    } catch (e) {
      return '-';
    }
  }

  String _calculateBMI(double? weight, double? height) {
    if (weight == null || height == null || height == 0) return '-';
    double heightM = height / 100;
    double bmi = weight / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  String _getBmiStatus(double? weight, double? height) {
    if (weight == null || height == null || height == 0) return tr('unknown');
    double bmi = weight / ((height / 100) * (height / 100));
    if (bmi < 18.5) return tr('underweight');
    if (bmi < 24.9) return tr('normal_weight');
    if (bmi < 29.9) return tr('overweight');
    return tr('obesity');
  }

  String _getActivityLevelText(int? level) {
    switch (level) {
      case 0: return tr('sedentary');
      case 1: return tr('lightly_active');
      case 2: return tr('moderate_active');
      case 3: return tr('very_active');
      default: return tr('unknown');
    }
  }

  String _getGoalText(int? goal) {
    switch (goal) {
      case 0: return tr('lose_weight');
      case 1: return tr('maintain_weight');
      case 2: return tr('gain_muscle');
      default: return tr('unknown');
    }
  }

  BoxDecoration _getSemiTransparentDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildSkeletonLoader(isDark),
      );
    }

    final String name = _profileData?['full_name'] ?? 'User';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final double? weight = _profileData?['weight_kg'] != null ? (_profileData!['weight_kg'] as num).toDouble() : null;
    final double? height = _profileData?['height_cm'] != null ? (_profileData!['height_cm'] as num).toDouble() : null;
    final int? tdee = _profileData?['tdee_target'];
    final int? activity = _profileData?['activity_level'];
    final int? goal = _profileData?['goal'];

    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 16.0),
                    child: Text(tr('profile'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _fetchProfileData(isSilent: true),
                      color: AppTheme.brandPrimary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 8.0, bottom: 100.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: isDark
                                        ? [const Color(0xFF1E293B).withOpacity(0.8), const Color(0xFF0F172A).withOpacity(0.8)]
                                        : [const Color(0xFFF0FDF4).withOpacity(0.8), Colors.white.withOpacity(0.8)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80, height: 80,
                                    decoration: const BoxDecoration(color: AppTheme.brandPrimary, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text(initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                                  const SizedBox(height: 4),
                                  Text(_email, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                                  const SizedBox(height: 24),

                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                        color: isDark ? Colors.black26 : const Color(0xFFE6F4EA).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16)
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildQuickStat(_calculateAge(_profileData?['dob']), tr('age'), theme),
                                        Container(width: 1, height: 30, color: isDark ? Colors.grey.shade700 : Colors.green.shade200),
                                        _buildQuickStat(weight?.toStringAsFixed(0) ?? '-', tr('kg'), theme, valueColor: AppTheme.brandPrimary),
                                        Container(width: 1, height: 30, color: isDark ? Colors.grey.shade700 : Colors.green.shade200),
                                        _buildQuickStat(height?.toStringAsFixed(0) ?? '-', tr('cm'), theme),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text(tr('body_metrics'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                            const SizedBox(height: 16),
                            _buildMetricTile('BMI', _calculateBMI(weight, height), _getBmiStatus(weight, height), isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7), AppTheme.brandPrimary, theme, isDark),
                            const SizedBox(height: 12),
                            _buildMetricTile('TDEE', '${tdee ?? '-'} kcal', tr('daily_target'), isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7), Colors.orange, theme, isDark),
                            const SizedBox(height: 12),
                            _buildMetricTileIcon(Icons.show_chart_rounded, _getActivityLevelText(activity), tr('activity_level'), isDark ? const Color(0xFF4C1D95) : const Color(0xFFF3E8FF), Colors.purpleAccent, theme, isDark),
                            const SizedBox(height: 12),
                            _buildMetricTileIcon(Icons.bolt_rounded, _getGoalText(goal), tr('current_goal'), isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE), Colors.lightBlue, theme, isDark),
                            const SizedBox(height: 32),

                            // ==========================================
                            // 1. ACCOUNT SECTION (Dipindah ke atas)
                            // ==========================================
                            Text(tr('account'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color, letterSpacing: 1.2)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                                if (result == true) {
                                  _fetchProfileData(isSilent: false);
                                  widget.onDataChanged?.call();
                                } else {
                                  _fetchProfileData(isSilent: true);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _getSemiTransparentDecoration(theme, isDark),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(12)
                                      ),
                                      child: const Icon(Icons.manage_accounts_outlined, color: AppTheme.brandPrimary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tr('edit_profile'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
                                          const SizedBox(height: 2),
                                          Text(tr('edit_profile_desc'), style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ==========================================
                            // 2. APP SETTINGS SECTION (Dipindah ke bawah)
                            // ==========================================
                            Text(tr('app_settings'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color, letterSpacing: 1.2)),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: _getSemiTransparentDecoration(theme, isDark),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: isDark ? Colors.black26 : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(
                                      themeProvider.themeMode == ThemeMode.system
                                          ? Icons.brightness_auto_rounded
                                          : (themeProvider.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                                      color: isDark ? Colors.amber : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(tr('app_theme'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
                                        const SizedBox(height: 2),
                                        Text(tr('theme_desc'), style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                                      ],
                                    ),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<ThemeMode>(
                                      value: themeProvider.themeMode,
                                      dropdownColor: theme.cardColor,
                                      icon: Icon(Icons.expand_more_rounded, color: theme.textTheme.bodyMedium?.color),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                                      items: [
                                        DropdownMenuItem(value: ThemeMode.system, child: Text(tr('system'))),
                                        DropdownMenuItem(value: ThemeMode.light, child: Text(tr('light'))),
                                        DropdownMenuItem(value: ThemeMode.dark, child: Text(tr('dark'))),
                                      ],
                                      onChanged: (ThemeMode? newMode) {
                                        if (newMode != null) themeProvider.setThemeMode(newMode);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: _getSemiTransparentDecoration(theme, isDark),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: isDark ? Colors.black26 : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.language_rounded, color: Colors.blueAccent),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(tr('language'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: AppLocalizations.currentLocale.value,
                                      dropdownColor: theme.cardColor,
                                      icon: Icon(Icons.expand_more_rounded, color: theme.textTheme.bodyMedium?.color),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                                      items: [
                                        DropdownMenuItem(value: 'en', child: Text(tr('english'))),
                                        DropdownMenuItem(value: 'id', child: Text(tr('indonesian'))),
                                      ],
                                      onChanged: (String? newLang) {
                                        if (newLang != null) {
                                          AppLocalizations.changeLocale(newLang);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ==========================================
                            // LOGOUT BUTTON
                            // ==========================================
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () => _showLogoutConfirmation(context),
                                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                                label: Text(tr('logout'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: isDark ? Colors.red.withOpacity(0.5) : const Color(0xFFEF4444)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFEF2F2).withOpacity(0.8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    Color skeletonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, height: 250, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 32),
          Container(width: 120, height: 16, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 32),
          Container(width: 100, height: 12, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20))),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(tr('logout_confirm_title'), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: Text(tr('logout_confirm_desc'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: Text(tr('logout'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStat(String value, String label, ThemeData theme, {Color? valueColor}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor ?? theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)),
      ],
    );
  }

  Widget _buildMetricTile(String iconText, String title, String subtitle, Color bgColor, Color textColor, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getSemiTransparentDecoration(theme, isDark),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(iconText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetricTileIcon(IconData icon, String title, String subtitle, Color bgColor, Color iconColor, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getSemiTransparentDecoration(theme, isDark),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
            ],
          )
        ],
      ),
    );
  }
}