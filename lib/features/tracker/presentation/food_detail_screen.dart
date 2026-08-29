import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/food_service.dart';

class FoodDetailScreen extends StatefulWidget {
  final Map<String, String> foodData;

  const FoodDetailScreen({super.key, required this.foodData});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final _foodService = FoodService();
  bool _isLoading = false;

  bool _isEditing = false;
  double _servings = 1.0;
  bool _dataChanged = false;

  String _selectedMealType = 'Breakfast';

  late String _foodId;
  late String _foodCreatorId;

  late TextEditingController _nameCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _pCtrl;
  late TextEditingController _kCtrl;
  late TextEditingController _fCtrl;

  @override
  void initState() {
    super.initState();
    _foodId = widget.foodData['id'] ?? '0';
    _foodCreatorId = widget.foodData['created_by'] ?? '';

    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) _selectedMealType = 'Breakfast';
    else if (hour >= 11 && hour < 15) _selectedMealType = 'Lunch';
    else if (hour >= 15 && hour < 22) _selectedMealType = 'Dinner';

    String macros = widget.foodData['macros'] ?? 'P:0g C:0g F:0g';
    String p = "0", k = "0", l = "0";

    try {
      final pMatch = RegExp(r'P:([0-9\.]+)g').firstMatch(macros);
      final kMatch = RegExp(r'C:([0-9\.]+)g').firstMatch(macros);
      final lMatch = RegExp(r'F:([0-9\.]+)g').firstMatch(macros);

      if (pMatch != null) p = pMatch.group(1)!;
      if (kMatch != null) k = kMatch.group(1)!;
      if (lMatch != null) l = lMatch.group(1)!;
    } catch (_) {}

