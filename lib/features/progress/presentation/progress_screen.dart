import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  final bool isActive;
  final int updateToken;

  const ProgressScreen({
    super.key,
    this.isActive = true,
    this.updateToken = 0,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _progressService = ProgressService();
  late int _lastToken;

  bool _isLoadingSummary = true;
  bool _isLoadingCharts = true;

  int _selectedFilter = 0;
  final List<String> _filters = ['week', 'month', 'year'];

  final Map<int, Map<String, dynamic>> _chartCache = {};

  int _summaryAvgCalories = 0;
  int _summaryAvgWater = 0;
  int _summaryWorkouts = 0;
  int _summaryCaloriesBurned = 0;

  List<double> _chartWorkoutRaw = [];
  List<double> _chartBurnedRaw = [];
  List<double> _chartConsumedRaw = [];
  List<double> _chartWaterRaw = [];
  List<String> _chartLabels = [];
  String _chartSubtitleKey = 'last_7_days';

  @override
  void initState() {
    super.initState();
    _lastToken = widget.updateToken;
    _refreshAllData(isSilent: false);
  }

  @override
  void didUpdateWidget(ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (widget.updateToken != _lastToken) {
        _lastToken = widget.updateToken;
        _refreshAllData(isSilent: false);
      } else {
        _refreshAllData(isSilent: true);
      }
    } else if (widget.isActive && widget.updateToken != oldWidget.updateToken) {
      _lastToken = widget.updateToken;
    }
  }

  List<double> _normalizeData(List<double> rawData) {
    if (rawData.isEmpty) return [];
    double maxVal = rawData.reduce(max);
    if (maxVal == 0) return List.filled(rawData.length, 0.0);
    return rawData.map((val) => val / maxVal).toList();
  }

  Future<void> _fetchSummaryData({bool isSilent = false}) async {
    if (!isSilent) setState(() => _isLoadingSummary = true);

    try {
      final today = DateTime.now();
      List<String> last7Days = List.generate(7, (i) => today.subtract(Duration(days: i)).toIso8601String().split('T')[0]);

      // PANGGIL SERVICE
      final data = await _progressService.fetchProgressData(last7Days);

      int totalCalConsumed = (data['meals'] as List).fold(0, (sum, item) => sum + ((item['calories_consumed'] as num?)?.toInt() ?? 0));
      int totalWaterConsumed = (data['water'] as List).fold(0, (sum, item) => sum + ((item['total_water_ml'] as num?)?.toInt() ?? 0));
      int totalCalBurned = (data['workouts'] as List).fold(0, (sum, item) => sum + ((item['calories_burned'] as num?)?.toInt() ?? 0));

      if (mounted) {
        setState(() {
          _summaryAvgCalories = (totalCalConsumed / 7).round();
          _summaryAvgWater = (totalWaterConsumed / 7).round();
          _summaryWorkouts = (data['workouts'] as List).length;
          _summaryCaloriesBurned = totalCalBurned;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${tr('failed')}: Check your internet connection'),
                backgroundColor: Colors.red
            )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _fetchChartData({bool isSilent = false}) async {
    if (_chartCache.containsKey(_selectedFilter)) {
      if (mounted) {
        setState(() {
          final cached = _chartCache[_selectedFilter]!;
          _chartLabels = cached['labels'];
          _chartWorkoutRaw = cached['workout'];
          _chartBurnedRaw = cached['burned'];
          _chartConsumedRaw = cached['consumed'];
          _chartWaterRaw = cached['water'];
          _chartSubtitleKey = cached['subtitleKey'];
        });
      }
      return;
    }

    if (!isSilent) setState(() => _isLoadingCharts = true);

    try {
      final today = DateTime.now();
      int daysToFetch = 7;
      int bucketsCount = 7;

      if (_selectedFilter == 0) {
        daysToFetch = 7; bucketsCount = 7; _chartSubtitleKey = 'last_7_days';
      } else if (_selectedFilter == 1) {
        daysToFetch = 28; bucketsCount = 4; _chartSubtitleKey = 'last_4_weeks';
      } else {
        daysToFetch = 180; bucketsCount = 6; _chartSubtitleKey = 'last_6_months';
      }

      List<String> chartDates = List.generate(daysToFetch, (i) => today.subtract(Duration(days: i)).toIso8601String().split('T')[0]);

      // PANGGIL SERVICE
      final data = await _progressService.fetchProgressData(chartDates);
      final chartMeals = data['meals'] as List;
      final chartWorkouts = data['workouts'] as List;
      final chartWater = data['water'] as List;

      List<double> bucketWorkout = List.filled(bucketsCount, 0.0);
      List<double> bucketBurned = List.filled(bucketsCount, 0.0);
      List<double> bucketConsumed = List.filled(bucketsCount, 0.0);
      List<double> bucketWater = List.filled(bucketsCount, 0.0);
      List<String> bucketLabels = List.filled(bucketsCount, '');

      int daysPerBucket = daysToFetch ~/ bucketsCount;
      const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const monthsOfYear = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      for (int i = 0; i < bucketsCount; i++) {
        DateTime pivotDate = today.subtract(Duration(days: (i * daysPerBucket) + (daysPerBucket ~/ 2)));

        if (_selectedFilter == 0) {
          bucketLabels[bucketsCount - 1 - i] = i == 0 ? 'Today' : daysOfWeek[pivotDate.weekday - 1];
        } else if (_selectedFilter == 1) {
          bucketLabels[bucketsCount - 1 - i] = 'W${4 - i}';
        } else {
          bucketLabels[bucketsCount - 1 - i] = monthsOfYear[pivotDate.month - 1];
        }

        for (int j = 0; j < daysPerBucket; j++) {
          String dStr = today.subtract(Duration(days: (i * daysPerBucket) + j)).toIso8601String().split('T')[0];
          int bIndex = bucketsCount - 1 - i;

          var mealMatch = chartMeals.where((m) => m['date'] == dStr);
          bucketConsumed[bIndex] += mealMatch.fold(0, (sum, item) => sum + ((item['calories_consumed'] as num?)?.toDouble() ?? 0));

          var waterMatch = chartWater.where((w) => w['date'] == dStr);
          bucketWater[bIndex] += waterMatch.fold(0, (sum, item) => sum + ((item['total_water_ml'] as num?)?.toDouble() ?? 0));

          var workMatch = chartWorkouts.where((w) => w['date'] == dStr);
          bucketWorkout[bIndex] += workMatch.fold(0, (sum, item) => sum + ((item['duration_minutes'] as num?)?.toDouble() ?? 0));
          bucketBurned[bIndex] += workMatch.fold(0, (sum, item) => sum + ((item['calories_burned'] as num?)?.toDouble() ?? 0));
        }
      }

      if (mounted) {
        _chartCache[_selectedFilter] = {
          'labels': bucketLabels, 'workout': bucketWorkout, 'burned': bucketBurned, 'consumed': bucketConsumed, 'water': bucketWater, 'subtitleKey': _chartSubtitleKey,
        };
        setState(() {
          _chartLabels = bucketLabels; _chartWorkoutRaw = bucketWorkout; _chartBurnedRaw = bucketBurned; _chartConsumedRaw = bucketConsumed; _chartWaterRaw = bucketWater;
        });
      }
    } catch (e) {
      print('Error loading charts data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCharts = false);
    }
  }

  Future<void> _refreshAllData({bool isSilent = false}) async {
    _chartCache.clear();
    await Future.wait([
      _fetchSummaryData(isSilent: isSilent),
      _fetchChartData(isSilent: isSilent),
    ]);
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

    return ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, child) {
          return Scaffold(
            backgroundColor: Colors.transparent, // Efek Aurora tembus
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
                        Text(tr('progress'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                        const SizedBox(height: 4),
                        Text(tr('track_milestones'), style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _refreshAllData(isSilent: true),
                      color: AppTheme.brandPrimary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 8.0, bottom: 100.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildToggleFilter(theme, isDark),
                            const SizedBox(height: 24),

                            if (_isLoadingCharts)
                              Column(
                                children: [
                                  _buildChartSkeleton(isDark),
                                  const SizedBox(height: 16),
                                  _buildChartSkeleton(isDark),
                                ],
                              )
                            else ...[
                              _buildChartCard(tr('calories_consumed'), '${tr('kcal')} / ${tr(_chartSubtitleKey)}', _chartConsumedRaw, AppTheme.brandPrimary, theme, isDark),
                              const SizedBox(height: 16),
                              _buildChartCard(tr('calories_burned'), '${tr('kcal')} / ${tr(_chartSubtitleKey)}', _chartBurnedRaw, const Color(0xFFF05133), theme, isDark),
                              const SizedBox(height: 16),
                              _buildChartCard(tr('water_intake'), '${tr('ml')} / ${tr(_chartSubtitleKey)}', _chartWaterRaw, Colors.lightBlue, theme, isDark),
                              const SizedBox(height: 16),
                              _buildChartCard(tr('workouts_duration'), '${tr('min')} / ${tr(_chartSubtitleKey)}', _chartWorkoutRaw, Colors.purple.shade300, theme, isDark),
                            ],

                            const SizedBox(height: 40),

                            Text(tr('last_7_days_summary'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                            const SizedBox(height: 16),

                            if (_isLoadingSummary)
                              GridView.count(
                                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.4, crossAxisSpacing: 16, mainAxisSpacing: 16,
                                children: [_buildSummarySkeleton(isDark), _buildSummarySkeleton(isDark), _buildSummarySkeleton(isDark), _buildSummarySkeleton(isDark)],
                              )
                            else
                              GridView.count(
                                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.4, crossAxisSpacing: 16, mainAxisSpacing: 16,
                                children: [
                                  _buildSummaryCard(tr('avg_calories'), '$_summaryAvgCalories', tr('kcal_day'), AppTheme.brandPrimary, theme, isDark),
                                  _buildSummaryCard(tr('avg_water'), '$_summaryAvgWater', tr('ml_day'), Colors.lightBlue, theme, isDark),
                                  _buildSummaryCard(tr('calories_burned'), '$_summaryCaloriesBurned', tr('kcal_week'), const Color(0xFFF05133), theme, isDark),
                                  _buildSummaryCard(tr('workout'), '$_summaryWorkouts', tr('this_week'), Colors.purple.shade300, theme, isDark),
                                ],
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

  Widget _buildChartSkeleton(bool isDark) {
    return Container(height: 220, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(20)));
  }

  Widget _buildSummarySkeleton(bool isDark) {
    return Container(decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(20)));
  }

  Widget _buildToggleFilter(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3))
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          bool isSelected = _selectedFilter == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedFilter != index) {
                  setState(() => _selectedFilter = index);
                  _fetchChartData(isSilent: true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: isSelected ? (isDark ? Colors.black.withOpacity(0.4) : Colors.white) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : []
                ),
                alignment: Alignment.center,
                child: Text(tr(_filters[index]), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? theme.textTheme.displayLarge?.color : theme.textTheme.bodyMedium?.color)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChartCard(String title, String subtitle, List<double> rawValues, Color lineColor, ThemeData theme, bool isDark) {
    List<double> normalizedPoints = _normalizeData(rawValues);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _getSemiTransparentDecoration(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.displayLarge?.color)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            height: 100, width: double.infinity,
            child: CustomPaint(painter: _LineChartPainter(normalizedPoints: normalizedPoints, rawValues: rawValues, lineColor: lineColor, isDark: isDark)),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _chartLabels.map((label) {
              String displayLabel = label == 'Today' ? tr('today') : label;
              return SizedBox(width: 32, child: Text(displayLabel, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)));
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String unit, Color unitColor, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getSemiTransparentDecoration(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.textTheme.displayLarge?.color)),
          const SizedBox(height: 2),
          Text(unit, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: unitColor)),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> normalizedPoints;
  final List<double> rawValues;
  final Color lineColor;
  final bool isDark;

  _LineChartPainter({required this.normalizedPoints, required this.rawValues, required this.lineColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedPoints.isEmpty) return;

    final gridPaint = Paint()..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)..strokeWidth = 1.0;

    int gridLines = 4;
    for (int i = 0; i < gridLines; i++) {
      double y = size.height - (i * (size.height / (gridLines - 1)));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()..color = lineColor..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)]).createShader(Rect.fromLTRB(0, 0, size.width, size.height))..style = PaintingStyle.fill;
    final pointPaint = Paint()..color = lineColor..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    double xSpacing = size.width / (normalizedPoints.length - 1);
    List<Offset> pointCoordinates = [];

    for (int i = 0; i < normalizedPoints.length; i++) {
      double x = i * xSpacing;
      double y = size.height - (normalizedPoints[i] * size.height * 0.85);

      pointCoordinates.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y);
      } else {
        double prevX = (i - 1) * xSpacing;
        double prevY = size.height - (normalizedPoints[i - 1] * size.height * 0.85);
        path.cubicTo(prevX + (xSpacing / 2), prevY, prevX + (xSpacing / 2), y, x, y);
        fillPath.cubicTo(prevX + (xSpacing / 2), prevY, prevX + (xSpacing / 2), y, x, y);
      }

      if (i == normalizedPoints.length - 1) { fillPath.lineTo(x, size.height); fillPath.close(); }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < pointCoordinates.length; i++) {
      Offset point = pointCoordinates[i];
      canvas.drawCircle(point, 3, pointPaint);
      if (rawValues[i] > 0) {
        final textSpan = TextSpan(text: rawValues[i].round().toString(), style: TextStyle(color: lineColor, fontSize: 10, fontWeight: FontWeight.bold));
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        Offset textOffset = Offset(point.dx - (textPainter.width / 2), point.dy - 16);
        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}