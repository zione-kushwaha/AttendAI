import 'package:flutter/material.dart';
import 'package:hajiri/features/home/home_screen_new.dart';
import 'package:hajiri/features/students/student_list_screen.dart';
import 'package:hajiri/features/students/add_edit_student_screen.dart';
import 'package:hajiri/features/students/bulk_add_students_screen.dart';
import 'package:hajiri/features/classes/class_list_screen.dart';
import 'package:hajiri/features/classes/add_edit_class_screen.dart';
import 'package:hajiri/features/attendance/attendance_screen.dart';
import 'package:hajiri/features/attendance/class_attendance_screen.dart';
import 'package:hajiri/features/attendance/take_attendance_screen.dart';
import 'package:hajiri/features/reports/reports_screen.dart';
import 'package:hajiri/features/settings/settings_screen.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/student_model.dart';

import '../../features/classes/class_detail_screen.dart';

/// AppRouter manages all the routes in the application.
/// It provides both named routes and helper methods for navigation.
class AppRouter {
  /// Route names
  static const String home = '/';
  static const String students = '/students';
  static const String addStudent = '/students/add';
  static const String editStudent = '/students/edit';
  static const String bulkAddStudents = '/students/bulk-add';
  static const String classes = '/classes';
  static const String addClass = '/classes/add';
  static const String editClass = '/classes/edit';
  static const String classDetail = '/classes/detail';
  static const String attendance = '/attendance';
  static const String classAttendance = '/attendance/class';
  static const String takeAttendance = '/attendance/take';
  static const String reports = '/reports';
  static const String settings = '/settings';

  /// Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case home:
        builder = (_) => const HomeScreen();
        break;

      case students:
        builder = (_) => const StudentListScreen();
        break;

      case addStudent:
        final args = settings.arguments as Map<String, dynamic>?;
        final preselectedClassId = args?['preselectedClassId'] as String?;
        builder =
            (_) => AddEditStudentScreen(preselectedClassId: preselectedClassId);
        break;

      case editStudent:
        final student = settings.arguments as StudentModel;
        builder = (_) => AddEditStudentScreen(student: student);
        break;

      case bulkAddStudents:
        final classModel = settings.arguments as ClassModel;
        builder = (_) => BulkStudentAddScreen(classModel: classModel);
        break;

      case classes:
        builder = (_) => const ClassListScreen();
        break;

      case addClass:
        builder = (_) => const AddEditClassScreen();
        break;

      case editClass:
        final classModel = settings.arguments as ClassModel;
        builder = (_) => AddEditClassScreen(classModel: classModel);
        break;

      case classDetail:
        final classModel = settings.arguments as ClassModel;
        builder = (_) => ClassDetailScreen(classModel: classModel);
        break;

      case attendance:
        builder = (_) => const AttendanceScreen();
        break;

      case classAttendance:
        final classModel = settings.arguments as ClassModel;
        builder = (_) => ClassAttendanceScreen(classModel: classModel);
        break;

      case takeAttendance:
        final classModel = settings.arguments as ClassModel;
        builder = (_) => TakeAttendanceScreen(classModel: classModel);
        break;

      case reports:
        builder = (_) => const ReportsScreen();
        break;

      case AppRouter.settings:
        builder = (_) => const SettingsScreen();
        break;

      default:
        builder =
            (_) => Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            );
        break;
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
