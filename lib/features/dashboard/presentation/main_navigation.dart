import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localization.dart';
import 'dashboard_screen.dart';
import 'package:calorie_tracker/features/tracker/presentation/food_log_screen.dart';
import '../../tracker/presentation/workout_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _globalUpdateToken = 0;

  void _notifyDataChanged() {
    setState(() {
      _globalUpdateToken++;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // --- KOMPONEN: AURORA BACKGROUND ---
  Widget _buildAuroraBackground(bool isDark) {
    return Stack(
      children: [
        Container(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),

        Positioned(
          top: -100, left: -100,
          child: Container(
            width: 350, height: 350,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF4C1D95).withOpacity(0.5) : const Color(0xFFD8B4FE).withOpacity(0.6)
            ),
          ),
        ),

        Positioned(
          bottom: 100, right: -150,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF064E3B).withOpacity(0.4) : const Color(0xFF86EFAC).withOpacity(0.5)
            ),
          ),
        ),

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        )
      ],
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
            extendBody: true,
            backgroundColor: Colors.transparent,

            body: Stack(
              children: [
                _buildAuroraBackground(isDark),

                IndexedStack(
                  index: _currentIndex,
                  children: [
                    DashboardScreen(isActive: _currentIndex == 0, updateToken: _globalUpdateToken, onDataChanged: _notifyDataChanged, onNavigateToWorkout: () => _onTabTapped(2)),
                    FoodLogScreen(updateToken: _globalUpdateToken, onDataChanged: _notifyDataChanged),
                    WorkoutScreen(updateToken: _globalUpdateToken, onDataChanged: _notifyDataChanged),
                    ProgressScreen(isActive: _currentIndex == 3, updateToken: _globalUpdateToken),
                    ProfileScreen(updateToken: _globalUpdateToken, onDataChanged: _notifyDataChanged),
                  ],
                ),
              ],
            ),

            // --- KOMPONEN: FLOATING GLASSMORPHISM BOTTOM NAV BAR ---
            bottomNavigationBar: SafeArea( // Menggunakan SafeArea agar tidak tertutup indikator home iPhone
              child: Padding(
                // Jarak dari kiri, kanan, dan bawah agar melayang
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 24.0),
                child: ClipRRect(
                  // Membuat sudut membulat sempurna (Pil)
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(32),
                        // Border mengelilingi seluruh sisi untuk efek kaca penuh
                        border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.5),
                            width: 1.5
                        ),
                      ),
                      child: BottomNavigationBar(
                        currentIndex: _currentIndex,
                        onTap: _onTabTapped,
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: Colors.transparent,
                        selectedItemColor: AppTheme.brandPrimary,
                        unselectedItemColor: theme.textTheme.bodyMedium?.color,
                        showUnselectedLabels: true,
                        selectedFontSize: 10,
                        unselectedFontSize: 10,
                        elevation: 0,
                        items: [
                          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: tr('hello').contains('Halo') ? 'Beranda' : 'Home'),
                          BottomNavigationBarItem(icon: const Icon(Icons.restaurant_rounded), label: tr('food_log')),
                          BottomNavigationBarItem(icon: const Icon(Icons.fitness_center_rounded), label: tr('workout')),
                          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_rounded), label: tr('progress')),
                          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: tr('profile')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
    );
  }
}