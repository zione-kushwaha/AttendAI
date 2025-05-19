import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hajiri/common/widgets/empty_state_widget.dart';
import 'package:hajiri/models/attendance_model.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/attendance_provider.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:hajiri/providers/student_provider.dart';

import '../../models/student_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedClassId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classProvider);

    return Scaffold(
      body:
          classes.isEmpty
              ? const EmptyStateWidget(
                message:
                    'No classes available for reports.\nAdd classes to generate reports.',
                icon: Icons.bar_chart,
              )
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportTypeCard(
                      title: 'Attendance Report',
                      description: 'Generate detailed attendance reports',
                      icon: Icons.fact_check,
                      onTap:
                          () => _showAttendanceReportDialog(context, classes),
                    ),
                    _buildReportTypeCard(
                      title: 'Student Summary',
                      description: 'Individual student attendance records',
                      icon: Icons.person,
                      onTap: () => _showStudentReportDialog(context, classes),
                    ),
                    _buildReportTypeCard(
                      title: 'Class Statistics',
                      description: 'Class-wide attendance analytics',
                      icon: Icons.pie_chart,
                      onTap: () => _showClassStatisticsDialog(context, classes),
                    ),
                    if (_isGenerating)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Generating report...'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildReportTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceReportDialog(
    BuildContext context,
    List<ClassModel> classes,
  ) {
    _selectedClassId = classes.isNotEmpty ? classes.first.id : null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Generate Attendance Report'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Class',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        value: _selectedClassId,
                        items:
                            classes
                                .map(
                                  (classItem) => DropdownMenuItem<String>(
                                    value: classItem.id,
                                    child: Text(classItem.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedClassId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_startDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_endDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (_selectedClassId != null) {
                          _generateAttendanceReport(_selectedClassId!);
                        }
                      },
                      child: const Text('Generate'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _generateAttendanceReport(String classId) async {
    setState(() => _isGenerating = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Validate date range
      if (_startDate.isAfter(_endDate)) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Start date must be before end date')),
        );
        return;
      }

      final classItem = ref
          .read(classProvider)
          .firstWhere((c) => c.id == classId);
      final students =
          ref
              .read(studentProvider)
              .where((student) => student.classIds.contains(classId))
              .toList()
            ..sort(
              (a, b) =>
                  int.parse(a.rollNumber).compareTo(int.parse(b.rollNumber)),
            );

      // Check for empty student list
      if (students.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No students found in this class')),
        );
        return;
      }

      final attendanceRecords =
          ref
              .read(attendanceProvider)
              .where(
                (record) =>
                    record.classId == classId &&
                    record.date.isAfter(
                      _startDate.subtract(const Duration(days: 1)),
                    ) &&
                    record.date.isBefore(_endDate.add(const Duration(days: 1))),
              )
              .toList();

      // Check for empty attendance records
      if (attendanceRecords.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No attendance records found for this period'),
          ),
        );
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 50),
                  pw.Text(
                    'Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    classItem.name,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Generated on: ${DateFormat.yMMMMd().format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'Total Students: ${students.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      );

      // Add summary page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    text: 'Attendance Summary',
                    textStyle: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox(
                        'Present',
                        attendanceRecords
                            .where((r) => r.status == AttendanceStatus.present)
                            .length,
                        PdfColors.green,
                        120,
                      ),
                      _buildStatBox(
                        'Absent',
                        attendanceRecords
                            .where((r) => r.status == AttendanceStatus.absent)
                            .length,
                        PdfColors.red,
                        120,
                      ),
                      _buildStatBox(
                        'Late',
                        attendanceRecords
                            .where((r) => r.status == AttendanceStatus.late)
                            .length,
                        PdfColors.orange,
                        120,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Header(
                    text: 'Attendance by Day of Week',
                    textStyle: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildWeekdayAttendanceTable(attendanceRecords),
                ],
              ),
        ),
      ); // Get all dates in the range
      final allDates = _getDatesInRange(_startDate, _endDate);

      // Calculate page layout parameters
      final pageFormat = PdfPageFormat.a4.landscape;
      final double pageWidth = pageFormat.availableWidth;
      final double pageHeight = pageFormat.availableHeight;
      const double rollNoWidth = 50; // Fixed width for roll number column
      const double nameWidth = 120; // Fixed width for name column
      const double dateColumnWidth = 40; // Width for each date column
      const double rowHeight = 25; // Height for each student row
      const double headerHeight = 100; // Height for header section
      const double footerHeight = 30; // Height for footer section

      // Calculate how many date columns can fit on one page horizontally
      final int datesPerPage =
          ((pageWidth - rollNoWidth - nameWidth) / dateColumnWidth).floor();

      // Calculate how many students can fit on one page vertically
      final int studentsPerPage =
          ((pageHeight - headerHeight - footerHeight) / rowHeight).floor();

      // Split dates into chunks that will fit on a page horizontally
      final dateChunks = <List<DateTime>>[];
      for (int i = 0; i < allDates.length; i += datesPerPage) {
        final end =
            i + datesPerPage < allDates.length
                ? i + datesPerPage
                : allDates.length;
        dateChunks.add(allDates.sublist(i, end));
      }

      // Split students into chunks that will fit on a page vertically
      final studentChunks = <List<StudentModel>>[];
      for (int i = 0; i < students.length; i += studentsPerPage) {
        final end =
            i + studentsPerPage < students.length
                ? i + studentsPerPage
                : students.length;
        studentChunks.add(students.sublist(i, end));
      }

      // For each combination of date chunk and student chunk, create a new page
      int totalPages = dateChunks.length * studentChunks.length;
      int currentPage = 0;

      for (
        int dateChunkIndex = 0;
        dateChunkIndex < dateChunks.length;
        dateChunkIndex++
      ) {
        final dateChunk = dateChunks[dateChunkIndex];

        for (
          int studentChunkIndex = 0;
          studentChunkIndex < studentChunks.length;
          studentChunkIndex++
        ) {
          currentPage++;
          final studentChunk = studentChunks[studentChunkIndex];

          pdf.addPage(
            pw.Page(
              pageFormat: pageFormat,
              build:
                  (context) => pw.Column(
                    children: [
                      pw.Header(
                        text:
                            'Detailed Attendance Records (Page $currentPage of $totalPages)',
                        textStyle: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Date Range: ${DateFormat('dd/MM').format(dateChunk.first)} - ${DateFormat('dd/MM').format(dateChunk.last)}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            'Sorted by Roll Number',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      pw.Expanded(
                        child: pw.Table.fromTextArray(
                          context: context,
                          border: pw.TableBorder.all(color: PdfColors.grey300),
                          headerStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          headerDecoration: pw.BoxDecoration(
                            color: PdfColors.blue700,
                          ),
                          headers: [
                            'Roll No',
                            'Name',
                            ...dateChunk.map(
                              (d) => DateFormat('dd/MM').format(d),
                            ),
                          ],
                          data:
                              studentChunk
                                  .map(
                                    (student) => [
                                      student.rollNumber,
                                      student.name,
                                      ...dateChunk.map((date) {
                                        final record = attendanceRecords
                                            .firstWhere(
                                              (r) =>
                                                  r.studentId == student.id &&
                                                  _isSameDay(r.date, date),
                                              orElse:
                                                  () => AttendanceRecord(
                                                    classId: classId,
                                                    studentId: student.id,
                                                    date: date,
                                                    status:
                                                        AttendanceStatus.absent,
                                                  ),
                                            );
                                        return _getStatusSymbol(record.status);
                                      }),
                                    ],
                                  )
                                  .toList(),
                          cellAlignment: pw.Alignment.center,
                          cellStyle: const pw.TextStyle(fontSize: 10),
                          headerAlignment: pw.Alignment.center,
                          columnWidths: {
                            0: const pw.FixedColumnWidth(
                              rollNoWidth,
                            ), // Roll No
                            1: const pw.FixedColumnWidth(nameWidth), // Name
                          },
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Status Legend: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text('P - Present, '),
                          pw.Text('A - Absent, '),
                          pw.Text('L - Late, '),
                          pw.Text('E - Excused'),
                        ],
                      ),
                    ],
                  ),
            ),
          );
        }
      }

      // Save the PDF
      final output = await getTemporaryDirectory();
      final fileName =
          'attendance_report_${classItem.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      if (context.mounted) {
        await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: fileName,
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating report: ${e.toString()}')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  pw.Widget _buildWeekdayAttendanceTable(List<AttendanceRecord> records) {
    final dayCounts = _buildWeeklyAttendanceData(records);

    return pw.TableHelper.fromTextArray(
      headers: ['Day', 'Present', 'Total', 'Attendance %'],
      data: [
        for (int i = 0; i < 7; i++)
          [
            _getWeekdayName(i + 1),
            dayCounts[i]['present'].toString(),
            dayCounts[i]['total'].toString(),
            dayCounts[i]['total']! > 0
                ? '${((dayCounts[i]['present']! / dayCounts[i]['total']!) * 100).toStringAsFixed(1)}%'
                : '0%',
          ],
      ],
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.blue700),
      cellAlignment: pw.Alignment.center,
    );
  }

  List<Map<String, int>> _buildWeeklyAttendanceData(
    List<AttendanceRecord> records,
  ) {
    final dayCounts = List.generate(7, (index) => {'present': 0, 'total': 0});

    for (final record in records) {
      final weekday = record.date.weekday - 1; // 0=Monday
      dayCounts[weekday]['total'] = dayCounts[weekday]['total']! + 1;
      if (record.status == AttendanceStatus.present) {
        dayCounts[weekday]['present'] = dayCounts[weekday]['present']! + 1;
      }
    }

    return dayCounts;
  }

  // Helper methods for PDF generation
  pw.Widget _buildStatBox(
    String title,
    int count,
    PdfColor color,
    double width,
  ) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '$count',
            style: pw.TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _getDatesInRange(DateTime startDate, DateTime endDate) {
    final days = <DateTime>[];
    var currentDay = startDate;

    while (currentDay.isBefore(endDate) || _isSameDay(currentDay, endDate)) {
      days.add(currentDay);
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getStatusSymbol(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.late:
        return 'L';
      case AttendanceStatus.excused:
        return 'E';
    }
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  void _showStudentReportDialog(
    BuildContext context,
    List<ClassModel> classes,
  ) {
    _selectedClassId = classes.isNotEmpty ? classes.first.id : null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Generate Student Summary'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Class',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        value: _selectedClassId,
                        items:
                            classes
                                .map(
                                  (classItem) => DropdownMenuItem<String>(
                                    value: classItem.id,
                                    child: Text(classItem.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedClassId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: _endDate,
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_startDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_endDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (_selectedClassId != null) {
                          _generateStudentSummaryReport(_selectedClassId!);
                        }
                      },
                      child: const Text('Generate'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _generateStudentSummaryReport(String classId) async {
    setState(() => _isGenerating = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Validate date range
      if (_startDate.isAfter(_endDate)) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Start date must be before end date')),
        );
        return;
      }

      final classItem = ref
          .read(classProvider)
          .firstWhere((c) => c.id == classId);
      final students =
          ref
              .read(studentProvider)
              .where((student) => student.classIds.contains(classId))
              .toList()
            ..sort(
              (a, b) =>
                  int.parse(a.rollNumber).compareTo(int.parse(b.rollNumber)),
            );

      // Check for empty student list
      if (students.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No students found in this class')),
        );
        return;
      }

      final attendanceRecords =
          ref
              .read(attendanceProvider)
              .where(
                (record) =>
                    record.classId == classId &&
                    record.date.isAfter(
                      _startDate.subtract(const Duration(days: 1)),
                    ) &&
                    record.date.isBefore(_endDate.add(const Duration(days: 1))),
              )
              .toList();

      // Check for empty attendance records
      if (attendanceRecords.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No attendance records found for this period'),
          ),
        );
        return;
      }

      // Create PDF document
      final pdf = pw.Document();
      final pageFormat = PdfPageFormat.a4;

      // Add cover page
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 50),
                  pw.Text(
                    'Student Attendance Summary',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    classItem.name,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Generated on: ${DateFormat.yMMMMd().format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'Total Students: ${students.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      );

      // Calculate how many students can fit in a single page
      const int studentsPerPage =
          25; // This can be adjusted based on design needs

      // Split students into chunks that will fit on each page
      final studentChunks = <List<StudentModel>>[];
      for (int i = 0; i < students.length; i += studentsPerPage) {
        final end =
            i + studentsPerPage < students.length
                ? i + studentsPerPage
                : students.length;
        studentChunks.add(students.sublist(i, end));
      }

      // For each chunk of students, create a new page
      for (int pageIndex = 0; pageIndex < studentChunks.length; pageIndex++) {
        final pageTitle =
            studentChunks.length > 1
                ? 'Student Attendance Summary (Page ${pageIndex + 1} of ${studentChunks.length})'
                : 'Student Attendance Summary';

        final studentChunk = studentChunks[pageIndex];

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build:
                (context) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Header(
                      text: pageTitle,
                      textStyle: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Sorted by Roll Number',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 20),
                    pw.TableHelper.fromTextArray(
                      context: context,
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration: pw.BoxDecoration(
                        color: PdfColors.blue700,
                      ),
                      headers: [
                        'Roll No',
                        'Name',
                        'Present',
                        'Absent',
                        'Late',
                        'Attendance %',
                      ],
                      data:
                          studentChunk.map((student) {
                            final records =
                                attendanceRecords
                                    .where((r) => r.studentId == student.id)
                                    .toList();

                            final present =
                                records
                                    .where(
                                      (r) =>
                                          r.status == AttendanceStatus.present,
                                    )
                                    .length;
                            final absent =
                                records
                                    .where(
                                      (r) =>
                                          r.status == AttendanceStatus.absent,
                                    )
                                    .length;
                            final late =
                                records
                                    .where(
                                      (r) => r.status == AttendanceStatus.late,
                                    )
                                    .length;
                            final total = records.length;
                            final percentage =
                                total > 0 ? (present / total * 100) : 0;

                            // Color code based on attendance percentage
                            final color =
                                percentage < 75
                                    ? PdfColors.red
                                    : percentage < 85
                                    ? PdfColors.orange
                                    : PdfColors.green;

                            return [
                              student.rollNumber,
                              student.name,
                              present.toString(),
                              absent.toString(),
                              late.toString(),
                              pw.Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: pw.TextStyle(color: color),
                              ),
                            ];
                          }).toList(),
                      cellAlignment: pw.Alignment.center,
                      cellStyle: const pw.TextStyle(fontSize: 10),
                      headerAlignment: pw.Alignment.center,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Attendance Percentage Legend: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Below 75% ',
                          style: pw.TextStyle(color: PdfColors.red),
                        ),
                        pw.Text('| '),
                        pw.Text(
                          '75-85% ',
                          style: pw.TextStyle(color: PdfColors.orange),
                        ),
                        pw.Text('| '),
                        pw.Text(
                          'Above 85%',
                          style: pw.TextStyle(color: PdfColors.green),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        );
      }

      // Save the PDF
      final output = await getTemporaryDirectory();
      final fileName =
          'student_summary_${classItem.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      if (context.mounted) {
        await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: fileName,
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating report: ${e.toString()}')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showClassStatisticsDialog(
    BuildContext context,
    List<ClassModel> classes,
  ) {
    _selectedClassId = classes.isNotEmpty ? classes.first.id : null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Generate Class Statistics'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Class',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        value: _selectedClassId,
                        items:
                            classes
                                .map(
                                  (classItem) => DropdownMenuItem<String>(
                                    value: classItem.id,
                                    child: Text(classItem.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedClassId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: _endDate,
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_startDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_endDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (_selectedClassId != null) {
                          _generateClassStatisticsReport(_selectedClassId!);
                        }
                      },
                      child: const Text('Generate'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _generateClassStatisticsReport(String classId) async {
    setState(() => _isGenerating = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Validate date range
      if (_startDate.isAfter(_endDate)) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Start date must be before end date')),
        );
        return;
      }

      final classItem = ref
          .read(classProvider)
          .firstWhere((c) => c.id == classId);
      final students =
          ref
              .read(studentProvider)
              .where((student) => student.classIds.contains(classId))
              .toList();

      // Check for empty student list
      if (students.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No students found in this class')),
        );
        return;
      }

      final attendanceRecords =
          ref
              .read(attendanceProvider)
              .where(
                (record) =>
                    record.classId == classId &&
                    record.date.isAfter(
                      _startDate.subtract(const Duration(days: 1)),
                    ) &&
                    record.date.isBefore(_endDate.add(const Duration(days: 1))),
              )
              .toList();

      // Check for empty attendance records
      if (attendanceRecords.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No attendance records found for this period'),
          ),
        );
        return;
      }

      // Calculate statistics
      final totalRecords = attendanceRecords.length;
      final presentCount =
          attendanceRecords
              .where((r) => r.status == AttendanceStatus.present)
              .length;
      final absentCount =
          attendanceRecords
              .where((r) => r.status == AttendanceStatus.absent)
              .length;
      final lateCount =
          attendanceRecords
              .where((r) => r.status == AttendanceStatus.late)
              .length;

      // Calculate daily averages
      final daysInRange = _endDate.difference(_startDate).inDays + 1;
      final avgPresentPerDay =
          daysInRange > 0 ? presentCount / daysInRange.toDouble() : 0.0;
      final avgAbsentPerDay =
          daysInRange > 0 ? absentCount / daysInRange.toDouble() : 0.0;

      // Create PDF document
      final pdf = pw.Document();

      // Add cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 50),
                  pw.Text(
                    'Class Attendance Statistics',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    classItem.name,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Generated on: ${DateFormat.yMMMMd().format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'Total Students: ${students.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      );

      // Add statistics page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      'Class Attendance Statistics',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Period: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox(
                        'Present',
                        presentCount,
                        PdfColors.green,
                        120,
                      ),
                      _buildStatBox('Absent', absentCount, PdfColors.red, 120),
                      _buildStatBox('Late', lateCount, PdfColors.orange, 120),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Daily Averages',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Average Present per Day:'),
                            pw.Text(
                              '${avgPresentPerDay.toStringAsFixed(1)}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Average Absent per Day:'),
                            pw.Text(
                              '${avgAbsentPerDay.toStringAsFixed(1)}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Attendance by Day of Week',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildWeekdayAttendanceTable(attendanceRecords),
                ],
              ),
        ),
      ); // Add attendance distribution overview page
      // Define student pagination constants
      const int studentsPerPage = 24;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      'Attendance Distribution (Overview)',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      _buildAttendanceDistributionCircle(
                        'Present',
                        presentCount,
                        totalRecords,
                        PdfColors.green,
                      ),
                      pw.SizedBox(width: 20),
                      _buildAttendanceDistributionCircle(
                        'Absent',
                        absentCount,
                        totalRecords,
                        PdfColors.red,
                      ),
                      pw.SizedBox(width: 20),
                      _buildAttendanceDistributionCircle(
                        'Late',
                        lateCount,
                        totalRecords,
                        PdfColors.orange,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      'Attendance Rate by Student',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // If the student count is small enough to fit on one page, just show the table
                  ...(() {
                    if (students.length <= studentsPerPage) {
                      return [
                        pw.TableHelper.fromTextArray(
                          headers: [
                            'Roll No',
                            'Name',
                            'Present Days',
                            'Total Days',
                            'Attendance Rate',
                          ],
                          data:
                              students.map((student) {
                                final studentRecords =
                                    attendanceRecords
                                        .where((r) => r.studentId == student.id)
                                        .toList();

                                final presentDays =
                                    studentRecords
                                        .where(
                                          (r) =>
                                              r.status ==
                                              AttendanceStatus.present,
                                        )
                                        .length;
                                final totalDays = studentRecords.length;
                                final attendanceRate =
                                    totalDays > 0
                                        ? (presentDays / totalDays * 100)
                                        : 0;

                                return [
                                  student.rollNumber,
                                  student.name,
                                  presentDays.toString(),
                                  totalDays.toString(),
                                  '${attendanceRate.toStringAsFixed(1)}%',
                                ];
                              }).toList(),
                          cellAlignment: pw.Alignment.center,
                          cellStyle: const pw.TextStyle(fontSize: 10),
                          headerStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          headerDecoration: pw.BoxDecoration(
                            color: PdfColors.blue700,
                          ),
                          border: pw.TableBorder.all(color: PdfColors.grey300),
                          headerAlignment: pw.Alignment.center,
                        ),
                      ];
                    } else {
                      return [
                        pw.Text(
                          'Student attendance data will be displayed on following pages',
                          style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            fontSize: 10,
                          ),
                        ),
                      ];
                    }
                  })(),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        color: PdfColors.green,
                      ),
                      pw.SizedBox(width: 5),
                      pw.Text('Above 85%'),
                      pw.SizedBox(width: 15),
                      pw.Container(
                        width: 12,
                        height: 12,
                        color: PdfColors.orange,
                      ),
                      pw.SizedBox(width: 5),
                      pw.Text('75% - 85%'),
                      pw.SizedBox(width: 15),
                      pw.Container(width: 12, height: 12, color: PdfColors.red),
                      pw.SizedBox(width: 5),
                      pw.Text('Below 75%'),
                    ],
                  ),
                ],
              ),
        ),
      );

      // Add student attendance details pages with pagination
      if (students.length > studentsPerPage) {
        // Split students into chunks for pagination
        final studentChunks = <List<StudentModel>>[];
        for (var i = 0; i < students.length; i += studentsPerPage) {
          final end =
              (i + studentsPerPage < students.length)
                  ? i + studentsPerPage
                  : students.length;
          studentChunks.add(students.sublist(i, end));
        }

        // Add a page for each chunk of students
        for (var pageIndex = 0; pageIndex < studentChunks.length; pageIndex++) {
          final pageStudents = studentChunks[pageIndex];

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build:
                  (context) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Header(
                        level: 0,
                        child: pw.Text(
                          'Student Attendance Details (Page ${pageIndex + 1} of ${studentChunks.length})',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.TableHelper.fromTextArray(
                        headers: [
                          'Roll No',
                          'Name',
                          'Present Days',
                          'Total Days',
                          'Attendance Rate',
                        ],
                        data:
                            pageStudents.map((student) {
                              final studentRecords =
                                  attendanceRecords
                                      .where((r) => r.studentId == student.id)
                                      .toList();

                              final presentDays =
                                  studentRecords
                                      .where(
                                        (r) =>
                                            r.status ==
                                            AttendanceStatus.present,
                                      )
                                      .length;
                              final totalDays = studentRecords.length;
                              final attendanceRate =
                                  totalDays > 0
                                      ? (presentDays / totalDays * 100)
                                      : 0;

                              return [
                                student.rollNumber,
                                student.name,
                                presentDays.toString(),
                                totalDays.toString(),
                                '${attendanceRate.toStringAsFixed(1)}%',
                              ];
                            }).toList(),
                        cellAlignment: pw.Alignment.center,
                        cellStyle: const pw.TextStyle(fontSize: 10),
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        headerDecoration: pw.BoxDecoration(
                          color: PdfColors.blue700,
                        ),
                        border: pw.TableBorder.all(color: PdfColors.grey300),
                        headerAlignment: pw.Alignment.center,
                      ),
                      pw.Expanded(child: pw.SizedBox()),
                      pw.Footer(
                        leading: pw.Text(
                          'Class: ${classItem.name}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        title: pw.Text(
                          'Page ${pageIndex + 1} of ${studentChunks.length}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
            ),
          );
        }
      }

      // Save the PDF
      final output = await getTemporaryDirectory();
      final fileName =
          'class_statistics_${classItem.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      if (context.mounted) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Class Statistics Report');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating report: ${e.toString()}')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  pw.Widget _buildAttendanceDistributionCircle(
    String label,
    int count,
    int total,
    PdfColor color,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return pw.Column(
      children: [
        pw.Container(
          width: 100,
          height: 100,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: color, width: 3),
          ),
          child: pw.Center(
            child: pw.Text(
              '${percentage.toStringAsFixed(1)}%',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('$count / $total', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}
