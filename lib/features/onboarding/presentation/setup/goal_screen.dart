import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/utils/app_localization.dart';
import 'bmi_result_screen.dart';

class GoalScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const GoalScreen({super.key, required this.profileData});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _profileService = ProfileService();
  int selectedIndex = 1;
  bool _isLoading = false;

  Future<void> _calculateAndSave() async {
    setState(() => _isLoading = true);

    try {
      widget.profileData['goal'] = selectedIndex;

      final result = await _profileService.calculateAndSaveProfile(widget.profileData, selectedIndex);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => BmiResultScreen(
                bmi: result['bmi'],
                tdee: result['tdee'],
                age: result['age'],
                profileData: widget.profileData,
              )
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> goals = [
      {'title': tr('lose_weight'), 'desc': tr('lose_weight_desc'), 'icon': Icons.arrow_downward_rounded, 'iconColor': Colors.blue, 'lightBg': Colors.blue.shade50, 'darkBg': const Color(0xFF0C4A6E)},
      {'title': tr('maintain_weight'), 'desc': tr('maintain_weight_desc'), 'icon': Icons.check_rounded, 'iconColor': AppTheme.brandPrimary, 'lightBg': const Color(0xFFDCFCE7), 'darkBg': const Color(0xFF064E3B)},
      {'title': tr('gain_muscle'), 'desc': tr('gain_muscle_desc'), 'icon': Icons.arrow_upward_rounded, 'iconColor': Colors.orange, 'lightBg': Colors.orange.shade50, 'darkBg': const Color(0xFF78350F)},
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
                    _buildProgressBar('3/3', 1.0, isDark),
                    const SizedBox(height: 24),
                    Text(tr('your_goal'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                    const SizedBox(height: 4),
                    Text(tr('what_achieve'), style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 32),

                    Expanded(
                      child: ListView.separated(
                        itemCount: goals.length,
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: isDark ? goals[index]['darkBg'] : goals[index]['lightBg'], borderRadius: BorderRadius.circular(12)),
                                    child: Icon(goals[index]['icon'], color: goals[index]['iconColor']),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(goals[index]['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.displayLarge?.color)),
                                        const SizedBox(height: 2),
                                        Text(goals[index]['desc'], style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                                      ],
                                    ),
                                  )
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
                        onPressed: _isLoading ? null : _calculateAndSave,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(tr('calculate_plan'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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