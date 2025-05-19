import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/core/database/database_service.dart';
import 'package:hajiri/core/router/app_router.dart';
import 'package:hajiri/features/auth/pin_screen.dart';
import 'package:hajiri/features/home/home_screen.dart';
import 'package:hajiri/providers/settings_provider.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';

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
    final settings = ref.watch(settingsProvider);
    final isPinEnabled = settings['pinEnabled'] as bool? ?? false;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AttendAI',
      theme: theme,
      onGenerateRoute: AppRouter.generateRoute,
      // Show PinScreen if PIN is enabled, otherwise show HomeScreen
      home: isPinEnabled ? const PinScreen() : const HomeScreen(),
    );
  }
}
