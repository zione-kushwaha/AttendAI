import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/common/widgets/empty_state_widget.dart';
import 'package:hajiri/core/utils/attendance_report_generator.dart';
import 'package:hajiri/features/attendance/take_attendance_screen.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/attendance_model.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/providers/attendance_provider.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ClassAttendanceScreen extends ConsumerStatefulWidget {
  final ClassModel classModel;

  const ClassAttendanceScreen({Key? key, required this.classModel})
    : super(key: key);

  @override
  ConsumerState<ClassAttendanceScreen> createState() =>
      _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends ConsumerState<ClassAttendanceScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRecords = ref.watch(attendanceProvider);
    final students =
        ref
            .watch(studentProvider)
            .where((student) => student.classIds.contains(widget.classModel.id))
            .toList();

    // Get all attendance for the selected day
    final selectedDayAttendance =
        attendanceRecords
            .where(
              (record) =>
                  record.classId == widget.classModel.id &&
                  _isSameDay(record.date, _selectedDay),
            )
            .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.classModel.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: () => _showAttendanceStats(context),
            tooltip: 'View Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.how_to_reg),
            onPressed: () => _navigateToTakeAttendance(context),
            tooltip: 'Take Attendance',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(attendanceRecords),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMMd().format(_selectedDay),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Present: ${_getAttendanceCount(selectedDayAttendance, AttendanceStatus.present)}/${students.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                selectedDayAttendance.isEmpty
                    ? EmptyStateWidget(
                      message: 'No attendance records for this day',
                      icon: Icons.event_busy,
                      buttonText: 'Take Attendance',
                      onButtonPressed: () => _navigateToTakeAttendance(context),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: selectedDayAttendance.length,
                      itemBuilder: (context, index) {
                        final record = selectedDayAttendance[index];
                        return _buildAttendanceRecord(record, students);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<AttendanceRecord> attendanceRecords) {
    final events = _getEventsForClass(attendanceRecords);

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: (day) => events[day] ?? [],
      selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 3,
        markerDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonShowsNext: false,
        formatButtonDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        formatButtonTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildAttendanceRecord(
    AttendanceRecord record,
    List<StudentModel> students,
  ) {
    // Find student for this attendance record
    final student = students.firstWhere(
      (student) => student.id == record.studentId,
      orElse:
          () => StudentModel(
            name: 'Unknown Student',
            rollNumber: 'N/A',
            classIds: [widget.classModel.id],
          ),
    );

    // Status color and icon
    final statusInfo = _getStatusInfo(record.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusInfo['color'],
          child: Icon(statusInfo['icon'], color: Colors.white),
        ),
        title: Text(student.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roll No: ${student.rollNumber}'),
            if (record.remark != null && record.remark!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Remark: ${record.remark}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        trailing: Text(
          statusInfo['label'],
          style: TextStyle(
            color: statusInfo['color'],
            fontWeight: FontWeight.bold,
          ),
        ),
        isThreeLine: record.remark != null && record.remark!.isNotEmpty,
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return {
          'label': 'Present',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case AttendanceStatus.absent:
        return {'label': 'Absent', 'color': Colors.red, 'icon': Icons.cancel};
      case AttendanceStatus.late:
        return {
          'label': 'Late',
          'color': Colors.orange,
          'icon': Icons.access_time,
        };
      case AttendanceStatus.excused:
        return {
          'label': 'Excused',
          'color': Colors.blue,
          'icon': Icons.medical_services,
        };
    }
  }

  Map<DateTime, List<AttendanceRecord>> _getEventsForClass(
    List<AttendanceRecord> records,
  ) {
    final events = <DateTime, List<AttendanceRecord>>{};

    for (final record in records) {
      if (record.classId == widget.classModel.id) {
        final day = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );

        if (events[day] != null) {
          events[day]!.add(record);
        } else {
          events[day] = [record];
        }
      }
    }

    return events;
  }

  int _getAttendanceCount(
    List<AttendanceRecord> records,
    AttendanceStatus status,
  ) {
    return records.where((record) => record.status == status).length;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _navigateToTakeAttendance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => TakeAttendanceScreen(classModel: widget.classModel),
      ),
    );
  }

  void _showAttendanceStats(BuildContext context) {
    final attendanceNotifier = ref.read(attendanceProvider.notifier);

    // Calculate monthly statistics
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final monthlyStats = attendanceNotifier.getClassAttendanceStats(
      widget.classModel.id,
      startDate: currentMonth,
      endDate: nextMonth,
    );

    // Calculate total statistics
    final allTimeStats = attendanceNotifier.getClassAttendanceStats(
      widget.classModel.id,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Statistics',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.classModel.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'This Month (${DateFormat.MMMM().format(currentMonth)})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          context,
                          'Present',
                          monthlyStats['presentCount'] ?? 0,
                          monthlyStats['totalRecords'] ?? 0,
                          (monthlyStats['presentPercentage'] ?? 0).toDouble(),
                          Colors.green,
                        ),
                        _buildStatCard(
                          context,
                          'Absent',
                          monthlyStats['absentCount'] ?? 0,
                          monthlyStats['totalRecords'] ?? 0,
                          ((monthlyStats['absentCount'] ?? 0).toDouble() /
                              ((monthlyStats['totalRecords'] ?? 0) > 0
                                  ? (monthlyStats['totalRecords'] ?? 1)
                                      .toDouble()
                                  : 1) *
                              100),
                          Colors.red,
                        ),
                        _buildStatCard(
                          context,
                          'Late',
                          monthlyStats['lateCount'] ?? 0,
                          monthlyStats['totalRecords'] ?? 0,
                          ((monthlyStats['lateCount'] ?? 0).toDouble() /
                              ((monthlyStats['totalRecords'] ?? 0) > 0
                                  ? (monthlyStats['totalRecords'] ?? 1)
                                      .toDouble()
                                  : 1) *
                              100),
                          Colors.orange,
                        ),
                        _buildStatCard(
                          context,
                          'Excused',
                          monthlyStats['excusedCount'] ?? 0,
                          monthlyStats['totalRecords'] ?? 0,
                          ((monthlyStats['excusedCount'] ?? 0).toDouble() /
                              ((monthlyStats['totalRecords'] ?? 0) > 0
                                  ? (monthlyStats['totalRecords'] ?? 1)
                                      .toDouble()
                                  : 1) *
                              100),
                          Colors.blue,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'All Time Statistics',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCircle(
                              'Present',
                              '${(allTimeStats['presentPercentage']?.toStringAsFixed(1) ?? '0.0')}%',
                              Colors.green,
                            ),
                            _buildStatCircle(
                              'Absent',
                              '${((allTimeStats['absentCount'] ?? 0).toDouble() / ((allTimeStats['totalRecords'] ?? 0) > 0 ? (allTimeStats['totalRecords'] ?? 1).toDouble() : 1.0) * 100).toStringAsFixed(1)}%',
                              Colors.red,
                            ),
                            _buildStatCircle(
                              'Late',
                              '${((allTimeStats['lateCount'] ?? 0).toDouble() / ((allTimeStats['totalRecords'] ?? 0) > 0 ? (allTimeStats['totalRecords'] ?? 1).toDouble() : 1.0) * 100).toStringAsFixed(1)}%',
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _generateReport(context),
                                icon: const Icon(Icons.download),
                                label: const Text('Export Report'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int count,
    int total,
    double percentage,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '$count/$total',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCircle(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _generateReport(BuildContext context) async {
    final attendanceRecords = ref.read(attendanceProvider);
    final students =
        ref
            .read(studentProvider)
            .where((student) => student.classIds.contains(widget.classModel.id))
            .toList();

    // Calculate monthly statistics
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final attendanceNotifier = ref.read(attendanceProvider.notifier);

    final monthlyStats = attendanceNotifier.getClassAttendanceStats(
      widget.classModel.id,
      startDate: currentMonth,
      endDate: nextMonth,
    );

    // Calculate total statistics
    final allTimeStats = attendanceNotifier.getClassAttendanceStats(
      widget.classModel.id,
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Generating Report...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your attendance report',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Generate PDF report
      final pdfFile =
          await AttendanceReportGenerator.generateClassAttendanceReport(
            classModel: widget.classModel,
            students: students,
            attendanceRecords:
                attendanceRecords
                    .where((record) => record.classId == widget.classModel.id)
                    .toList(),
            monthlyStats: monthlyStats,
            allTimeStats: allTimeStats,
          );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog with share option
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Report Generated'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your attendance report has been generated successfully.'),
                SizedBox(height: 12),
                Text(
                  'File name: ${pdfFile.path.split('/').last}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await AttendanceReportGenerator.shareReport(pdfFile);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Failed to generate report: ${e.toString()}'),
                SizedBox(height: 12),
                Text(
                  'Troubleshooting tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('• Check your device has enough storage space'),
                Text('• Make sure you have necessary file permissions'),
                Text('• Try again with a smaller date range'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _generateReport(context); // Try again
                },
                child: const Text('Try Again'),
              ),
            ],
          );
        },
      );
    }
  }
}
