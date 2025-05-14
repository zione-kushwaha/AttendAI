import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/features/classes/class_list_screen_content.dart';
import 'package:hajiri/features/students/student_list_screen_content.dart';
import 'package:hajiri/features/attendance/attendance_screen_content.dart';
import 'package:hajiri/features/reports/reports_screen_content.dart';
import 'package:hajiri/features/settings/settings_screen_content.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';

// Provider to store and manage the screen title
final screenTitleProvider = StateProvider<String>((ref) => 'Classes');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // List of screen titles
  final List<String> _screenTitles = [
    'Classes',
    'Students',
    'Attendance',
    'Reports',
    'Settings',
  ];

  late final List<Widget> _screens = [
    const ClassListScreenContent(),
    const StudentListScreenContent(),
    const AttendanceScreenContent(),
    const ReportsScreenContent(),
    const SettingsScreenContent(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize screen title on the next frame to avoid build-time modifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenTitleProvider.notifier).state =
          _screenTitles[_selectedIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: CustomAppBar(
        title: _screenTitles[_selectedIndex],
        showBackButton: false,
      ),
      body: _screens[_selectedIndex].animate(
        key: ValueKey(_selectedIndex),
        effects: [
          FadeEffect(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.primary,
        buttonBackgroundColor: AppColors.primary,
        height: 60,
        index: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // Update screen title when index changes
            ref.read(screenTitleProvider.notifier).state = _screenTitles[index];
          });
        },
        animationDuration: const Duration(milliseconds: 300),
        items: [
          _buildNavItem(Icons.class_, _selectedIndex == 0, isDarkMode),
          _buildNavItem(Icons.people, _selectedIndex == 1, isDarkMode),
          _buildNavItem(Icons.fact_check, _selectedIndex == 2, isDarkMode),
          _buildNavItem(Icons.assessment, _selectedIndex == 3, isDarkMode),
          _buildNavItem(Icons.settings, _selectedIndex == 4, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected, bool isDarkMode) {
    return Icon(
      icon,
      size: 26,
      color: isSelected || isDarkMode ? Colors.white : Colors.white70,
    );
  }
}
