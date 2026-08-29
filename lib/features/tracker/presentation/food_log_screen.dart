import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/food_service.dart';
import 'add_food_screen.dart';
import 'water_tracker_screen.dart';
import 'food_detail_screen.dart';

class FoodLogScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  final int updateToken;

  const FoodLogScreen({super.key, this.onDataChanged, this.updateToken = 0});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final _foodService = FoodService();
  bool _isLoading = true;
  bool _hasError = false;

  int _dailyTotalCal = 0;
  List<Map<String, dynamic>> _breakfastMeals = [];
  List<Map<String, dynamic>> _lunchMeals = [];
  List<Map<String, dynamic>> _dinnerMeals = [];
  List<Map<String, dynamic>> _snackMeals = [];

  List<Map<String, String>> _quickAddFoods = [];

  @override
  void initState() {
    super.initState();
    _fetchTodayMeals();
    _fetchQuickAddFoods();
  }

  @override
  void didUpdateWidget(FoodLogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updateToken != oldWidget.updateToken) {
      _fetchTodayMeals(isSilent: true);
      _fetchQuickAddFoods();
    }
  }

  Future<void> _fetchQuickAddFoods() async {
    try {
      final validFoods = await _foodService.fetchQuickAddFoods();
      List<Map<String, String>> recent = validFoods.map((food) => {
        'id': food['id'].toString(),
        'name': food['name'].toString(),
        'cal': food['calories'].toString(),
        'macros': 'P:${food['protein']}g C:${food['carbs']}g F:${food['fat']}g',
        'created_by': food['created_by']?.toString() ?? '',
      }).toList();

      if (mounted) setState(() => _quickAddFoods = recent);
    } catch (e) {
      print('Error loading quick add: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: ${tr('failed_load_history')}'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _fetchTodayMeals({bool isSilent = false}) async {
    if (!isSilent) setState(() { _isLoading = true; _hasError = false; });

    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final data = await _foodService.fetchTodayMeals(todayStr);

      int total = 0;
      List<Map<String, dynamic>> breakfast = [];
      List<Map<String, dynamic>> lunch = [];
      List<Map<String, dynamic>> dinner = [];
      List<Map<String, dynamic>> snack = [];

      for (var row in data) {
        final cal = (row['calories_consumed'] as num).toInt();
        total += cal;

        double baseCal = (row['foods']?['calories'] as num?)?.toDouble() ?? 0;
        double currentPortion = baseCal > 0 ? (cal / baseCal) : 1.0;

        final mealData = {
          'id': row['id'].toString(),
          'name': row['foods']?['name'] ?? tr('custom_food'),
          'cal': '$cal ${tr('kcal')}',
          'raw_cal': cal,
          'base_cal': baseCal,
          'portion': currentPortion,
          'meal_type': row['meal_type'],
        };

        switch (row['meal_type']) {
          case 'Breakfast': breakfast.add(mealData); break;
          case 'Lunch': lunch.add(mealData); break;
          case 'Dinner': dinner.add(mealData); break;
          default: snack.add(mealData);
        }
      }

      if (mounted) {
        setState(() {
          _dailyTotalCal = total;
          _breakfastMeals = breakfast;
          _lunchMeals = lunch;
          _dinnerMeals = dinner;
          _snackMeals = snack;
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error loading food log: $e');
      if (mounted) {
        setState(() => _hasError = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: ${tr('check_internet')}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMealLog(dynamic logId, int calDeduct) async {
    final targetId = logId.toString();
    setState(() {
      _breakfastMeals.removeWhere((item) => item['id'] == targetId);
      _lunchMeals.removeWhere((item) => item['id'] == targetId);
      _dinnerMeals.removeWhere((item) => item['id'] == targetId);
      _snackMeals.removeWhere((item) => item['id'] == targetId);
      _dailyTotalCal -= calDeduct;
      if (_dailyTotalCal < 0) _dailyTotalCal = 0;
    });

    try {
      await _foodService.deleteMealLog(targetId);
      await _fetchTodayMeals(isSilent: true);
      widget.onDataChanged?.call();
    } catch (e) {
      await _fetchTodayMeals(isSilent: true);
    }
  }

  void _showBulkEditMealLogSheet(String mealName, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<Map<String, dynamic>> editingItems = items.map((e) {
      var item = Map<String, dynamic>.from(e);
      if ((item['base_cal'] as num) <= 0) {
        item['base_cal'] = (item['raw_cal'] as num).toDouble();
        item['portion'] = 1.0;
      }
      return item;
    }).toList();

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
                    Text('${tr('edit_log')} $mealName', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                    Text(tr('adjust_portion_time'), style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
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
                                  Expanded(child: Text(item['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color), overflow: TextOverflow.ellipsis)),
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
                                          onPressed: () {
                                            if (item['portion'] > 0.5) setModalState(() => item['portion'] -= 0.5);
                                          },
                                        ),
                                        Text('${item['portion'].toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${tr('portion')}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color)),
                                        IconButton(
                                          icon: Icon(Icons.add, size: 16, color: theme.textTheme.displayLarge?.color),
                                          onPressed: () {
                                            setModalState(() => item['portion'] += 0.5);
                                          },
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
                            for (var item in editingItems) {
                              int updatedCal = (item['base_cal'] * item['portion']).round();
                              await _foodService.updateMealLog(item['id'], item['meal_type'], updatedCal);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              _fetchTodayMeals(isSilent: true);
                              widget.onDataChanged?.call();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('log_updated')), backgroundColor: Colors.green));
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
                            : Text(tr('save_changes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  BoxDecoration _getSemiTransparentDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    bool noMeals = _breakfastMeals.isEmpty && _lunchMeals.isEmpty && _dinnerMeals.isEmpty && _snackMeals.isEmpty;

    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('food_log'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                        const SizedBox(height: 4),
                        Text(tr('search_add_food'), style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                        const SizedBox(height: 24),

                        TextField(
                          readOnly: true,
                          onTap: () async {
                            final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddFoodScreen(autoFocusSearch: true))
                            );
                            if (result != null && result != false) {
                              _fetchTodayMeals(isSilent: false);
                              _fetchQuickAddFoods();
                              widget.onDataChanged?.call();
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
                            hintText: tr('search_food'),
                            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.7),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.brandPrimary)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _isLoading
                        ? _buildSkeletonLoader(isDark)
                        : RefreshIndicator(
                      onRefresh: () async {
                        await _fetchTodayMeals(isSilent: true);
                        await _fetchQuickAddFoods();
                      },
                      color: AppTheme.brandPrimary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 8.0, bottom: 100.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('quick_add'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                            const SizedBox(height: 16),

                            if (_quickAddFoods.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: Text(tr('no_recent_meals'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))),
                              )
                            else
                              Column(
                                children: [
                                  for (int i = 0; i < _quickAddFoods.length; i += 2)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Row(
                                        children: [
                                          Expanded(child: _buildQuickFoodItem(_quickAddFoods[i], theme, isDark)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: (i + 1 < _quickAddFoods.length)
                                                ? _buildQuickFoodItem(_quickAddFoods[i + 1], theme, isDark)
                                                : const SizedBox.shrink(),
                                          ),
                                        ],
                                      ),
                                    )
                                ],
                              ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AddFoodScreen(autoFocusSearch: false))
                                  );
                                  if (result != null && result != false) {
                                    _fetchTodayMeals(isSilent: false);
                                    _fetchQuickAddFoods();
                                    widget.onDataChanged?.call();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                                ),
                                child: Text(tr('see_all_food'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 24),

                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const WaterTrackerScreen()));
                                if (result != null && result != false) {
                                  _fetchTodayMeals(isSilent: true);
                                  widget.onDataChanged?.call();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: _getSemiTransparentDecoration(theme, isDark),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE), shape: BoxShape.circle),
                                      child: const Icon(Icons.water_drop_outlined, color: Colors.lightBlue),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tr('water_intake'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.displayLarge?.color)),
                                          const SizedBox(height: 4),
                                          Text(tr('track_hydration'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: isDark ? Colors.black26 : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text(tr('todays_meals'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                            const SizedBox(height: 16),

                            if (_hasError)
                              Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(tr('failed_load_data_pull'), style: TextStyle(color: Colors.redAccent.shade200, fontWeight: FontWeight.bold))))
                            else if (noMeals)
                              Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(tr('no_meals_today'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))))
                            else ...[
                                _buildMealSection(tr('breakfast'), Icons.wb_twilight, _breakfastMeals, theme, isDark),
                                const SizedBox(height: 16),
                                _buildMealSection(tr('lunch'), Icons.wb_sunny, _lunchMeals, theme, isDark),
                                const SizedBox(height: 16),
                                _buildMealSection(tr('dinner'), Icons.nightlight_round, _dinnerMeals, theme, isDark),
                                const SizedBox(height: 16),
                                _buildMealSection(tr('snack'), Icons.cookie, _snackMeals, theme, isDark),
                              ],
                            const SizedBox(height: 32),

                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: _getSemiTransparentDecoration(theme, isDark),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(tr('daily_total'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                                  Text('$_dailyTotalCal ${tr('kcal')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.brandPrimary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    Color skeletonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 100, height: 16, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 70, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(16)))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 70, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(16)))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Container(height: 70, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(16)))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 70, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(16)))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20))),
        ],
      ),
    );
  }

  Widget _buildQuickFoodItem(Map<String, String> foodData, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailScreen(foodData: foodData)));
        if (result != null && result != false) {
          _fetchTodayMeals(isSilent: false);
          _fetchQuickAddFoods();
          widget.onDataChanged?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3))
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF78350F) : Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.history_rounded, size: 16, color: isDark ? Colors.orange.shade300 : Colors.brown.shade400),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(foodData['name']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.displayLarge?.color), overflow: TextOverflow.ellipsis),
                  Text('${foodData['cal']} ${tr('kcal')}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String mealName, IconData icon, List<Map<String, dynamic>> items, ThemeData theme, bool isDark) {
    bool isEmpty = items.isEmpty;
    int sectionTotal = 0;
    for (var item in items) {
      sectionTotal += int.tryParse(item['cal'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    return GestureDetector(
      onTap: () => _showBulkEditMealLogSheet(mealName, items),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _getSemiTransparentDecoration(theme, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: isDark ? Colors.orange.shade300 : Colors.brown.shade700),
                    const SizedBox(width: 8),
                    Text(mealName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                    if (!isEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.edit_outlined, size: 14, color: theme.textTheme.bodyMedium?.color),
                    ]
                  ],
                ),
                Text('$sectionTotal ${tr('kcal')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isEmpty ? theme.textTheme.bodyMedium?.color : AppTheme.brandPrimary)),
              ],
            ),
            if (!isEmpty) ...[
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item['name'], style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    Row(
                      children: [
                        Text(item['cal'], style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            int itemCal = int.tryParse(item['cal'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                            _deleteMealLog(item['id'], itemCal);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF7F1D1D) : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.close, size: 12, color: Colors.redAccent),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )).toList()
            ]
          ],
        ),
      ),
    );
  }
}