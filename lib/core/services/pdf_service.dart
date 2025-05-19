import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hajiri/models/attendance_model.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  // Color constants for attendance percentages
  static const PdfColor lowAttendanceColor = PdfColors.red;
  static const PdfColor mediumAttendanceColor = PdfColors.orange;
  static const PdfColor highAttendanceColor = PdfColors.green;

  // Attendance percentage thresholds
  static const double lowAttendanceThreshold = 75.0;
  static const double mediumAttendanceThreshold = 85.0;

  pw.Document? _doc;
  pw.Font? _regularFont;
  pw.Font? _boldFont;
  Uint8List? _logo;

  PdfColor getAttendanceColor(double percentage) {
    if (percentage < lowAttendanceThreshold) return lowAttendanceColor;
    if (percentage < mediumAttendanceThreshold) return mediumAttendanceColor;
    return highAttendanceColor;
  }

  Future<File> generateAttendanceReport({
    required ClassModel classModel,
    required List<StudentModel> students,
    required List<AttendanceRecord> records,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _doc = pw.Document();

      // Load fonts
      _regularFont = await _loadFont('assets/fonts/Roboto-Regular.ttf');
      _boldFont = await _loadFont('assets/fonts/Roboto-Bold.ttf');

      // Create PDF pages
      await _addCoverPage(classModel, students.length);
      await _addSummaryPage(records);
      await _addDetailedRecordsPage(students, records);

      // Get temporary directory for saving
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) {
        await tempDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'attendance_${classModel.id}_$timestamp.pdf';
      final filePath = '${tempDir.path}/$fileName';

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(await _doc!.save());

      return file;
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  Future<pw.Font> _loadFont(String path) async {
    try {
      final fontData = await rootBundle.load(path);
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('Error loading font: $e');
      rethrow;
    }
  }

  Future<void> _addCoverPage(ClassModel classModel, int studentCount) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final end = now;

    _doc!.addPage(
      await _buildCoverPage(
        classModel: classModel,
        startDate: start,
        endDate: end,
        studentCount: studentCount,
        stats: {},
      ),
    );
  }

  Future<void> _addSummaryPage(List<AttendanceRecord> records) async {
    final stats = _calculateStats(records);
    _doc!.addPage(await _buildStatsPage(stats));
  }

  Future<void> _addDetailedRecordsPage(
    List<StudentModel> students,
    List<AttendanceRecord> records,
  ) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final end = now;

    _doc!.addPage(
      await _buildStudentDetailsPage(
        students: students,
        records: records,
        startDate: start,
        endDate: end,
      ),
    );

    _doc!.addPage(
      await _buildDailyRecordsPage(
        classModel: ClassModel(id: '', name: '', subject: '', schedule: {}),
        students: students,
        records: records,
        startDate: start,
        endDate: end,
      ),
    );
  }

  Future<pw.Page> _buildCoverPage({
    required ClassModel classModel,
    required DateTime startDate,
    required DateTime endDate,
    required int studentCount,
    required Map<String, dynamic> stats,
  }) async {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build:
          (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 40),
              if (_logo != null)
                pw.Image(pw.MemoryImage(_logo!), width: 100, height: 100),
              pw.SizedBox(height: 20),
              pw.Text(
                'Attendance Report',
                style: pw.TextStyle(
                  font: _boldFont,
                  fontSize: 24,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                classModel.name,
                style: pw.TextStyle(font: _boldFont, fontSize: 20),
              ),
              pw.Text(
                classModel.subject,
                style: pw.TextStyle(font: _regularFont, fontSize: 16),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Report Period',
                style: pw.TextStyle(font: _boldFont, fontSize: 16),
              ),
              pw.Text(
                '${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
                style: pw.TextStyle(font: _regularFont, fontSize: 14),
              ),
              pw.SizedBox(height: 40),
              _buildSummaryBox(studentCount, stats),
              pw.Spacer(),
              pw.Text(
                'Generated on: ${DateFormat.yMMMMd().format(DateTime.now())}',
                style: pw.TextStyle(
                  font: _regularFont,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
    );
  }

  pw.Widget _buildSummaryBox(int studentCount, Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Quick Summary',
            style: pw.TextStyle(
              font: _boldFont,
              fontSize: 14,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildSummaryRow('Total Students', studentCount.toString()),
          _buildSummaryRow('Present Days', stats['presentDays'].toString()),
          _buildSummaryRow('Absent Days', stats['absentDays'].toString()),
          _buildSummaryRow(
            'Average Attendance',
            '${stats['averageAttendance'].toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: _regularFont)),
          pw.Text(value, style: pw.TextStyle(font: _boldFont)),
        ],
      ),
    );
  }

  Future<pw.Page> _buildStatsPage(Map<String, dynamic> stats) async {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build:
          (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Attendance Statistics',
                  style: pw.TextStyle(
                    font: _boldFont,
                    fontSize: 20,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  font: _boldFont,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(font: _regularFont),
                headerAlignment: pw.Alignment.center,
                cellAlignment: pw.Alignment.center,
                headers: ['Category', 'Count', 'Percentage'],
                data: [
                  [
                    'Present',
                    stats['presentDays'].toString(),
                    '${stats['presentPercentage'].toStringAsFixed(1)}%',
                  ],
                  [
                    'Absent',
                    stats['absentDays'].toString(),
                    '${stats['absentPercentage'].toStringAsFixed(1)}%',
                  ],
                  [
                    'Late',
                    stats['lateDays'].toString(),
                    '${stats['latePercentage'].toStringAsFixed(1)}%',
                  ],
                ],
              ),
            ],
          ),
    );
  }

  Future<pw.Page> _buildStudentDetailsPage({
    required List<StudentModel> students,
    required List<AttendanceRecord> records,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Filter records by date range
    final filteredRecords =
        records
            .where(
              (r) =>
                  r.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  r.date.isBefore(endDate.add(const Duration(days: 1))),
            )
            .toList();

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build:
          (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Student Attendance Details',
                  style: pw.TextStyle(
                    font: _boldFont,
                    fontSize: 20,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  font: _boldFont,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(font: _regularFont),
                headerAlignment: pw.Alignment.center,
                cellAlignment: pw.Alignment.center,
                headers: [
                  'Name',
                  'Roll No',
                  'Present',
                  'Absent',
                  'Late',
                  'Attendance %',
                ],
                data:
                    students.map((student) {
                      final studentRecords =
                          filteredRecords
                              .where((r) => r.studentId == student.id)
                              .toList();
                      final totalDays = studentRecords.length;
                      final presentCount =
                          studentRecords
                              .where(
                                (r) => r.status == AttendanceStatus.present,
                              )
                              .length;
                      final absentCount =
                          studentRecords
                              .where((r) => r.status == AttendanceStatus.absent)
                              .length;
                      final lateCount =
                          studentRecords
                              .where((r) => r.status == AttendanceStatus.late)
                              .length;
                      final attendancePercentage =
                          totalDays > 0
                              ? (presentCount / totalDays * 100)
                              : 0.0;

                      return [
                        student.name,
                        student.rollNumber,
                        presentCount.toString(),
                        absentCount.toString(),
                        lateCount.toString(),
                        '${attendancePercentage.toStringAsFixed(1)}%',
                      ];
                    }).toList(),
              ),
            ],
          ),
    );
  }

  Future<pw.Page> _buildDailyRecordsPage({
    required ClassModel classModel,
    required List<StudentModel> students,
    required List<AttendanceRecord> records,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Filter records by date range
    final filteredRecords =
        records
            .where(
              (r) =>
                  r.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  r.date.isBefore(endDate.add(const Duration(days: 1))),
            )
            .toList();

    // Group records by date
    final recordsByDate = <DateTime, List<AttendanceRecord>>{};
    for (var record in filteredRecords) {
      final date = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      recordsByDate.putIfAbsent(date, () => []).add(record);
    }

    // Sort dates
    final dates = recordsByDate.keys.toList()..sort();

    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build:
          (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Daily Attendance Records',
                      style: pw.TextStyle(
                        font: _boldFont,
                        fontSize: 20,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'P = Present, A = Absent, L = Late',
                      style: pw.TextStyle(
                        font: _regularFont,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  font: _boldFont,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(font: _regularFont),
                headerAlignment: pw.Alignment.center,
                cellAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // Name
                  1: const pw.FlexColumnWidth(1.5), // Roll No
                  for (var i = 2; i < dates.length + 2; i++)
                    i: const pw.FlexColumnWidth(1),
                },
                headers: [
                  'Name',
                  'Roll No',
                  ...dates.map((d) => DateFormat('MMM d').format(d)),
                ],
                data:
                    students
                        .map(
                          (student) => [
                            student.name,
                            student.rollNumber,
                            ...dates.map((date) {
                              final record = recordsByDate[date]?.firstWhere(
                                (r) => r.studentId == student.id,
                                orElse:
                                    () => AttendanceRecord(
                                      classId: classModel.id,
                                      studentId: student.id,
                                      date: date,
                                      status: AttendanceStatus.absent,
                                    ),
                              );
                              switch (record?.status) {
                                case AttendanceStatus.present:
                                  return 'P';
                                case AttendanceStatus.absent:
                                  return 'A';
                                case AttendanceStatus.late:
                                  return 'L';
                                default:
                                  return '-';
                              }
                            }),
                          ],
                        )
                        .toList(),
              ),
            ],
          ),
    );
  }

  Map<String, dynamic> _calculateStats(List<AttendanceRecord> records) {
    final totalRecords = records.length;
    final presentDays =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final absentDays =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final lateDays =
        records.where((r) => r.status == AttendanceStatus.late).length;

    return {
      'totalDays': totalRecords,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'presentPercentage':
          totalRecords > 0 ? (presentDays / totalRecords * 100) : 0,
      'absentPercentage':
          totalRecords > 0 ? (absentDays / totalRecords * 100) : 0,
      'latePercentage': totalRecords > 0 ? (lateDays / totalRecords * 100) : 0,
      'averageAttendance':
          totalRecords > 0 ? (presentDays / totalRecords * 100) : 0,
    };
  }
}
