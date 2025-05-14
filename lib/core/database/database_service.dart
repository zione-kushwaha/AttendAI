import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/models/attendance_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  bool _isInitialized = false;

  Future<void> initializeDatabase() async {
    if (_isInitialized) return;

    // Get application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();

    // Initialize Hive with the documents directory path
    await Hive.initFlutter(appDocDir.path);

    // Register adapters
    Hive.registerAdapter(ClassModelAdapter());
    Hive.registerAdapter(StudentModelAdapter());
    Hive.registerAdapter(AttendanceRecordAdapter());
    Hive.registerAdapter(AttendanceStatusAdapter());

    // Open boxes
    await Hive.openBox<ClassModel>('classes');
    await Hive.openBox<StudentModel>('students');
    await Hive.openBox<AttendanceRecord>('attendance');
    await Hive.openBox('settings');

    _isInitialized = true;
  }

  // Class operations
  Box<ClassModel> get classesBox => Hive.box<ClassModel>('classes');

  // Student operations
  Box<StudentModel> get studentsBox => Hive.box<StudentModel>('students');

  // Attendance operations
  Box<AttendanceRecord> get attendanceBox =>
      Hive.box<AttendanceRecord>('attendance');

  // Settings operations
  Box get settingsBox => Hive.box('settings');

  // Close database
  Future<void> closeDatabase() async {
    await Hive.close();
    _isInitialized = false;
  }

  // Clear all data (for reset functionality)
  Future<void> clearAllData() async {
    await classesBox.clear();
    await studentsBox.clear();
    await attendanceBox.clear();
    await settingsBox.clear();
  }

  // Backup data as JSON
  Future<Map<String, dynamic>> exportData() async {
    final Map<String, dynamic> exportData = {
      'classes': classesBox.values.map((e) => e.toJson()).toList(),
      'students': studentsBox.values.map((e) => e.toJson()).toList(),
      'attendance': attendanceBox.values.map((e) => e.toJson()).toList(),
      'settings': settingsBox.toMap(),
    };

    return exportData;
  }

  // Import data from JSON
  Future<void> importData(Map<String, dynamic> data) async {
    await clearAllData();

    // Import classes
    final classesList =
        (data['classes'] as List).map((e) => ClassModel.fromJson(e)).toList();
    await classesBox.addAll(classesList);

    // Import students
    final studentsList =
        (data['students'] as List)
            .map((e) => StudentModel.fromJson(e))
            .toList();
    await studentsBox.addAll(studentsList);

    // Import attendance
    final attendanceList =
        (data['attendance'] as List)
            .map((e) => AttendanceRecord.fromJson(e))
            .toList();
    await attendanceBox.addAll(attendanceList);

    // Import settings
    final settings = data['settings'] as Map;
    await settingsBox.putAll(settings);
  }
}
