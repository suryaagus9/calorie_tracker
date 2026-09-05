import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
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

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _searchSupabaseFoods('');
  }

  void _showCustomSnackBar(String message, {bool isError = true, bool isWarning = false}) {
    if (!mounted) return;

    Color bgColor;
    IconData icon;
    if (isWarning) {
      bgColor = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
    } else if (isError) {
      bgColor = const Color(0xFFEF4444);
      icon = Icons.error_outline_rounded;
    } else {
      bgColor = const Color(0xFF10B981);
      icon = Icons.check_circle_outline_rounded;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        elevation: 10,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: source, maxWidth: 800, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      _showCustomSnackBar('${tr('failed_open_media')}$e');
    }
  }

  Future<void> _processAiInput() async {
    final input = _aiInputCtrl.text.trim();
    if (input.isEmpty && _selectedImageBytes == null) return;

    FocusScope.of(context).unfocus();

    bool isCancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(context);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: Color(0xFF9333EA),
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Icon(Icons.auto_awesome_rounded, color: const Color(0xFF9333EA).withOpacity(0.8), size: 28),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        tr('ai_analyzing'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('scanning_nutrition'),
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 8,
                  right: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, color: theme.textTheme.displayLarge?.color),
                      iconSize: 20,
                      onPressed: () {
                        isCancelled = true;
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );

    try {
      final parsedItems = await _aiService.analyzeFoodsMulti(
        textInput: input,
        imageBytes: _selectedImageBytes,
      ).timeout(const Duration(seconds: 15));

      if (isCancelled) return;
      if (mounted) Navigator.pop(context);

      if (parsedItems.isNotEmpty) {
        setState(() {
          _aiInputCtrl.clear();
        });
        _showAiVerificationSheet(parsedItems);
      } else {
        _showCustomSnackBar(tr('ai_not_detected_error'), isError: false, isWarning: true);
      }
    } on TimeoutException catch (_) {
      if (isCancelled) return;
      if (mounted) {
        Navigator.pop(context);
        _showCustomSnackBar('${tr('ai_timeout')}${tr('check_internet')}');
      }
    } catch (e) {
      if (isCancelled) return;
      if (mounted) {
        Navigator.pop(context);

        String errorMessage = e.toString().replaceAll('Exception: ', '').trim();

        if (errorMessage.toLowerCase().contains('kuota') ||
            errorMessage.toLowerCase().contains('habis') ||
            errorMessage.toLowerCase().contains('quota') ||
            errorMessage.toLowerCase().contains('exhausted')) {

          showDialog(
            context: context,
            builder: (ctx) {
              final theme = Theme.of(context);
              return AlertDialog(
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('ai_busy_title'),
                        style: TextStyle(color: theme.textTheme.displayLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  '${tr('sorry')}$errorMessage\n\n${tr('manual_search_suggestion')}',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      tr('got_it'),
                      style: const TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          _showCustomSnackBar(errorMessage);
        }
      }
    }
  }

  void _showFullScreenImage(BuildContext context, List<Map<String, dynamic>> parsedItems, ThemeData theme) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      barrierDismissible: true,
      barrierLabel: 'Close',
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.memory(_selectedImageBytes!),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: BoundingBoxPainter(parsedItems, theme.textTheme.bodyMedium ?? const TextStyle()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24)
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(tr('ai_verification_result'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                  Text(tr('remove_unnecessary_options'), style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                  const SizedBox(height: 16),

                  if (_selectedImageBytes != null) ...[
                    Center(
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(context, parsedItems, theme),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.memory(_selectedImageBytes!),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: BoundingBoxPainter(parsedItems, theme.textTheme.bodyMedium ?? const TextStyle()),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Expanded(
                    child: ListView.separated(
                      itemCount: parsedItems.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                      itemBuilder: (ctx, index) {
                        final item = parsedItems[index];
                        final matches = item['matches'] as List<Map<String, dynamic>>;
                        final fallback = item['fallback'];

                        // PERBAIKAN: Jika item yang dipilih adalah indeks terakhir (matches.length), itu berarti AI Estimasi terpilih
                        bool isAiEst = selectedIndices[index] == matches.length ||
                            (selectedIndices[index] < matches.length && matches[selectedIndices[index]]['name'].toString().contains('(AI Est.)'));

                        final List<Color> boxColors = const [
                          Color(0xFF9333EA), Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFFEAB308),
                        ];
                        Color currentBoxColor = boxColors[index % boxColors.length];

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: isAiEst ? currentBoxColor.withOpacity(isDark ? 0.15 : 0.05) : theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isAiEst ? currentBoxColor.withOpacity(0.5) : theme.dividerColor,
                                  width: isAiEst ? 1.5 : 1
                              )
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(isAiEst ? Icons.auto_awesome_rounded : Icons.cloud_done_rounded,
                                      size: 18,
                                      color: isAiEst ? currentBoxColor : AppTheme.brandPrimary
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${tr('ai_detected')} ${item['keyword']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
                                  ),
                                  if (isAiEst)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: currentBoxColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                      child: Text(tr('new_ai_badge'), style: TextStyle(fontSize: 10, color: currentBoxColor, fontWeight: FontWeight.bold)),
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
                                decoration: BoxDecoration(
                                    color: isAiEst ? (isDark ? currentBoxColor.withOpacity(0.2) : currentBoxColor.withOpacity(0.1)) : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(12)
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedIndices[index],
                                    isExpanded: true,
                                    dropdownColor: theme.cardColor,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.displayLarge?.color),
                                    items: [
                                      // Looping untuk opsi dari database Supabase
                                      for (int j = 0; j < matches.length; j++)
                                        DropdownMenuItem(
                                            value: j,
                                            child: Text(
                                                '${matches[j]['name']} (${matches[j]['calories']} ${tr('kcal')})',
                                                style: TextStyle(
                                                  color: matches[j]['name'].toString().contains('(AI Est.)') ? currentBoxColor : theme.textTheme.displayLarge?.color,
                                                  fontWeight: matches[j]['name'].toString().contains('(AI Est.)') ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis
                                            )
                                        ),
                                      // PERBAIKAN: Selalu tampilkan opsi AI Estimasi sebagai pilihan terakhir
                                      DropdownMenuItem(
                                          value: matches.length, // Nilai value adalah panjang data matches
                                          child: Text(
                                              '${tr('use_ai_estimation')} (${fallback['calories']} ${tr('kcal')})',
                                              style: TextStyle(color: currentBoxColor, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis
                                          )
                                      ),
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

                        setState(() {
                          _selectedImageBytes = null;
                        });

                        // PERBAIKAN: Format tanggal hari ini menggunakan INTL
                        String currentDateStr = DateFormat('d MMM').format(DateTime.now());

                        List<Map<String, dynamic>> cartToProcess = [];
                        for (int i = 0; i < parsedItems.length; i++) {
                          final item = parsedItems[i];
                          final matches = item['matches'] as List<Map<String, dynamic>>;
                          final fallback = item['fallback'];
                          final selIdx = selectedIndices[i];
                          final qty = item['quantity'];

                          // Jika memilih dari database (indeks kurang dari matches.length)
                          if (matches.isNotEmpty && selIdx < matches.length) {
                            final dbFood = matches[selIdx];
                            bool isNewAi = dbFood['name'].toString().contains('(AI Est.)');

                            cartToProcess.add({'food_id': dbFood['id'].toString(), 'name': dbFood['name'], 'base_cal': (dbFood['calories'] as num?)?.toDouble() ?? 0.0, 'base_p': (dbFood['protein'] as num?)?.toDouble() ?? 0.0, 'base_c': (dbFood['carbs'] as num?)?.toDouble() ?? 0.0, 'base_f': (dbFood['fat'] as num?)?.toDouble() ?? 0.0, 'portion': qty, 'meal_type': _getDefaultMealType(), 'is_custom': isNewAi});
                          } else {
                            // Jika memilih AI Estimasi (indeks sama dengan matches.length atau matches kosong)
                            // PERBAIKAN: Tambahkan tanggal pada format namanya
                            cartToProcess.add({'food_id': null, 'name': '${fallback['name']} (AI Est. - $currentDateStr)', 'base_cal': (fallback['calories'] as num?)?.toDouble() ?? 0.0, 'base_p': (fallback['protein'] as num?)?.toDouble() ?? 0.0, 'base_c': (fallback['carbs'] as num?)?.toDouble() ?? 0.0, 'base_f': (fallback['fat'] as num?)?.toDouble() ?? 0.0, 'portion': qty, 'meal_type': _getDefaultMealType(), 'is_custom': true});
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
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _selectedImageBytes = null;
      });
    });
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
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
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
                                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('AI Est.', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
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

                            if (item['is_custom'] == true && foodId == null) {
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
                            _showCustomSnackBar(tr('successfully_added_log'), isError: false);
                          }
                        } catch (e) {
                          _showCustomSnackBar('${tr('failed')}: $e');
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
      _showCustomSnackBar(tr('fill_name_calories'));
      return;
    }
    try {
      await _foodService.createCustomFood(
          _customNameCtrl.text.trim(), _parseNumber(_customCalCtrl.text), _parseNumber(_customProteinCtrl.text), _parseNumber(_customCarbsCtrl.text), _parseNumber(_customFatCtrl.text)
      );

      if (mounted) {
        Navigator.pop(context);
        _dataChanged = true;
        _showCustomSnackBar(tr('custom_food_saved'), isError: false);
        if (isAllSelected) _searchSupabaseFoods(searchQuery);
        else _fetchRecentFoods(searchQuery);
      }
    } catch (e) {
      _showCustomSnackBar(tr('failed_create_custom_food'));
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
              resizeToAvoidBottomInset: false,
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
                            label: Text(tr('custom_food').replaceAll(' Food', ''), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.brandPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withOpacity(isDark ? 0.15 : 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                          border: Border.all(
                            color: const Color(0xFF9333EA).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9333EA).withOpacity(0.1),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9333EA), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Smart Scanner',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (_selectedImageBytes != null)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedImageBytes = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _aiInputCtrl,
                                      style: TextStyle(color: theme.textTheme.displayLarge?.color, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: tr('ask_ai'),
                                        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      onSubmitted: (_) => _processAiInput(),
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: theme.dividerColor,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.camera_alt_rounded, color: theme.textTheme.bodyMedium?.color),
                                    iconSize: 20,
                                    splashRadius: 20,
                                    onPressed: () => _pickImage(ImageSource.camera),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.image_rounded, color: theme.textTheme.bodyMedium?.color),
                                    iconSize: 20,
                                    splashRadius: 20,
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF9333EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                                      iconSize: 18,
                                      splashRadius: 20,
                                      onPressed: _processAiInput,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                                      Text('${food['base_cal']} ${tr('kcal')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.brandPrimary)),
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

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> aiItems;
  final TextStyle baseTextStyle;

  final List<Color> boxColors = const [
    Color(0xFF9333EA), Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFFEAB308),
  ];

  BoundingBoxPainter(this.aiItems, this.baseTextStyle);

  @override
  void paint(Canvas canvas, Size size) {
    if (aiItems.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < aiItems.length; i++) {
      var item = aiItems[i];

      Color currentColor = boxColors[i % boxColors.length];

      final paint = Paint()
        ..color = currentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      List<dynamic> boxRaw = item['box_2d'] ?? [0, 0, 0, 0];
      if (boxRaw.length == 4 && boxRaw.every((val) => val > 0)) {
        double ymin = (boxRaw[0] / 1000) * size.height;
        double xmin = (boxRaw[1] / 1000) * size.width;
        double ymax = (boxRaw[2] / 1000) * size.height;
        double xmax = (boxRaw[3] / 1000) * size.width;

        final rect = Rect.fromLTRB(xmin, ymin, xmax, ymax);

        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

        String label = item['keyword'] ?? '';

        textPainter.text = TextSpan(
          text: ' $label ',
          style: baseTextStyle.copyWith(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: currentColor,
            decoration: TextDecoration.none,
          ),
        );
        textPainter.layout();

        double textY = ymin - textPainter.height - 4;
        if (textY < 0) textY = ymin + 4;

        textPainter.paint(canvas, Offset(xmin, textY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return true;
  }
}