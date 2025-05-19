import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/features/classes/class_list_screen.dart';
import 'package:hajiri/features/students/student_list_screen.dart';
import 'package:hajiri/features/attendance/attendance_screen.dart';
import 'package:hajiri/features/reports/reports_screen.dart';
import 'package:hajiri/features/settings/settings_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';

import '../../common/widgets/custom_app_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ClassListScreen(),
    const StudentListScreen(),
    const AttendanceScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Classes',
    'Students',
    'Attendance',
    'Reports',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: _titles[_selectedIndex],
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
    final color =
        isSelected
            ? Colors.white
            : (isDarkMode ? AppColors.gray300 : AppColors.gray100);

    return Icon(icon, size: 28, color: color);
  }
}
