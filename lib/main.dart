import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/core/database/database_service.dart';
import 'package:hajiri/core/router/app_router.dart';
import 'package:hajiri/providers/settings_provider.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

final enhancedThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);
  final isDarkMode = settings['isDarkMode'] as bool? ?? false;

  return isDarkMode ? AppThemeEnhanced.darkTheme : AppThemeEnhanced.lightTheme;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  final db = DatabaseService();
  await db.initializeDatabase();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the theme based on settings
    final theme = ref.watch(enhancedThemeProvider);

    return MaterialApp(
      title: 'Hajiri',
      theme: theme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Simulate loading
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.8), AppColors.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fact_check,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  )
                  .animate()
                  .fade(duration: const Duration(milliseconds: 800))
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 40),
              Text(
                    'Hajiri',
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  )
                  .animate()
                  .fade(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 400),
                  )
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 400),
                    curve: Curves.easeOutQuad,
                  ),
              const SizedBox(height: 8),
              Text(
                'Offline Attendance Manager',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 1.2,
                ),
              ).animate().fade(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 600),
              ),
              const SizedBox(height: 50),
              SpinKitPulse(color: Colors.white, size: 50.0),
            ],
          ),
        ),
      ),
    );
  }
}
