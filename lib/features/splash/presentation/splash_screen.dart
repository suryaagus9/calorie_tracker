import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../dashboard/presentation/main_navigation.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialNavigation();
  }

  Future<void> _checkInitialNavigation() async {
    // 1. Tahan splash screen selama 2.5 detik agar animasi cantik Anda tetap terlihat
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // 2. Cek status Onboarding di memori perangkat
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      // Jika user belum pernah melihat onboarding (Baru Install), arahkan ke Onboarding
      await prefs.setBool('hasSeenOnboarding', true); // Tandai agar tidak muncul lagi

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
      return; // Hentikan eksekusi di sini
    }

    // 3. Jika sudah melewati Onboarding, cek sesi login Supabase
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Sesi aktif (User belum logout), langsung masuk ke dalam aplikasi
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } else {
      // Sesi kosong (User sudah logout), arahkan ke Login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4ADE80),
              Color(0xFF16A34A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Ikon Tengah dengan Efek Glassmorphism
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tipografi Judul
            const Text(
              'CalTrack',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SMART CALORIE TRACKER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),

            const Spacer(),

            // Indikator Loading
            const Padding(
              padding: EdgeInsets.only(bottom: 64.0),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}