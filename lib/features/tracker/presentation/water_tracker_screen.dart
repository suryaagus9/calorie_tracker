import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/services/water_service.dart';

class WaterTrackerScreen extends StatefulWidget {
  final int? initialWater;
  final int? initialTarget;

  const WaterTrackerScreen({super.key, this.initialWater, this.initialTarget});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  final _waterService = WaterService();

  bool _isLoading = true;
  bool _dataChanged = false;

  double _sliderValue = 250;
  int _waterConsumed = 0;
  int _waterTarget = 2500;

  @override
  void initState() {
    super.initState();
    // Jika data dilempar dari layar sebelumnya, langsung tampilkan tanpa loading!
    if (widget.initialWater != null && widget.initialTarget != null) {
      _waterConsumed = widget.initialWater!;
      _waterTarget = widget.initialTarget!;
      _isLoading = false;
      _fetchWaterData(isSilent: true); // Update secara senyap di latar belakang
    } else {
      _fetchWaterData(); // Mode standar jika tidak ada data awal
    }
  }

  Future<void> _fetchWaterData({bool isSilent = false}) async {
    if (!isSilent) setState(() => _isLoading = true);
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final data = await _waterService.fetchWaterData(todayStr);

      if (mounted) {
        setState(() {
          _waterTarget = data['target'];
          _waterConsumed = data['consumed'];
        });
      }
    } catch (e) {
      print('Error fetching water: $e');
      if (mounted && !isSilent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: ${tr('check_internet')}'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWater(int amount) async {
    final newTotal = _waterConsumed + amount;
    // UI langsung diperbarui seketika (Optimistic UI)
    setState(() { _waterConsumed = newTotal; _dataChanged = true; });

    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await _waterService.updateWater(todayStr, newTotal);
    } catch (e) {
      setState(() => _waterConsumed -= amount); // Kembalikan ke semula jika gagal
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed')}: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resetWater() async {
    final previousTotal = _waterConsumed;
    setState(() { _waterConsumed = 0; _dataChanged = true; });

    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await _waterService.updateWater(todayStr, 0);
    } catch (e) {
      setState(() => _waterConsumed = previousTotal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double progress = _waterTarget > 0 ? _waterConsumed / _waterTarget : 0.0;
    if (progress > 1.0) progress = 1.0;

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
                              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
                              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.textTheme.displayLarge?.color),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(tr('water_tracker'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _isLoading
                          ? _buildSkeletonLoader(isDark)
                          : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFDEF2FF), borderRadius: BorderRadius.circular(24)),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 200, height: 200,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // ANIMASI REAL-TIME: Lingkaran Air Bergerak Mulus
                                        TweenAnimationBuilder<double>(
                                            tween: Tween<double>(begin: 0, end: progress),
                                            duration: const Duration(milliseconds: 1200),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, value, child) {
                                              return CircularProgressIndicator(
                                                  value: value,
                                                  strokeWidth: 20,
                                                  backgroundColor: isDark ? Colors.blue.shade900 : Colors.lightBlue.shade100,
                                                  color: const Color(0xFF0EA5E9),
                                                  strokeCap: StrokeCap.round
                                              );
                                            }
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.water_drop_rounded, size: 40, color: Color(0xFF0EA5E9)),

                                            // ANIMASI REAL-TIME: Angka bergulir seperti mesin koin
                                            TweenAnimationBuilder<int>(
                                                tween: IntTween(begin: 0, end: _waterConsumed),
                                                duration: const Duration(milliseconds: 1200),
                                                curve: Curves.easeOutCubic,
                                                builder: (context, value, child) {
                                                  return Text('$value', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: theme.textTheme.displayLarge?.color, height: 1.1));
                                                }
                                            ),
                                            Text('/ $_waterTarget ${tr('ml')}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                  onPressed: _resetWater,
                                  child: Text(tr('reset_todays_water'), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500, fontSize: 14))
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text(tr('add_water'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildWaterButton('+150 ${tr('ml')}', tr('small_glass'), 150)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildWaterButton('+250 ${tr('ml')}', tr('regular_glass'), 250)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildWaterButton('+500 ${tr('ml')}', tr('bottle'), 500)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('custom_amount'), style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            activeTrackColor: const Color(0xFF0EA5E9),
                                            inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                            thumbColor: const Color(0xFF0EA5E9),
                                            trackHeight: 8,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                                          ),
                                          child: Slider(value: _sliderValue, min: 0, max: 2000, onChanged: (val) => setState(() => _sliderValue = val)),
                                        ),
                                      ),
                                      SizedBox(width: 50, child: Text('${_sliderValue.toInt()} ${tr('ml')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9), fontSize: 12), textAlign: TextAlign.right))
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity, height: 48,
                                    child: ElevatedButton(
                                      onPressed: () => _addWater(_sliderValue.toInt()),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                                      child: Text(tr('add_custom_amount'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
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

  Widget _buildWaterButton(String title, String subtitle, int amount) {
    return GestureDetector(
      onTap: () => _addWater(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    Color skeletonColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 48), decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(24)), child: Center(child: Container(width: 200, height: 200, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, shape: BoxShape.circle)))),
          const SizedBox(height: 16),
          Center(child: Container(width: 140, height: 16, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 32),
          Container(width: 100, height: 20, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: Container(height: 70, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(16)))), const SizedBox(width: 12), Expanded(child: Container(height: 70, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(16)))), const SizedBox(width: 12), Expanded(child: Container(height: 70, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(16))))]),
          const SizedBox(height: 24),
          Container(height: 160, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(20))),
        ],
      ),
    );
  }
}