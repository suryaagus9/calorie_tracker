import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../dashboard/presentation/main_navigation.dart';

class TdeeResultScreen extends StatelessWidget {
  final int tdee;
  final int age;
  final Map<String, dynamic> profileData;

  const TdeeResultScreen({
    super.key,
    required this.tdee,
    required this.age,
    required this.profileData,
  });

  int _parseSafeInt(dynamic val, int defaultVal) {
    if (val == null) return defaultVal;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          final userMeta = Supabase.instance.client.auth.currentUser?.userMetadata;
          final String name = userMeta?['full_name'] ?? 'User';

          final String gender = profileData['gender']?.toString() ?? 'Male';

          final int activityInt = _parseSafeInt(profileData['activity_level'], 1);
          final int goalInt = _parseSafeInt(profileData['goal'], 1);

          String activityStr = tr('sedentary');
          if (activityInt == 1) activityStr = tr('lightly_active');
          if (activityInt == 2) activityStr = tr('moderate_active');
          if (activityInt == 3) activityStr = tr('very_active');

          String goalStr = tr('maintain_weight');
          if (goalInt == 0) goalStr = tr('lose_weight');
          if (goalInt == 2) goalStr = tr('gain_muscle');

          int baseTdee = tdee;
          if (goalInt == 0) baseTdee = tdee + 500;
          if (goalInt == 2) baseTdee = tdee - 500;

          int lossTdee = baseTdee - 500;
          int bulkTdee = baseTdee + 500;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.brandPrimary, AppTheme.brandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppTheme.brandPrimary.withOpacity(isDark ? 0.1 : 0.3), blurRadius: 16, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('daily_calorie_target'), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(tdee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
                              const SizedBox(width: 8),
                              const Text('kcal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('for_weight_loss'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text('$lossTdee kcal', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('for_bulking'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text('$bulkTdee kcal', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSummaryTile(Icons.person_outline, isDark ? const Color(0xFF064E3B) : AppTheme.brandLight, AppTheme.brandPrimary, name, '$age ${tr('years')}, ${tr(gender.toLowerCase())}', theme),
                    const SizedBox(height: 12),
                    _buildSummaryTile(Icons.show_chart_rounded, isDark ? const Color(0xFF4C1D95) : const Color(0xFFF3E8FF), Colors.purpleAccent, activityStr, tr('activity_level'), theme),
                    const SizedBox(height: 12),
                    _buildSummaryTile(Icons.bolt_rounded, isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE), Colors.lightBlue, goalStr, tr('current_goal'), theme),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MainNavigation()),
                                (route) => false
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: Text(tr('go_to_dashboard'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildSummaryTile(IconData icon, Color bgIconColor, Color iconColor, String title, String subtitle, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.displayLarge?.color)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
            ],
          )
        ],
      ),
    );
  }
}