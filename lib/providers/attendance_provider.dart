import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/core/database/database_service.dart';
import 'package:hajiri/models/attendance_model.dart';

class AttendanceNotifier extends StateNotifier<List<AttendanceRecord>> {
  final DatabaseService _db = DatabaseService();

  AttendanceNotifier() : super([]) {
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    state = _db.attendanceBox.values.toList();
  }

  // Mark attendance for a student
  Future<void> markAttendance(AttendanceRecord record) async {
    // Check if an attendance record already exists for this student on this date
    final existingRecord =
        state
            .where(
              (element) =>
                  element.studentId == record.studentId &&
                  element.classId == record.classId &&
                  _isSameDay(element.date, record.date),
            )
            .toList();

    if (existingRecord.isNotEmpty) {
      // Update existing record
      existingRecord.first.updateStatus(record.status, remark: record.remark);
    } else {
      // Add new record
      await _db.attendanceBox.add(record);
    }

    _loadAttendance();
  }

  // Update an attendance record
  Future<void> updateAttendance(AttendanceRecord record) async {
    await record.save();
    _loadAttendance();
  }

  // Delete an attendance record
  Future<void> deleteAttendance(String recordId) async {
    final recordToDelete = _db.attendanceBox.values.firstWhere(
      (element) => element.id == recordId,
      orElse: () => throw Exception('Attendance record not found'),
    );

    await recordToDelete.delete();
    _loadAttendance();
  }

  // Get all attendance records for a class on a specific date
  List<AttendanceRecord> getAttendanceByClassAndDate(
    String classId,
    DateTime date,
  ) {
    return state
        .where(
          (record) =>
              record.classId == classId && _isSameDay(record.date, date),
        )
        .toList();
  }

  // Get attendance record for a specific student, class, and date
  AttendanceRecord? getAttendanceRecord(
    String studentId,
    String classId,
    DateTime date,
  ) {
    try {
      return state.firstWhere(
        (record) =>
            record.studentId == studentId &&
            record.classId == classId &&
            _isSameDay(record.date, date),
      );
    } catch (_) {
      return null;
    }
  }

  // Get all attendance records for a student
  List<AttendanceRecord> getStudentAttendanceHistory(String studentId) {
    return state.where((record) => record.studentId == studentId).toList();
  }

  // Get attendance statistics for a class
  Map<String, dynamic> getClassAttendanceStats(
    String classId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final records =
        state
            .where(
              (record) =>
                  record.classId == classId &&
                  (startDate == null || record.date.isAfter(startDate)) &&
                  (endDate == null || record.date.isBefore(endDate)),
            )
            .toList();

    int totalRecords = records.length;
    int presentCount =
        records
            .where((record) => record.status == AttendanceStatus.present)
            .length;
    int absentCount =
        records
            .where((record) => record.status == AttendanceStatus.absent)
            .length;
    int lateCount =
        records
            .where((record) => record.status == AttendanceStatus.late)
            .length;
    int excusedCount =
        records
            .where((record) => record.status == AttendanceStatus.excused)
            .length;

    return {
      'totalRecords': totalRecords,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'lateCount': lateCount,
      'excusedCount': excusedCount,
      'presentPercentage':
          totalRecords > 0 ? (presentCount / totalRecords * 100) : 0,
    };
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>((ref) {
      return AttendanceNotifier();
    });
