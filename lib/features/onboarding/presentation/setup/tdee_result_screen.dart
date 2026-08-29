import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
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

  // FUNGSI PENGAMAN: Mencegah error jika data yang masuk berupa String atau Double
  int _parseSafeInt(dynamic val, int defaultVal) {
    if (val == null) return defaultVal;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userMeta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final String name = userMeta?['full_name'] ?? 'User';

    final String gender = profileData['gender']?.toString() ?? 'Male';

    // PERBAIKAN: Menggunakan pengurai yang aman
    final int activityInt = _parseSafeInt(profileData['activity_level'], 1);
    final int goalInt = _parseSafeInt(profileData['goal'], 1);

    String activityStr = 'Sedentary';
    if (activityInt == 1) activityStr = 'Lightly Active';
    if (activityInt == 2) activityStr = 'Moderate Active';
    if (activityInt == 3) activityStr = 'Very Active';

    String goalStr = 'Maintain Weight';
    if (goalInt == 0) goalStr = 'Lose Weight';
    if (goalInt == 2) goalStr = 'Gain Muscle';

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
                    const Text('Daily Calorie Target', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
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
                            const Text('For Weight Loss', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('$lossTdee kcal', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('For Bulking', style: TextStyle(color: Colors.white70, fontSize: 11)),
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

              _buildSummaryTile(Icons.person_outline, isDark ? const Color(0xFF064E3B) : AppTheme.brandLight, AppTheme.brandPrimary, name, '$age years, $gender', theme),
              const SizedBox(height: 12),
              _buildSummaryTile(Icons.show_chart_rounded, isDark ? const Color(0xFF4C1D95) : const Color(0xFFF3E8FF), Colors.purpleAccent, activityStr, 'Activity Level', theme),
              const SizedBox(height: 12),
              _buildSummaryTile(Icons.bolt_rounded, isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE), Colors.lightBlue, goalStr, 'Current goal', theme),

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
                  child: const Text('Go to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
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