import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_localization.dart';
import 'goal_screen.dart';

class ActivityLevelScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ActivityLevelScreen({super.key, required this.profileData});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  int selectedIndex = 2;

  void _continueToGoal() {
    widget.profileData['activity_level'] = selectedIndex;

    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GoalScreen(profileData: widget.profileData))
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Memindahkan list ke dalam build agar reaktif terhadap perubahan bahasa
    final List<Map<String, String>> levels = [
      {'title': tr('sedentary'), 'desc': tr('sedentary_desc')},
      {'title': tr('lightly_active'), 'desc': tr('light_active_desc')},
      {'title': tr('moderate_active'), 'desc': tr('moderate_active_desc')},
      {'title': tr('very_active'), 'desc': tr('very_active_desc')},
    ];

    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar('2/3', 0.66, isDark),
                    const SizedBox(height: 24),
                    Text(tr('activity_level'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                    const SizedBox(height: 4),
                    Text(tr('how_active'), style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 32),

                    Expanded(
                      child: ListView.separated(
                        itemCount: levels.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          bool isSelected = selectedIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => selectedIndex = index),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4)) : theme.cardColor,
                                border: Border.all(color: isSelected ? AppTheme.brandPrimary : theme.dividerColor, width: isSelected ? 1.5 : 1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(levels[index]['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.displayLarge?.color)),
                                  const SizedBox(height: 4),
                                  Text(levels[index]['desc']!, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _continueToGoal,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: Text(tr('continue_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildProgressBar(String step, double progress, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8)
          ),
          child: Text(step, style: const TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                color: AppTheme.brandPrimary
            ),
          ),
        ),
      ],
    );
  }
}