import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileService = ProfileService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _dataChanged = false;

  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _gender = 'Male';
  String _email = '';

  int _selectedActivity = 1;
  int _selectedGoal = 1;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) _email = user.email ?? '';

      final data = await _profileService.fetchProfileData();
      setState(() {
        _nameCtrl.text = data['full_name'] ?? '';
        _dobCtrl.text = data['dob'] ?? '';
        _weightCtrl.text = data['weight_kg']?.toString() ?? '';
        _heightCtrl.text = data['height_cm']?.toString() ?? '';
        _gender = data['gender'] ?? 'Male';
        _selectedActivity = data['activity_level'] ?? 1;
        _selectedGoal = data['goal'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, ThemeData theme, bool isDark) async {
    DateTime initial = DateTime(2000, 1, 1);
    if (_dobCtrl.text.isNotEmpty) { try { initial = DateTime.parse(_dobCtrl.text); } catch (_) {} }

    final DateTime? picked = await showDatePicker(
      context: context, initialDate: initial, firstDate: DateTime(1930), lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(colorScheme: ColorScheme.light(primary: AppTheme.brandPrimary, onPrimary: Colors.white, surface: theme.cardColor, onSurface: theme.textTheme.displayLarge!.color!), dialogBackgroundColor: theme.cardColor),
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

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // PERBAIKAN: Ganti puluhan baris kalkulasi dengan memanggil 1 fungsi di ProfileService
      await _profileService.updateProfileAndMetrics(
          _weightCtrl.text, _heightCtrl.text, _gender, _dobCtrl.text, _selectedActivity, _selectedGoal
      );

      // Pengecualian: Nama diupdate manual karena ada di auth & tabel terpisah jika dibutuhkan.
      // Tabel users_profile sudah mengupdate nama jika diintegrasikan, mari update manual untuk nama:
      await Supabase.instance.client.from('users_profile').update({'full_name': _nameCtrl.text}).eq('id', Supabase.instance.client.auth.currentUser!.id);

      if (mounted) {
        _dataChanged = true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('profile_updated')), backgroundColor: Colors.green));
        Navigator.pop(context, _dataChanged);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) return;
              Navigator.pop(context, _dataChanged);
            },
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context, _dataChanged),
                  child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)), child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: theme.textTheme.displayLarge?.color)),
                ),
                title: Text(tr('edit_profile'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                centerTitle: false,
              ),
              body: _isLoading
                  ? _buildSkeletonLoader(isDark)
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(tr('personal_data'), theme),
                    const SizedBox(height: 16),
                    _buildInputLabel(tr('full_name'), theme),
                    _buildTextField(_nameCtrl, Icons.person_outline, theme, isDark),
                    const SizedBox(height: 16),

                    _buildInputLabel(tr('date_of_birth'), theme),
                    _buildTextField(_dobCtrl, Icons.calendar_today_outlined, theme, isDark, isReadOnly: true, onTap: () => _selectDate(context, theme, isDark)),
                    const SizedBox(height: 16),

                    _buildInputLabel(tr('email_address'), theme),
                    _buildTextField(TextEditingController(text: _email), Icons.email_outlined, theme, isDark, isEnabled: false),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.lock_outline, size: 12, color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 4),
                        Text(tr('contact_support'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle(tr('body_metrics').toUpperCase(), theme),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Weight (kg)', theme), _buildTextField(_weightCtrl, null, theme, isDark, isCentered: true, isNumber: true)])),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Height (cm)', theme), _buildTextField(_heightCtrl, null, theme, isDark, isCentered: true, isNumber: true)])),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle(tr('activity_level').toUpperCase(), theme),
                    const SizedBox(height: 16),
                    _buildCustomRadioTile(0, _selectedActivity, tr('sedentary'), 'Little or no exercise', Icons.chair_alt, theme, isDark, (val) => setState(() => _selectedActivity = val)),
                    const SizedBox(height: 12),
                    _buildCustomRadioTile(1, _selectedActivity, tr('lightly_active'), 'Light exercise 1-3 days/week', Icons.directions_walk, theme, isDark, (val) => setState(() => _selectedActivity = val)),
                    const SizedBox(height: 12),
                    _buildCustomRadioTile(2, _selectedActivity, tr('moderate_active'), 'Moderate exercise 3-5 days/week', Icons.directions_run, theme, isDark, (val) => setState(() => _selectedActivity = val)),
                    const SizedBox(height: 12),
                    _buildCustomRadioTile(3, _selectedActivity, tr('very_active'), 'Hard exercise 6-7 days/week', Icons.fitness_center, theme, isDark, (val) => setState(() => _selectedActivity = val)),
                    const SizedBox(height: 32),

                    _buildSectionTitle(tr('current_goal').toUpperCase(), theme),
                    const SizedBox(height: 16),
                    _buildCustomRadioTile(0, _selectedGoal, tr('lose_weight'), 'Calorie deficit for fat loss', Icons.trending_down, theme, isDark, (val) => setState(() => _selectedGoal = val)),
                    const SizedBox(height: 12),
                    _buildCustomRadioTile(1, _selectedGoal, tr('maintain_weight'), 'Keep your current physique', Icons.remove, theme, isDark, (val) => setState(() => _selectedGoal = val)),
                    const SizedBox(height: 12),
                    _buildCustomRadioTile(2, _selectedGoal, tr('gain_muscle'), 'Calorie surplus for bulking', Icons.trending_up, theme, isDark, (val) => setState(() => _selectedGoal = val)),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.brandPrimary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: theme.textTheme.displayLarge?.color, fontSize: 12, height: 1.5),
                                children: [
                                  TextSpan(text: tr('updating_your')),
                                  TextSpan(text: tr('weight_height_activity'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: tr('or_goal')),
                                  TextSpan(text: tr('auto_recalculate')),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(tr('save_changes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    Color skeletonColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    Widget buildBox(double width, double height, {double borderRadius = 12}) => Container(width: width, height: height, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(borderRadius)));

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildBox(120, 16, borderRadius: 4), const SizedBox(height: 16), buildBox(80, 14, borderRadius: 4), const SizedBox(height: 8), buildBox(double.infinity, 56), const SizedBox(height: 16), buildBox(90, 14, borderRadius: 4), const SizedBox(height: 8), buildBox(double.infinity, 56), const SizedBox(height: 16), buildBox(100, 14, borderRadius: 4), const SizedBox(height: 8), buildBox(double.infinity, 56), const SizedBox(height: 4), buildBox(180, 12, borderRadius: 4), const SizedBox(height: 32),
          buildBox(120, 16, borderRadius: 4), const SizedBox(height: 16), Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [buildBox(80, 14, borderRadius: 4), const SizedBox(height: 8), buildBox(double.infinity, 56)])), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [buildBox(80, 14, borderRadius: 4), const SizedBox(height: 8), buildBox(double.infinity, 56)]))]), const SizedBox(height: 32),
          buildBox(120, 16, borderRadius: 4), const SizedBox(height: 16), buildBox(double.infinity, 72, borderRadius: 16), const SizedBox(height: 12), buildBox(double.infinity, 72, borderRadius: 16), const SizedBox(height: 12), buildBox(double.infinity, 72, borderRadius: 16), const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color, letterSpacing: 1.2));
  }

  Widget _buildInputLabel(String label, ThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)));
  }

  Widget _buildTextField(TextEditingController controller, IconData? prefixIcon, ThemeData theme, bool isDark, {bool isEnabled = true, bool isCentered = false, bool isNumber = false, bool isReadOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: controller, enabled: isEnabled, readOnly: isReadOnly, onTap: onTap, keyboardType: isNumber ? TextInputType.number : TextInputType.text, textAlign: isCentered ? TextAlign.center : TextAlign.left,
      style: TextStyle(color: isEnabled ? theme.textTheme.displayLarge?.color : theme.textTheme.bodyMedium?.color, fontSize: 14, fontWeight: isCentered ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: theme.textTheme.bodyMedium?.color, size: 20) : null, filled: true, fillColor: isEnabled ? theme.cardColor : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandPrimary))),
    );
  }

  Widget _buildCustomRadioTile(int value, int groupValue, String title, String subtitle, IconData icon, ThemeData theme, bool isDark, Function(int) onChanged) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4)) : theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? AppTheme.brandPrimary : theme.dividerColor, width: isSelected ? 1.5 : 1)),
        child: Row(
          children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppTheme.brandPrimary : Colors.grey.shade400, width: 2)), child: isSelected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.brandPrimary, shape: BoxShape.circle))) : null),
            const SizedBox(width: 16),
            Icon(icon, color: isDark ? Colors.brown.shade300 : Colors.brown.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.displayLarge?.color)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color))])),
          ],
        ),
      ),
    );
  }
}