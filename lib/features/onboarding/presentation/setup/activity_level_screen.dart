import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'goal_screen.dart';

class ActivityLevelScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ActivityLevelScreen({super.key, required this.profileData});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  int selectedIndex = 2;

  final List<Map<String, String>> levels = [
    {'title': 'Sedentary', 'desc': 'Desk job, little to no exercise'},
    {'title': 'Light Active', 'desc': 'Light exercise 1-3 days/week'},
    {'title': 'Moderate Active', 'desc': 'Moderate exercise 3-5 days/week'},
    {'title': 'Very Active', 'desc': 'Hard exercise 6-7 days/week'},
  ];

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PERBAIKAN: Pemanggilan dengan 3 argumen yang sesuai
              _buildProgressBar('2/3', 0.66, isDark),
              const SizedBox(height: 24),
              Text('Activity Level', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
              const SizedBox(height: 4),
              Text('How active are you daily?', style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
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
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Definisi Fungsi dengan 3 parameter
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