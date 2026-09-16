import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_localization.dart';
import 'tdee_result_screen.dart';

class BmiResultScreen extends StatelessWidget {
  final double bmi;
  final int tdee;
  final int age;
  final Map<String, dynamic> profileData;

  const BmiResultScreen({
    super.key,
    required this.bmi,
    required this.tdee,
    required this.age,
    required this.profileData,
  });

  Map<String, dynamic> _getBmiInfo() {
    if (bmi < 18.5) {
      return {'status': tr('underweight'), 'color': Colors.blue, 'desc': tr('bmi_underweight_desc')};
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return {'status': tr('normal_weight'), 'color': Colors.green, 'desc': tr('bmi_normal_desc')};
    } else if (bmi >= 25 && bmi <= 29.9) {
      return {'status': tr('overweight'), 'color': Colors.orange, 'desc': tr('bmi_overweight_desc')};
    } else {
      return {'status': tr('obesity'), 'color': Colors.red, 'desc': tr('bmi_obesity_desc')};
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          final theme = Theme.of(context);
          final bmiInfo = _getBmiInfo();
          final Color statusColor = bmiInfo['color'];

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    Text(tr('your_bmi_result'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                    const SizedBox(height: 8),
                    Text(tr('where_you_stand'), style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 32),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(tr('bmi_title'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                          const SizedBox(height: 16),
                          Text(bmi.toStringAsFixed(1), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: -1)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                            child: Text(bmiInfo['status'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          const SizedBox(height: 16),
                          Text(bmiInfo['desc'], textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: theme.textTheme.displayLarge?.color)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('bmi_categories'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                          const SizedBox(height: 16),
                          _buildBmiLegendRow(Colors.blue, tr('underweight'), '< 18.5', theme),
                          const SizedBox(height: 12),
                          _buildBmiLegendRow(Colors.green, tr('normal_weight'), '18.5 - 24.9', theme),
                          const SizedBox(height: 12),
                          _buildBmiLegendRow(Colors.orange, tr('overweight'), '25.0 - 29.9', theme),
                          const SizedBox(height: 12),
                          _buildBmiLegendRow(Colors.red, tr('obesity'), '≥ 30.0', theme),
                        ],
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TdeeResultScreen(
                                  tdee: tdee,
                                  age: age,
                                  profileData: profileData,
                                )
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(tr('see_calorie_details'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildBmiLegendRow(Color color, String label, String range, ThemeData theme) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color))),
        Text(range, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}