    _nameCtrl = TextEditingController(text: widget.foodData['name'] ?? 'Unknown');
    _calCtrl = TextEditingController(text: widget.foodData['cal'] ?? '0');
    _pCtrl = TextEditingController(text: p);
    _kCtrl = TextEditingController(text: k);
    _fCtrl = TextEditingController(text: l);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _calCtrl.dispose(); _pCtrl.dispose(); _kCtrl.dispose(); _fCtrl.dispose();
    super.dispose();
  }

  double _parseNumber(String text) {
    if (text.trim().isEmpty) return 0.0;
    return double.tryParse(text.trim().replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> _saveToMealLogs() async {
    setState(() => _isLoading = true);
    try {
      final baseCal = _parseNumber(_calCtrl.text);
      final totalCal = (baseCal * _servings).round();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      await _foodService.insertMealLog(_foodId, todayStr, _selectedMealType, totalCal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_nameCtrl.text} ${tr('added_to')} ${tr(_selectedMealType.toLowerCase())}!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFoodInDatabase() async {
    setState(() => _isLoading = true);
    try {
      final newCal = _parseNumber(_calCtrl.text);
      final newP = _parseNumber(_pCtrl.text);
      final newK = _parseNumber(_kCtrl.text);
      final newFat = _parseNumber(_fCtrl.text);

      // Jika foodId adalah angka murni yang besar (berarti bukan data kosong awal)
      if (int.tryParse(_foodId) != null && int.parse(_foodId) > 0) {
        await _foodService.updateFood(_foodId, _nameCtrl.text.trim(), newCal, newP, newK, newFat);
      } else {
        // Buat custom food baru jika ini makanan custom
        _foodId = await _foodService.createCustomFood(_nameCtrl.text.trim(), newCal, newP, newK, newFat);
      }

      if (mounted) {
        setState(() { _isEditing = false; _dataChanged = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('food_updated')), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFood() async {
    setState(() => _isLoading = true);
    try {
      await _foodService.hideOrDeleteFood(_foodId, _foodCreatorId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('food_removed')), backgroundColor: Colors.green));
        Navigator.pop(context, 'deleted');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              backgroundColor: AppTheme.brandPrimary,
              body: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_isEditing) setState(() => _isEditing = false);
                              else Navigator.pop(context, _dataChanged);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(tr('food_detail'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Spacer(),
                          if (_isEditing)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: theme.cardColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text(tr('remove_food'), style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                                      content: Text(tr('remove_food_confirm'), style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
                                        ElevatedButton(
                                          onPressed: () { Navigator.pop(ctx); _deleteFood(); },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
                                          child: Text(tr('remove'), style: const TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    )
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white),
                              ),
                            )
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 24.0),
                      child: _isEditing
                          ? TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2))),
                      )
                          : Text(_nameCtrl.text, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tr('nutritional_information'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.displayLarge?.color)),
                                    const SizedBox(height: 4),
                                    Text(tr('total_per_serving'), style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                                    const SizedBox(height: 16),

                                    GridView.count(
                                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.5, crossAxisSpacing: 16, mainAxisSpacing: 16,
                                      children: [
                                        _buildMacroCard(tr('calories'), Icons.local_fire_department_outlined, isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9), isDark ? Colors.green.shade400 : const Color(0xFF4CAF50), _calCtrl, tr('kcal')),
                                        _buildMacroCard(tr('protein'), Icons.opacity_rounded, isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE), isDark ? Colors.red.shade400 : const Color(0xFFF44336), _pCtrl, 'g'),
                                        _buildMacroCard(tr('carbs'), Icons.grass_rounded, isDark ? const Color(0xFF78350F) : const Color(0xFFFFFDE7), isDark ? Colors.yellow.shade400 : const Color(0xFFFBC02D), _kCtrl, 'g'),
                                        _buildMacroCard(tr('fat'), Icons.opacity_rounded, isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFF3E0), isDark ? Colors.orange.shade400 : const Color(0xFFFF9800), _fCtrl, 'g'),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    Divider(color: theme.dividerColor),
                                    const SizedBox(height: 16),

                                    Text(tr('meal_type'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.displayLarge?.color)),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedMealType,
                                          isExpanded: true,
                                          dropdownColor: theme.cardColor,
                                          icon: Icon(Icons.expand_more_rounded, color: theme.textTheme.bodyMedium?.color),
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color),
                                          items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((String value) {
                                            return DropdownMenuItem<String>(value: value, child: Text(tr(value.toLowerCase())));
                                          }).toList(),
                                          onChanged: (newValue) {
                                            if (newValue != null) setState(() => _selectedMealType = newValue);
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(tr('number_of_servings'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.displayLarge?.color)),
                                            const SizedBox(height: 2),
                                            Text(tr('serving_standard'), style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                                          ],
                                        ),
                                        Container(
                                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.remove, size: 18, color: theme.textTheme.displayLarge?.color),
                                                onPressed: () { if (_servings > 0.5) setState(() => _servings -= 0.5); },
                                              ),
                                              Text(_servings.toString().replaceAll(RegExp(r'\.0$'), ''), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.displayLarge?.color)),
                                              IconButton(
                                                icon: Icon(Icons.add, size: 18, color: theme.textTheme.displayLarge?.color),
                                                onPressed: () => setState(() => _servings += 0.5),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
                              child: SafeArea(
                                top: false,
                                child: _isEditing
                                    ? Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: OutlinedButton(
                                          onPressed: () => setState(() { _isEditing = false; _servings = 1.0; }),
                                          style: OutlinedButton.styleFrom(side: BorderSide(color: theme.dividerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                          child: Text(tr('cancel'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _updateFoodInDatabase,
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                                          child: _isLoading
                                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : Text(tr('save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                    : Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() { _isEditing = true; _servings = 1.0; }),
                                      child: Container(
                                        width: 56, height: 56,
                                        decoration: BoxDecoration(color: const Color(0xFFFACC15), borderRadius: BorderRadius.circular(16)),
                                        child: const Icon(Icons.edit_outlined, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _saveToMealLogs,
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                                          child: _isLoading
                                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : Text(tr('add_to_log'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
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

  Widget _buildMacroCard(String title, IconData icon, Color bgColor, Color fgColor, TextEditingController ctrl, String unit) {
    double baseVal = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0;
    double displayedVal = _isEditing ? baseVal : baseVal * _servings;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: fgColor, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          if (_isEditing)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl, keyboardType: TextInputType.number, style: TextStyle(color: fgColor, fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: fgColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: fgColor, width: 2))),
                  ),
                ),
                Text(' $unit', style: TextStyle(color: fgColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(displayedVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''), style: TextStyle(color: fgColor, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(' $unit', style: TextStyle(color: fgColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }
}