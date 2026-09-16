import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_localization.dart';
import 'activity_level_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String selectedGender = 'Male';

  final _dobCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void dispose() {
    _dobCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, ThemeData theme) async {
    DateTime initial = DateTime(2000, 1, 1);
    if (_dobCtrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobCtrl.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.brandPrimary,
              onPrimary: Colors.white,
              surface: theme.cardColor,
              onSurface: theme.textTheme.displayLarge!.color!,
            ),
            dialogBackgroundColor: theme.cardColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        String year = picked.year.toString();
        String month = picked.month.toString().padLeft(2, '0');
        String day = picked.day.toString().padLeft(2, '0');
        _dobCtrl.text = "$year-$month-$day";
      });
    }
  }

  void _continueToActivity() {
    if (_dobCtrl.text.isEmpty || _weightCtrl.text.isEmpty || _heightCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('fill_all_fields'))),
      );
      return;
    }

    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));

    if (weight == null || weight <= 20 || weight >= 300 || height == null || height <= 50 || height >= 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('invalid_weight_height')), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final Map<String, dynamic> profileData = {
      'gender': selectedGender,
      'dob': _dobCtrl.text,
      'weight': _weightCtrl.text,
      'height': _heightCtrl.text,
    };

    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ActivityLevelScreen(profileData: profileData))
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar('1/3', 0.33, isDark),
                    const SizedBox(height: 24),

                    Text(tr('personal_data'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(tr('we_need_this'), style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 32),

                    Text(tr('gender'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildGenderCard(tr('male'), 'Male', Icons.male, selectedGender == 'Male', theme, isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGenderCard(tr('female'), 'Female', Icons.female, selectedGender == 'Female', theme, isDark)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(tr('date_of_birth'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)),
                    const SizedBox(height: 8),
                    _buildTextField(
                      hint: 'YYYY-MM-DD',
                      align: TextAlign.left,
                      controller: _dobCtrl,
                      isNumber: false,
                      isReadOnly: true,
                      onTap: () => _selectDate(context, theme),
                      prefixIcon: Icons.calendar_month_rounded,
                      theme: theme,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('weight'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)),
                              const SizedBox(height: 8),
                              _buildTextField(
                                  hint: '0',
                                  align: TextAlign.right,
                                  controller: _weightCtrl,
                                  isNumber: true,
                                  suffixText: 'kg',
                                  theme: theme
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('height'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)),
                              const SizedBox(height: 8),
                              _buildTextField(
                                  hint: '0',
                                  align: TextAlign.right,
                                  controller: _heightCtrl,
                                  isNumber: true,
                                  suffixText: 'cm',
                                  theme: theme
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _continueToActivity,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0
                        ),
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

  Widget _buildGenderCard(String displayLabel, String value, IconData icon, bool isSelected, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4)) : theme.cardColor,
          border: Border.all(
              color: isSelected ? AppTheme.brandPrimary : theme.dividerColor,
              width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.brandPrimary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: value == 'Male' ? Colors.blue.shade500 : Colors.pink.shade400),
            const SizedBox(height: 12),
            Text(displayLabel, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.brandPrimary : theme.textTheme.displayLarge?.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextAlign align,
    required TextEditingController controller,
    required bool isNumber,
    bool isReadOnly = false,
    VoidCallback? onTap,
    String? suffixText,
    IconData? prefixIcon,
    required ThemeData theme,
  }) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      onTap: onTap,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textAlign: align,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.normal),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: theme.textTheme.bodyMedium?.color, size: 22) : null,
        suffixText: suffixText,
        suffixStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.dividerColor, width: 1)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.brandPrimary, width: 2)
        ),
        filled: true,
        fillColor: theme.cardColor,
      ),
    );
  }
}