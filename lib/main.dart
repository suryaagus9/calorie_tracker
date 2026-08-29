import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'core/utils/app_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await AppLocalizations.init();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const CalTrackApp(),
    ),
  );
}

class CalTrackApp extends StatelessWidget {
  const CalTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLocale,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'CalTrack',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const SplashScreen(),

          onGenerateRoute: (settings) {
            if (settings.name != null && settings.name!.contains('callback')) {
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            }
            return null;
          },

          onUnknownRoute: (settings) {
            return MaterialPageRoute(
                builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  return Scaffold(
                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    body: const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary)),
                  );
                }
            );
          },
        );
      },
    );
  }
}