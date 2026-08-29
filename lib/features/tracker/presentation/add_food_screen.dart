import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_food_service.dart';
import '../../../core/services/food_service.dart';
import '../../../core/utils/app_localization.dart';
import 'food_detail_screen.dart';

class AddFoodScreen extends StatefulWidget {
  final bool autoFocusSearch;

  const AddFoodScreen({super.key, this.autoFocusSearch = false});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _foodService = FoodService();
  bool isAllSelected = true;
  String searchQuery = "";

  bool _isLoading = false;
  Timer? _debounce;
  bool _dataChanged = false;

  List<Map<String, dynamic>> _displayedFoods = [];
  List<Map<String, dynamic>> _selectedFoodsCart = [];

  final _searchCtrl = TextEditingController();
  final _aiInputCtrl = TextEditingController();

  final _customNameCtrl = TextEditingController();
  final _customCalCtrl = TextEditingController();
  final _customProteinCtrl = TextEditingController();
  final _customCarbsCtrl = TextEditingController();
  final _customFatCtrl = TextEditingController();

  final _aiService = AiFoodService();

  @override
  void initState() {
    super.initState();
    _searchSupabaseFoods('');
  }

  Future<void> _processAiInput(String input) async {
    if (input.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const CircularProgressIndicator(color: Color(0xFF9333EA)),
          )
      ),
    );

    try {
      final parsedItems = await _aiService.analyzeFoodsMulti(input);
      if (mounted) Navigator.pop(context);
      if (parsedItems.isNotEmpty) {
        _showAiVerificationSheet(parsedItems);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('cannot_process_food')), backgroundColor: Colors.orange));
      }
      _aiInputCtrl.clear();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  void _showAiVerificationSheet(List<Map<String, dynamic>> parsedItems) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    List<int> selectedIndices = List.generate(parsedItems.length, (index) => 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    Text(tr('ai_verification_result'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                    // PERBAIKAN Teks statis menjadi fungsi tr()
                    Text(tr('remove_unnecessary_options'), style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView.separated(
                        itemCount: parsedItems.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                        itemBuilder: (ctx, index) {
                          final item = parsedItems[index];
                          final matches = item['matches'] as List<Map<String, dynamic>>;
                          final fallback = item['fallback'];
                          final qty = item['quantity'];

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF9333EA)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('${tr('ai_detected')} ${qty.toString().replaceAll(RegExp(r'\.0$'), '')}x ${item['keyword']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          parsedItems.removeAt(index);
                                          selectedIndices.removeAt(index);
                                        });
                                        if (parsedItems.isEmpty) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: selectedIndices[index],
                                      isExpanded: true,
                                      dropdownColor: theme.cardColor,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color),
                                      items: [
                                        for (int j = 0; j < matches.length; j++)
                                          DropdownMenuItem(value: j, child: Text('${matches[j]['name']} (${matches[j]['calories']} kcal)', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: matches.length, child: Text('${tr('use_ai_estimation')} (${fallback['calories']} kcal)', style: const TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedIndices[index] = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          List<Map<String, dynamic>> cartToProcess = [];
                          for (int i = 0; i < parsedItems.length; i++) {
                            final item = parsedItems[i];
                            final matches = item['matches'] as List<Map<String, dynamic>>;
                            final fallback = item['fallback'];
                            final selIdx = selectedIndices[i];
                            final qty = item['quantity'];

                            if (selIdx < matches.length) {
                              final dbFood = matches[selIdx];
                              cartToProcess.add({'food_id': dbFood['id'].toString(), 'name': dbFood['name'], 'base_cal': (dbFood['calories'] as num?)?.toDouble() ?? 0.0, 'base_p': (dbFood['protein'] as num?)?.toDouble() ?? 0.0, 'base_c': (dbFood['carbs'] as num?)?.toDouble() ?? 0.0, 'base_f': (dbFood['fat'] as num?)?.toDouble() ?? 0.0, 'portion': qty, 'meal_type': _getDefaultMealType(), 'is_custom': false});
                            } else {
                              cartToProcess.add({'food_id': null, 'name': '${fallback['name']} (AI Est.)', 'base_cal': (fallback['calories'] as num?)?.toDouble() ?? 0.0, 'base_p': (fallback['protein'] as num?)?.toDouble() ?? 0.0, 'base_c': (fallback['carbs'] as num?)?.toDouble() ?? 0.0, 'base_f': (fallback['fat'] as num?)?.toDouble() ?? 0.0, 'portion': qty, 'meal_type': _getDefaultMealType(), 'is_custom': true});
                            }
                          }
                          _showBulkAddBottomSheet(cartToProcess);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: Text(tr('confirm_selection'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 15) return 'Lunch';
    if (hour >= 15 && hour < 22) return 'Dinner';
    return 'Snack';
  }

  void _showBulkAddBottomSheet(List<Map<String, dynamic>> itemsToProcess) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<Map<String, dynamic>> editingItems = itemsToProcess.map((e) => Map<String, dynamic>.from(e)).toList();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    Text(tr('adjust_food_log'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                    Text(tr('check_portion_time'), style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView.separated(
                        itemCount: editingItems.length,
                        separatorBuilder: (ctx, i) => Divider(color: theme.dividerColor, height: 32),
                        itemBuilder: (ctx, index) {
                          final item = editingItems[index];
                          final int currentTotalCal = (item['base_cal'] * item['portion']).round();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(item['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color))),
                                        if (item['is_custom'] == true)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('AI Est.', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                          )
                                      ],
                                    ),
                                  ),
                                  Text('$currentTotalCal ${tr('kcal')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary)),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: 16, color: theme.textTheme.displayLarge?.color),
                                          onPressed: () { if (item['portion'] > 0.5) setModalState(() => item['portion'] -= 0.5); },
                                        ),
                                        Text('${item['portion']} ${tr('portion')}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)),
                                        IconButton(
                                          icon: Icon(Icons.add, size: 16, color: theme.textTheme.displayLarge?.color),
                                          onPressed: () { setModalState(() => item['portion'] += 0.5); },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: item['meal_type'],
                                        dropdownColor: theme.cardColor,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color),
                                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((String value) {
                                          return DropdownMenuItem<String>(value: value, child: Text(tr(value.toLowerCase())));
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) setModalState(() => item['meal_type'] = newValue);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          setModalState(() => isSaving = true);
                          try {
                            final todayStr = DateTime.now().toIso8601String().split('T')[0];

                            for (var item in editingItems) {
                              String? foodId = item['food_id'];

                              if (item['is_custom'] == true) {
                                foodId = await _foodService.createCustomFood(
                                    item['name'], item['base_cal'], item['base_p'], item['base_c'], item['base_f']
                                );
                              }

                              int totalCal = (item['base_cal'] * item['portion']).round();
                              await _foodService.insertMealLog(foodId, todayStr, item['meal_type'], totalCal);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              setState(() { _selectedFoodsCart.clear(); _dataChanged = true; });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('successfully_added_log')), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.red));
                          } finally {
                            if (mounted) setModalState(() => isSaving = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(tr('save_items_to_log').replaceFirst('Item(s)', '${editingItems.length}'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    setState(() => searchQuery = query);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (isAllSelected) _searchSupabaseFoods(query);
      else _fetchRecentFoods(query);
    });
  }

  Future<void> _searchSupabaseFoods(String query) async {
    setState(() => _isLoading = true);
    try {
      final validFoods = await _foodService.searchFoods(query);
      _parseResponseData(validFoods);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRecentFoods([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      final validRows = await _foodService.fetchRecentFoods(query);
      _parseResponseData(validRows);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _parseResponseData(List<dynamic> response) {
    List<Map<String, dynamic>> parsedFoods = response.map((food) {
      return {'id': food['id'].toString(), 'name': food['name'].toString(), 'base_cal': (food['calories'] as num?)?.toDouble() ?? 0.0, 'base_p': (food['protein'] as num?)?.toDouble() ?? 0.0, 'base_c': (food['carbs'] as num?)?.toDouble() ?? 0.0, 'base_f': (food['fat'] as num?)?.toDouble() ?? 0.0, 'created_by': food['created_by']?.toString() ?? ''};
    }).toList();
    setState(() { _displayedFoods = parsedFoods; _isLoading = false; });
  }

  double _parseNumber(String text) {
    if (text.trim().isEmpty) return 0.0;
    return double.tryParse(text.trim().replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> _saveCustomFoodOnly() async {
    if (_customNameCtrl.text.isEmpty || _customCalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('fill_name_calories'))));
      return;
    }
    try {
      await _foodService.createCustomFood(
          _customNameCtrl.text.trim(), _parseNumber(_customCalCtrl.text), _parseNumber(_customProteinCtrl.text), _parseNumber(_customCarbsCtrl.text), _parseNumber(_customFatCtrl.text)
      );

      if (mounted) {
        Navigator.pop(context);
        _dataChanged = true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('custom_food_saved')), backgroundColor: Colors.green));
        if (isAllSelected) _searchSupabaseFoods(searchQuery);
        else _fetchRecentFoods(searchQuery);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('failed_create_custom_food')), backgroundColor: Colors.red));
    }
  }

  void _showCreateCustomFoodSheet(BuildContext context, ThemeData theme, bool isDark) {
    FocusScope.of(context).unfocus();
    _customNameCtrl.clear(); _customCalCtrl.clear(); _customProteinCtrl.clear(); _customCarbsCtrl.clear(); _customFatCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(tr('create_custom_food'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                const SizedBox(height: 24),

                _buildInputLabel(tr('food_name'), theme),
                _buildTextField('', _customNameCtrl, theme, isDark, isNumber: false),
                const SizedBox(height: 16),

                _buildInputLabel(tr('calories_kcal'), theme),
                _buildTextField('', _customCalCtrl, theme, isDark, isNumber: true),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel(tr('protein_g'), theme), _buildTextField('0', _customProteinCtrl, theme, isDark, isNumber: true)])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel(tr('carbs_g'), theme), _buildTextField('0', _customCarbsCtrl, theme, isDark, isNumber: true)])),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel(tr('fat_g'), theme), _buildTextField('0', _customFatCtrl, theme, isDark, isNumber: true)])),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _saveCustomFoodOnly,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    child: Text(tr('create_food'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel(); _searchCtrl.dispose(); _aiInputCtrl.dispose(); _customNameCtrl.dispose(); _customCalCtrl.dispose(); _customProteinCtrl.dispose(); _customCarbsCtrl.dispose(); _customFatCtrl.dispose(); super.dispose();
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
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context, _dataChanged),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.textTheme.displayLarge?.color),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(tr('add_food'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateCustomFoodSheet(context, theme, isDark),
                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                            label: const Text('Custom', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          )
                        ],
                      ),
                    ),

                    // AI INPUT BOX
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark ? [const Color(0xFF4C1D95).withOpacity(0.3), const Color(0xFF1E3A8A).withOpacity(0.3)] : [const Color(0xFFFAF5FF), const Color(0xFFEFF6FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF7C3AED) : const Color(0xFFD8B4FE)),
                        ),
                        child: TextField(
                          controller: _aiInputCtrl,
                          style: TextStyle(color: theme.textTheme.displayLarge?.color),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9333EA)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send_rounded, color: Color(0xFF9333EA)),
                              onPressed: () { FocusScope.of(context).unfocus(); _processAiInput(_aiInputCtrl.text); },
                            ),
                            hintText: tr('ask_ai'),
                            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onSubmitted: (val) => _processAiInput(val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NORMAL SEARCH BOX
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        autofocus: widget.autoFocusSearch,
                        style: TextStyle(color: theme.textTheme.displayLarge?.color),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(icon: Icon(Icons.clear, color: theme.textTheme.bodyMedium?.color), onPressed: () { _searchCtrl.clear(); _onSearchChanged(''); })
                              : null,
                          hintText: tr('search_food_manually'),
                          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          filled: true,
                          fillColor: theme.cardColor,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () { setState(() => isAllSelected = true); _searchSupabaseFoods(searchQuery); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: isAllSelected ? AppTheme.brandPrimary : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(20)),
                              child: Text(tr('all'), style: TextStyle(color: isAllSelected ? Colors.white : theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () { setState(() => isAllSelected = false); _fetchRecentFoods(searchQuery); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: !isAllSelected ? AppTheme.brandPrimary : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(20)),
                              child: Text(tr('recent'), style: TextStyle(color: !isAllSelected ? Colors.white : theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: _isLoading
                          ? ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        itemCount: 6,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildFoodSkeleton(theme, isDark),
                      )
                          : _displayedFoods.isEmpty
                          ? Center(child: Text(tr('food_not_found'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16)))
                          : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        itemCount: _displayedFoods.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final food = _displayedFoods[index];
                          bool isSelected = _selectedFoodsCart.any((element) => element['food_id'] == food['id']);

                          return GestureDetector(
                            onTap: () async {
                              FocusScope.of(context).unfocus();
                              final mappedFood = {'id': food['id'].toString(), 'name': food['name'].toString(), 'cal': food['base_cal'].toString(), 'macros': 'P:${food['base_p']}g C:${food['base_c']}g F:${food['base_f']}g', 'created_by': food['created_by'].toString()};

                              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailScreen(foodData: mappedFood)));

                              if (result != null && result != false) {
                                _dataChanged = true;

                                if (result == 'deleted') {
                                  setState(() {
                                    _displayedFoods.removeWhere((element) => element['id'] == food['id']);
                                    _selectedFoodsCart.removeWhere((element) => element['food_id'] == food['id']);
                                  });
                                } else {
                                  if (isAllSelected) _searchSupabaseFoods(searchQuery);
                                  else _fetchRecentFoods(searchQuery);
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: isSelected ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4)) : theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppTheme.brandPrimary : theme.dividerColor, width: isSelected ? 1.5 : 1)),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(Icons.restaurant_menu_rounded, color: isDark ? Colors.white54 : Colors.black26),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(food['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.displayLarge?.color)),
                                        const SizedBox(height: 4),
                                        Text('P:${food['base_p']}g C:${food['base_c']}g F:${food['base_f']}g', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${food['base_cal']} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.brandPrimary)),
                                      const SizedBox(height: 8),

                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) { _selectedFoodsCart.removeWhere((e) => e['food_id'] == food['id']); }
                                            else { _selectedFoodsCart.add({'food_id': food['id'], 'name': food['name'], 'base_cal': food['base_cal'], 'base_p': food['base_p'], 'base_c': food['base_c'], 'base_f': food['base_f'], 'portion': 1.0, 'meal_type': _getDefaultMealType(), 'is_custom': false}); }
                                          });
                                        },
                                        child: Container(
                                          width: 24, height: 24,
                                          decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppTheme.brandPrimary : Colors.transparent, border: Border.all(color: isSelected ? AppTheme.brandPrimary : Colors.grey.shade400, width: 2)),
                                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    if (_selectedFoodsCart.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                        ),
                        child: Row(
                          children: [
                            Text(tr('item_selected').replaceFirst('Item(s)', '${_selectedFoodsCart.length}'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.displayLarge?.color)),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => _showBulkAddBottomSheet(_selectedFoodsCart),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                              child: Text(tr('continue_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildFoodSkeleton(ThemeData theme, bool isDark) {
    Color skeletonColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 150, height: 16, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))), const SizedBox(height: 8), Container(width: 80, height: 12, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4)))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(width: 50, height: 16, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))), const SizedBox(height: 8), Container(width: 40, height: 12, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4)))])
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, ThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)));
  }

  Widget _buildTextField(String hint, TextEditingController controller, ThemeData theme, bool isDark, {bool isNumber = false}) {
    return TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: theme.textTheme.displayLarge?.color, fontSize: 14),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandPrimary))
        )
    );
  }
}