import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/workout_service.dart';

class WorkoutScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  final int updateToken;

  const WorkoutScreen({super.key, this.onDataChanged, this.updateToken = 0});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _workoutService = WorkoutService();
  bool _isLoading = true;

  double _userWeightKg = 70.0;
  int _totalCaloriesBurned = 0;
  int _totalDurationMinutes = 0;

  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _todayWorkouts = [];

  double _parseSafeDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  int _parseSafeInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) {
      double parsedDouble = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
      return parsedDouble.toInt();
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _fetchWorkoutData();
  }

  @override
  void didUpdateWidget(WorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updateToken != oldWidget.updateToken) {
      _fetchWorkoutData(isSilent: false);
    }
  }

  Future<void> _fetchWorkoutData({bool isSilent = false}) async {
    if (!isSilent) setState(() => _isLoading = true);

    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final data = await _workoutService.fetchWorkoutData(todayStr);

      _userWeightKg = _parseSafeDouble(data['weight_kg']);
      if (_userWeightKg <= 0) _userWeightKg = 70.0;

      _allExercises = List<Map<String, dynamic>>.from(data['exercises']);

      int totalCal = 0;
      int totalMin = 0;
      List<Map<String, dynamic>> logs = [];

      for (var row in data['logs']) {
        int cal = _parseSafeInt(row['calories_burned']);
        int min = _parseSafeInt(row['duration_minutes']);
        totalCal += cal;
        totalMin += min;

        String name = row['exercises']?['name']?.toString() ?? tr('unknown');

        logs.add({
          'id': row['id'].toString(),
          'name': name,
          'desc': '$min ${tr('min')} • $cal ${tr('kcal')}',
          'cal': cal,
          'min': min,
        });
      }

      if (mounted) {
        setState(() {
          _totalCaloriesBurned = totalCal;
          _totalDurationMinutes = totalMin;
          _todayWorkouts = logs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkoutLog(String logId, int calDeduct, int minDeduct) async {
    setState(() {
      _todayWorkouts.removeWhere((item) => item['id'] == logId);
      _totalCaloriesBurned -= calDeduct;
      if (_totalCaloriesBurned < 0) _totalCaloriesBurned = 0;
      _totalDurationMinutes -= minDeduct;
      if (_totalDurationMinutes < 0) _totalDurationMinutes = 0;
    });

    try {
      await _workoutService.deleteWorkout(logId);
      await _fetchWorkoutData(isSilent: true);
      widget.onDataChanged?.call();
    } catch (e) {
      await _fetchWorkoutData(isSilent: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.red));
    }
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

    int hours = _totalDurationMinutes ~/ 60;
    int minutes = _totalDurationMinutes % 60;
    String durationText = hours > 0 ? '$hours ${tr('h')} $minutes ${tr('min')}' : '$minutes ${tr('min')}';

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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('workout'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                            const SizedBox(height: 4),
                            Text(tr('track_and_log_exercises'), style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _isLoading
                        ? _buildSkeletonLoader(isDark)
                        : RefreshIndicator(
                      onRefresh: () => _fetchWorkoutData(isSilent: true),
                      color: const Color(0xFFF05133),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 8.0, bottom: 100.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEF4444)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tr('calories_burned_today'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text('$_totalCaloriesBurned', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1)),
                                          const SizedBox(width: 8),
                                          Text(tr('kcal'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule, color: Colors.white70, size: 16),
                                          const SizedBox(width: 6),
                                          Text(durationText, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    right: 0, top: 0, bottom: 0,
                                    child: Center(child: Icon(Icons.local_fire_department, size: 80, color: Colors.yellow.withOpacity(0.8))),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text(tr('categories'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color, letterSpacing: 1.5)),
                            const SizedBox(height: 16),

                            // PERBAIKAN: Mengganti GridView menjadi Column > Row > Expanded agar responsif mutlak
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildCategoryCard(tr('cardio'), tr('run_cycling'), Icons.directions_run, () => _showSelectExerciseBottomSheet(context, 'Cardio', theme, isDark), theme, isDark)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildCategoryCard(tr('strength'), tr('weightlifting'), Icons.fitness_center, () => _showSelectExerciseBottomSheet(context, 'Strength', theme, isDark), theme, isDark)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _buildCategoryCard(tr('stretching'), tr('yoga'), Icons.self_improvement, () => _showSelectExerciseBottomSheet(context, 'Stretching', theme, isDark), theme, isDark)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildCategoryCard(tr('sports'), tr('football_basket'), Icons.sports_soccer, () => _showSelectExerciseBottomSheet(context, 'Sports', theme, isDark), theme, isDark)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            Text(tr('todays_workouts'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                            const SizedBox(height: 16),

                            if (_todayWorkouts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text(tr('no_workouts_today'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
                              )
                            else
                              ..._todayWorkouts.map((workout) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildWorkoutLogItem(workout, theme, isDark),
                              )).toList(),

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
          Container(width: double.infinity, height: 160, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 32),
          Container(width: 100, height: 16, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          // PERBAIKAN SKELETON: Menyesuaikan dengan susunan Row yang baru
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 120, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20)))),
                  const SizedBox(width: 16),
                  Expanded(child: Container(height: 120, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20)))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Container(height: 120, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20)))),
                  const SizedBox(width: 16),
                  Expanded(child: Container(height: 120, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20)))),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, IconData icon, VoidCallback onTap, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // PERBAIKAN: Padding vertikal statis agar tinggi kartu tetap konsisten dan tidak terlalu memanjang
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFF05133), size: 36),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.displayLarge?.color)),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutLogItem(Map<String, dynamic> item, ThemeData theme, bool isDark) {
    int itemCal = (item['cal'] as num?)?.toInt() ?? 0;
    int itemMin = (item['min'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getSemiTransparentDecoration(theme, isDark),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF78350F) : Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.fitness_center, color: isDark ? Colors.orange.shade300 : Colors.orange.shade400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? tr('unknown'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.displayLarge?.color), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item['desc'] ?? '', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteWorkoutLog(item['id'].toString(), itemCal, itemMin),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF7F1D1D) : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
            ),
          )
        ],
      ),
    );
  }

  void _showSelectExerciseBottomSheet(BuildContext context, String categoryName, ThemeData theme, bool isDark) {
    int selectedIndex = 0;
    int workoutDuration = 30;
    String searchQuery = '';
    bool isSaving = false;
    const double datasetBaseWeightKg = 70.0;

    List<Map<String, dynamic>> baseExercises = _allExercises.where((ex) {
      final cat = ex['category']?.toString().toLowerCase() ?? '';
      return cat.contains(categoryName.toLowerCase());
    }).toList();

    if (baseExercises.isEmpty) baseExercises = _allExercises;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              List<Map<String, dynamic>> filteredExercises = baseExercises.where((ex) {
                return ex['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
              }).toList();

              int estimatedBurn = 0;
              if (filteredExercises.isNotEmpty && selectedIndex < filteredExercises.length) {
                int baseCal = _parseSafeInt(filteredExercises[selectedIndex]['cal_per_hour']);
                double ratio = _userWeightKg / datasetBaseWeightKg;
                double calPerHourForUser = baseCal * ratio;
                estimatedBurn = (calPerHourForUser * (workoutDuration / 60.0)).round();
              }

              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 24),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('select_exercise'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                          Text('${tr('category')}: ${tr(categoryName.toLowerCase())}', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        onChanged: (val) { setModalState(() { searchQuery = val; selectedIndex = 0; }); },
                        style: TextStyle(color: theme.textTheme.displayLarge?.color),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
                          hintText: tr('find_exercise'),
                          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          filled: true,
                          fillColor: theme.cardColor,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF05133))),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: filteredExercises.isEmpty
                            ? Center(child: Text(tr('no_exercises_found'), style: TextStyle(color: theme.textTheme.bodyMedium?.color)))
                            : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                          itemCount: filteredExercises.length,
                          itemBuilder: (context, index) {
                            bool isSelected = selectedIndex == index;
                            int baseCal = _parseSafeInt(filteredExercises[index]['cal_per_hour']);
                            int calPerHourForUser = (baseCal * (_userWeightKg / datasetBaseWeightKg)).round();

                            return GestureDetector(
                              onTap: () { setModalState(() { selectedIndex = index; }); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFDE6E4)) : theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? const Color(0xFFF05133) : theme.dividerColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: isDark ? const Color(0xFF78350F) : Colors.orange.shade50, shape: BoxShape.circle),
                                      child: Icon(Icons.fitness_center, size: 16, color: isDark ? Colors.orange.shade300 : Colors.orange.shade400),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(filteredExercises[index]['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.textTheme.displayLarge?.color), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          Text('~$calPerHourForUser ${tr('kcal')}/hr', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
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
                      const SizedBox(height: 12),

                      Text(tr('duration_minutes'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => setModalState(() { workoutDuration = (workoutDuration - 5).clamp(5, 300); }),
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.remove, size: 18, color: theme.textTheme.displayLarge?.color)),
                          ),
                          Column(
                            children: [
                              Text('$workoutDuration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                              Text(tr('min'), style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
                            ],
                          ),
                          InkWell(
                            onTap: () => setModalState(() { workoutDuration = (workoutDuration + 5).clamp(5, 300); }),
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.add, size: 18, color: theme.textTheme.displayLarge?.color)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFDE6E4), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Text(tr('estimated_burn'), style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text('$estimatedBurn ${tr('kcal')}', style: const TextStyle(color: Color(0xFFF05133), fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (filteredExercises.isEmpty || isSaving) ? null : () async {
                            setModalState(() => isSaving = true);
                            try {
                              final todayStr = DateTime.now().toIso8601String().split('T')[0];

                              setState(() {
                                _todayWorkouts.add({
                                  'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                                  'name': filteredExercises[selectedIndex]['name'],
                                  'desc': '$workoutDuration ${tr('min')} • $estimatedBurn ${tr('kcal')}',
                                  'cal': estimatedBurn,
                                  'min': workoutDuration,
                                });
                                _totalDurationMinutes += workoutDuration;
                                _totalCaloriesBurned += estimatedBurn;
                              });

                              Navigator.pop(context, true);

                              await _workoutService.addWorkout(
                                  filteredExercises[selectedIndex]['id'],
                                  todayStr,
                                  workoutDuration,
                                  estimatedBurn
                              );

                              _fetchWorkoutData(isSilent: true);
                              widget.onDataChanged?.call();
                            } catch (e) {
                              _fetchWorkoutData(isSilent: true);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.red));
                            } finally {
                              if (mounted) setModalState(() => isSaving = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF05133), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                          child: isSaving
                              ? const SizedBox(width: 20, height: 20, child: CupertinoActivityIndicator(color: Colors.white))
                              : Text(tr('save_workout'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }
}