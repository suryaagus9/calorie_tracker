import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data slide dengan warna khusus untuk Light & Dark Mode
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Track Calories Easily',
      'description': 'Log your meals in seconds with our smart food\ndatabase tailored for Indonesian cuisine',
      'icon': Icons.assignment_outlined,
      'iconColor': AppTheme.brandPrimary,
      'lightBg': const Color(0xFFF0FDF4),
      'darkBg': const Color(0xFF064E3B), // Hijau gelap
    },
    {
      'title': 'Monitor Water Intake',
      'description': 'Stay hydrated with quick water logging and\nvisual progress tracking throughout your day',
      'icon': Icons.water_drop_rounded,
      'iconColor': const Color(0xFF0EA5E9),
      'lightBg': const Color(0xFFF0F9FF),
      'darkBg': const Color(0xFF0C4A6E), // Biru gelap
    },
    {
      'title': 'Reach Your Goals',
      'description': 'Whether bulking or cutting, CalTrack helps you\nstay on target with clear progress insights',
      'icon': Icons.bolt_rounded,
      'iconColor': const Color(0xFFF59E0B),
      'lightBg': const Color(0xFFFFFBEB),
      'darkBg': const Color(0xFF78350F), // Oranye/cokelat gelap
    },
  ];

  void _nextAction() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    }
  }

  void _skipAction() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mendeteksi tema aktif (Dark/Light)
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dinamis
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlideContent(_slides[index], isDark, theme);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // Indikator Titik (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                          (index) => _buildDotIndicator(index, isDark),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _skipAction,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.textTheme.bodyMedium?.color,
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color, // Teks Dinamis
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desain Konten Utama setiap Slide
  Widget _buildSlideContent(Map<String, dynamic> slideData, bool isDark, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: isDark ? slideData['darkBg'] : slideData['lightBg'], // Lingkaran Dinamis
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              slideData['icon'],
              size: 90,
              color: slideData['iconColor'],
            ),
          ),
        ),
        const SizedBox(height: 48),

        Text(
          slideData['title'],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: theme.textTheme.displayLarge?.color, // Teks Judul Dinamis
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            slideData['description'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color, // Teks Deskripsi Dinamis
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Animasi Indikator Titik
  Widget _buildDotIndicator(int index, bool isDark) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.brandPrimary
            : (isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)), // Warna Titik Dinamis
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}