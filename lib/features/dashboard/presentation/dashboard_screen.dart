import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/dashboard_service.dart';
import '../../tracker/presentation/add_food_screen.dart';
import '../../tracker/presentation/water_tracker_screen.dart';
import '../../tracker/presentation/workout_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isActive;
  final int updateToken;
  final VoidCallback? onDataChanged;
  final VoidCallback? onNavigateToWorkout;

  const DashboardScreen({
    super.key,
    this.isActive = true,
    this.updateToken = 0,
    this.onDataChanged,
    this.onNavigateToWorkout
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = DashboardService();

  bool _isLoading = true;
  late int _lastToken;

  String _firstName = '';
  String _goalTextKey = 'maintain';
  int _tdeeTarget = 2000;
  int _caloriesConsumed = 0;
  int _caloriesBurned = 0;
  double _proteinConsumed = 0;
  double _carbsConsumed = 0;
  double _fatConsumed = 0;
  int _waterTarget = 2500;
  int _waterConsumed = 0;

  List<Map<String, dynamic>> _breakfastMeals = [];
  List<Map<String, dynamic>> _lunchMeals = [];
  List<Map<String, dynamic>> _dinnerMeals = [];
  List<Map<String, dynamic>> _snackMeals = [];
  List<Map<String, dynamic>> _todayWorkouts = [];

  @override
  void initState() {
    super.initState();
    _lastToken = widget.updateToken;
    _fetchDashboardData();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (widget.updateToken != _lastToken) {
        _lastToken = widget.updateToken;
        _fetchDashboardData(isSilent: false);
      } else {
        _fetchDashboardData(isSilent: true);
      }
    } else if (widget.isActive && widget.updateToken != oldWidget.updateToken) {
      _lastToken = widget.updateToken;
    }
  }

  void _showNetworkAlert(dynamic error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.wifi_off_rounded, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(tr('failed'), style: const TextStyle(color: Colors.white)))]), backgroundColor: Colors.red.shade600, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16), duration: const Duration(seconds: 4)));
  }

  Future<void> _fetchDashboardData({bool isSilent = false}) async {
    if (!isSilent) setState(() => _isLoading = true);

    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final rawData = await _dashboardService.fetchDashboardData(todayStr);

      final profileData = rawData['profile'];
      final mealsData = rawData['meals'] as List<dynamic>;
      final waterData = rawData['water'];
      final workoutData = rawData['workouts'] as List<dynamic>;

      String fullName = profileData['full_name'] ?? 'User';
      _firstName = fullName.split(' ')[0];
      _tdeeTarget = profileData['tdee_target'] ?? 2000;
      _waterTarget = profileData['water_target_ml'] ?? 2500;

      int goalInt = profileData['goal'] ?? 1;
      if (goalInt == 0) _goalTextKey = 'cutting';
      else if (goalInt == 1) _goalTextKey = 'maintain';
      else if (goalInt == 2) _goalTextKey = 'bulking';

      _caloriesConsumed = 0; _proteinConsumed = 0; _carbsConsumed = 0; _fatConsumed = 0;
      List<Map<String, dynamic>> breakfast = []; List<Map<String, dynamic>> lunch = []; List<Map<String, dynamic>> dinner = []; List<Map<String, dynamic>> snack = [];

      for (var meal in mealsData) {
        int consumedCal = (meal['calories_consumed'] as num?)?.toInt() ?? 0;
        _caloriesConsumed += consumedCal;

        if (meal['foods'] != null) {
          double baseCal = (meal['foods']['calories'] as num?)?.toDouble() ?? 1.0;
          double ratio = baseCal > 0 ? (consumedCal / baseCal) : 0;
          _proteinConsumed += ((meal['foods']['protein'] as num?)?.toDouble() ?? 0) * ratio;
          _carbsConsumed += ((meal['foods']['carbs'] as num?)?.toDouble() ?? 0) * ratio;
          _fatConsumed += ((meal['foods']['fat'] as num?)?.toDouble() ?? 0) * ratio;
        }

        final mealDataMap = {'name': meal['foods']?['name'] ?? tr('custom_food'), 'cal': '$consumedCal ${tr('kcal')}'};
        switch (meal['meal_type']) {
          case 'Breakfast': breakfast.add(mealDataMap); break;
          case 'Lunch': lunch.add(mealDataMap); break;
          case 'Dinner': dinner.add(mealDataMap); break;
          default: snack.add(mealDataMap);
        }
      }

      _waterConsumed = waterData != null ? (waterData['total_water_ml'] ?? 0) : 0;

      _caloriesBurned = 0;
      List<Map<String, dynamic>> workouts = [];
      for (var row in workoutData) {
        int cal = (row['calories_burned'] as num?)?.toInt() ?? 0;
        int min = (row['duration_minutes'] as num?)?.toInt() ?? 0;
        _caloriesBurned += cal;
        String name = row['exercises']?['name']?.toString() ?? tr('unknown');
        workouts.add({'name': name, 'desc': '$min ${tr('min')}', 'cal': cal});
      }

      if (mounted) {
        setState(() { _breakfastMeals = breakfast; _lunchMeals = lunch; _dinnerMeals = dinner; _snackMeals = snack; _todayWorkouts = workouts; });
      }
    } catch (e) {
      _showNetworkAlert(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWater(int amount) async {
    final previousTotal = _waterConsumed;
    final newTotal = _waterConsumed + amount;
    setState(() => _waterConsumed = newTotal);
    widget.onDataChanged?.call();

    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await _dashboardService.addWater(todayStr, newTotal);
    } catch (e) {
      setState(() => _waterConsumed = previousTotal);
      _showNetworkAlert(e);
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildGlassCard({required Widget child, required bool isDark, required ThemeData theme, double padding = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSemiTransparentCard({required Widget child, required bool isDark, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int netCalories = _caloriesConsumed - _caloriesBurned;
    if (netCalories < 0) netCalories = 0;
    int remainingCal = _tdeeTarget - netCalories;
    double calProgress = _tdeeTarget > 0 ? netCalories / _tdeeTarget : 0.0;
    if (calProgress > 1.0) calProgress = 1.0;
    double waterProgress = _waterTarget > 0 ? _waterConsumed / _waterTarget : 0.0;
    if (waterProgress > 1.0) waterProgress = 1.0;

    bool noMeals = _breakfastMeals.isEmpty && _lunchMeals.isEmpty && _dinnerMeals.isEmpty && _snackMeals.isEmpty;

    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              child: _isLoading
                  ? _buildDashboardSkeleton(isDark)
                  : RefreshIndicator(
                onRefresh: () => _fetchDashboardData(isSilent: true),
                color: AppTheme.brandPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getFormattedDate(), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('${tr('hello')}, $_firstName!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildGlassCard(
                        isDark: isDark, theme: theme,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr('todays_calories'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF064E3B).withOpacity(0.8) : const Color(0xFFDCFCE7).withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                                  child: Text(tr(_goalTextKey), style: const TextStyle(color: AppTheme.brandPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: 160,
                              height: 160,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: calProgress),
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return CircularProgressIndicator(
                                            value: value,
                                            strokeWidth: 14,
                                            backgroundColor: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                                            color: AppTheme.brandPrimary,
                                            strokeCap: StrokeCap.round
                                        );
                                      }
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TweenAnimationBuilder<int>(
                                          tween: IntTween(begin: 0, end: netCalories),
                                          duration: const Duration(milliseconds: 1000),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, child) {
                                            return Text('$value', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: theme.textTheme.displayLarge?.color, letterSpacing: -1));
                                          }
                                      ),
                                      Text('${tr('of')} $_tdeeTarget ${tr('kcal')}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                                      const SizedBox(height: 4),
                                      Text('${remainingCal > 0 ? remainingCal : 0} ${tr('remaining')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.restaurant_menu_rounded, size: 15, color: theme.textTheme.bodyMedium?.color),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$_caloriesConsumed ${tr('kcal')}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textTheme.displayLarge?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 16, color: theme.dividerColor.withOpacity(0.4)),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(
                                        '-$_caloriesBurned ${tr('kcal')}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMacroItem(tr('protein'), '${_proteinConsumed.toStringAsFixed(0)}g', Colors.redAccent, theme),
                                _buildMacroItem(tr('carbs'), '${_carbsConsumed.toStringAsFixed(0)}g', Colors.orangeAccent, theme),
                                _buildMacroItem(tr('fat'), '${_fatConsumed.toStringAsFixed(0)}g', Colors.lightBlue, theme),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildGlassCard(
                        isDark: isDark, theme: theme,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr('water_intake'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                                TweenAnimationBuilder<int>(
                                    tween: IntTween(begin: 0, end: _waterConsumed),
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Text('$value / $_waterTarget ${tr('ml')}', style: const TextStyle(color: Colors.lightBlue, fontSize: 13, fontWeight: FontWeight.bold));
                                    }
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: waterProgress),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return LinearProgressIndicator(
                                        value: value,
                                        minHeight: 10,
                                        backgroundColor: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                                        color: Colors.lightBlue
                                    );
                                  }
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildWaterButton('+150 ${tr('ml')}', 150, isDark),
                                _buildWaterButton('+250 ${tr('ml')}', 250, isDark),
                                _buildWaterButton('+500 ${tr('ml')}', 500, isDark),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(tr('quick_actions'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickAction(context, Icons.local_cafe_outlined, tr('add_food'), isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7), AppTheme.brandPrimary, theme, isDark: isDark, destination: const AddFoodScreen()),
                          _buildQuickAction(context, Icons.water_drop_outlined, tr('add_water'), isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE), Colors.lightBlue, theme, isDark: isDark, destination: WaterTrackerScreen(initialWater: _waterConsumed, initialTarget: _waterTarget)),
                          _buildQuickAction(context, Icons.fitness_center_outlined, tr('workout'), isDark ? const Color(0xFF4C1D95) : const Color(0xFFF3E8FF), Colors.purpleAccent, theme, isDark: isDark, onTap: widget.onNavigateToWorkout),
                        ],
                      ),
                      const SizedBox(height: 32),

                      Text(tr('todays_meals'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      const SizedBox(height: 16),
                      if (noMeals)
                        Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(tr('no_meals_today'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))))
                      else ...[
                        _buildMealSection(tr('breakfast'), Icons.wb_twilight, _breakfastMeals, theme, isDark),
                        _buildMealSection(tr('lunch'), Icons.wb_sunny, _lunchMeals, theme, isDark),
                        _buildMealSection(tr('dinner'), Icons.nightlight_round, _dinnerMeals, theme, isDark),
                        _buildMealSection(tr('snack'), Icons.cookie, _snackMeals, theme, isDark),
                      ],
                      const SizedBox(height: 32),

                      Text(tr('todays_workouts'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      const SizedBox(height: 16),
                      if (_todayWorkouts.isEmpty)
                        Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(tr('no_workouts_today'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))))
                      else
                        _buildWorkoutSection(_todayWorkouts, theme, isDark),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildDashboardSkeleton(bool isDark) {
    Color skeletonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 120, height: 14, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(width: 180, height: 28, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 24),
          Container(width: double.infinity, height: 280, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 24),
          Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(24))),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 8),
        Container(width: 60, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildWaterButton(String text, int amount, bool isDark) {
    return GestureDetector(
      onTap: () => _addWater(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C4A6E).withOpacity(0.8) : const Color(0xFFF0F9FF).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.blue.shade900.withOpacity(0.5) : Colors.lightBlue.shade100.withOpacity(0.5)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color bgColor, Color iconColor, ThemeData theme, {required bool isDark, Widget? destination, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () async {
          if (destination != null) {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
            if (result == true) {
              _fetchDashboardData(isSilent: false);
              widget.onDataChanged?.call();
            } else {
              _fetchDashboardData(isSilent: true);
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5))
          ),
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor.withOpacity(0.8), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 28)),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealSection(String mealName, IconData icon, List<Map<String, dynamic>> items, ThemeData theme, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    int sectionTotal = 0;
    for (var item in items) sectionTotal += int.tryParse(item['cal'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _buildSemiTransparentCard(
        isDark: isDark, theme: theme,
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
                    Text(mealName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  ],
                ),
                Text('$sectionTotal ${tr('kcal')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(item['name'], style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  Text(item['cal'], style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                ],
              ),
            )).toList()
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutSection(List<Map<String, dynamic>> items, ThemeData theme, bool isDark) {
    int sectionTotalCal = 0;
    for (var item in items) sectionTotalCal += (item['cal'] as int);

    return _buildSemiTransparentCard(
      isDark: isDark, theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center, size: 18, color: isDark ? Colors.purple.shade300 : AppTheme.brandPrimary),
                  const SizedBox(width: 8),
                  Text(tr('exercises'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                ],
              ),
              Text('$sectionTotalCal ${tr('kcal')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      Text(item['desc'], style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                    ],
                  ),
                ),
                Text('${item['cal']} ${tr('kcal')}', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
              ],
            ),
          )).toList()
        ],
      ),
    );
  }
}