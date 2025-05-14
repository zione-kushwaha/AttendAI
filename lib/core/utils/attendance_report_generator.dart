import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hajiri/models/attendance_model.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class AttendanceReportGenerator {
  /// Generate a PDF attendance report for a class
  static Future<File> generateClassAttendanceReport({
    required ClassModel classModel,
    required List<StudentModel> students,
    required List<AttendanceRecord> attendanceRecords,
    required Map<String, dynamic> monthlyStats,
    required Map<String, dynamic> allTimeStats,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();
    final reportPeriod =
        startDate != null && endDate != null
            ? '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'
            : 'All Time';

    // Load Roboto font - with fallback to default if not available
    pw.Font ttf;
    pw.Font ttfBold;
    try {
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      ttf = pw.Font.ttf(fontData);
      final fontBold = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      ttfBold = pw.Font.ttf(fontBold);
    } catch (e) {
      // Use default font if Roboto is not available
      ttf = pw.Font.helvetica();
      ttfBold = pw.Font.helveticaBold();
    }

    // Logo bytes (placeholder - use default icon if app icon not available)
    Uint8List logoBytes;
    try {
      final ByteData assetData = await rootBundle.load(
        'assets/icon/app_icon.png',
      );
      logoBytes = assetData.buffer.asUint8List();
    } catch (e) {
      // Create a simple placeholder logo
      final placeholder = pw.Document();
      placeholder.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'H',
                style: pw.TextStyle(fontSize: 40, font: ttfBold),
              ),
            );
          },
        ),
      );
      logoBytes = await placeholder.save();
    }

    // Helper function to get status icon and color
    PdfColor getStatusColor(AttendanceStatus status) {
      switch (status) {
        case AttendanceStatus.present:
          return PdfColors.green;
        case AttendanceStatus.absent:
          return PdfColors.red;
        case AttendanceStatus.late:
          return PdfColors.orange;
        case AttendanceStatus.excused:
          return PdfColors.blue;
      }
    }

    String getStatusLabel(AttendanceStatus status) {
      switch (status) {
        case AttendanceStatus.present:
          return 'Present';
        case AttendanceStatus.absent:
          return 'Absent';
        case AttendanceStatus.late:
          return 'Late';
        case AttendanceStatus.excused:
          return 'Excused';
      }
    }

    // Title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(pw.MemoryImage(logoBytes), width: 100, height: 100),
              pw.SizedBox(height: 20),
              pw.Text(
                'Attendance Report',
                style: pw.TextStyle(font: ttfBold, fontSize: 24),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                classModel.name,
                style: pw.TextStyle(font: ttfBold, fontSize: 20),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Subject: ${classModel.subject}',
                style: pw.TextStyle(font: ttf, fontSize: 16),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Report Period: $reportPeriod',
                      style: pw.TextStyle(font: ttf, fontSize: 14),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Generated on: ${dateFormat.format(now)}',
                      style: pw.TextStyle(font: ttf, fontSize: 14),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Total Students: ${students.length}',
                      style: pw.TextStyle(font: ttf, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Summary statistics page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 1,
                text: 'Attendance Summary',
                textStyle: pw.TextStyle(font: ttfBold, fontSize: 18),
              ),
              pw.Divider(thickness: 1),

              pw.SizedBox(height: 20),

              // Monthly statistics
              pw.Text(
                'Monthly Statistics (${DateFormat.MMMM().format(DateTime.now())})',
                style: pw.TextStyle(font: ttfBold, fontSize: 16),
              ),

              pw.SizedBox(height: 10),

              // Stat cards
              _buildPdfStatRow(
                'Present',
                monthlyStats['presentCount'],
                monthlyStats['totalRecords'],
                monthlyStats['presentPercentage'],
                PdfColors.green,
                ttf,
                ttfBold,
              ),

              _buildPdfStatRow(
                'Absent',
                monthlyStats['absentCount'],
                monthlyStats['totalRecords'],
                monthlyStats['absentCount'] /
                    (monthlyStats['totalRecords'] > 0
                        ? monthlyStats['totalRecords']
                        : 1) *
                    100,
                PdfColors.red,
                ttf,
                ttfBold,
              ),

              _buildPdfStatRow(
                'Late',
                monthlyStats['lateCount'],
                monthlyStats['totalRecords'],
                monthlyStats['lateCount'] /
                    (monthlyStats['totalRecords'] > 0
                        ? monthlyStats['totalRecords']
                        : 1) *
                    100,
                PdfColors.orange,
                ttf,
                ttfBold,
              ),

              _buildPdfStatRow(
                'Excused',
                monthlyStats['excusedCount'],
                monthlyStats['totalRecords'],
                monthlyStats['excusedCount'] /
                    (monthlyStats['totalRecords'] > 0
                        ? monthlyStats['totalRecords']
                        : 1) *
                    100,
                PdfColors.blue,
                ttf,
                ttfBold,
              ),

              pw.SizedBox(height: 20),

              // All time statistics
              pw.Text(
                'All Time Statistics',
                style: pw.TextStyle(font: ttfBold, fontSize: 16),
              ),

              pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfStatCircle(
                    'Present',
                    allTimeStats['presentPercentage'].toStringAsFixed(1) + '%',
                    PdfColors.green,
                    ttf,
                    ttfBold,
                  ),
                  _buildPdfStatCircle(
                    'Absent',
                    (allTimeStats['absentCount'] /
                                (allTimeStats['totalRecords'] > 0
                                    ? allTimeStats['totalRecords']
                                    : 1) *
                                100)
                            .toStringAsFixed(1) +
                        '%',
                    PdfColors.red,
                    ttf,
                    ttfBold,
                  ),
                  _buildPdfStatCircle(
                    'Late',
                    (allTimeStats['lateCount'] /
                                (allTimeStats['totalRecords'] > 0
                                    ? allTimeStats['totalRecords']
                                    : 1) *
                                100)
                            .toStringAsFixed(1) +
                        '%',
                    PdfColors.orange,
                    ttf,
                    ttfBold,
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Attendance days and remarks
              pw.Text(
                'Additional Information:',
                style: pw.TextStyle(font: ttfBold, fontSize: 16),
              ),

              pw.SizedBox(height: 5),

              pw.Text(
                'Total Attendance Days: ${monthlyStats['attendanceDays']}',
                style: pw.TextStyle(font: ttf, fontSize: 14),
              ),

              pw.Text(
                'Average Attendance Rate: ${monthlyStats['averageAttendanceRate'].toStringAsFixed(1)}%',
                style: pw.TextStyle(font: ttf, fontSize: 14),
              ),
            ],
          );
        },
      ),
    );

    // Students attendance details page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // Group attendance records by student
          final Map<String, List<AttendanceRecord>> studentAttendance = {};
          for (final record in attendanceRecords) {
            if (record.classId == classModel.id) {
              if (!studentAttendance.containsKey(record.studentId)) {
                studentAttendance[record.studentId] = [];
              }
              studentAttendance[record.studentId]!.add(record);
            }
          }

          // Calculate individual student statistics
          final List<Map<String, dynamic>> studentStats = [];
          for (final student in students) {
            if (student.classIds.contains(classModel.id)) {
              final records = studentAttendance[student.id] ?? [];
              final presentCount =
                  records
                      .where((r) => r.status == AttendanceStatus.present)
                      .length;
              final absentCount =
                  records
                      .where((r) => r.status == AttendanceStatus.absent)
                      .length;
              final lateCount =
                  records
                      .where((r) => r.status == AttendanceStatus.late)
                      .length;
              final excusedCount =
                  records
                      .where((r) => r.status == AttendanceStatus.excused)
                      .length;
              final totalAttendance = records.length;

              studentStats.add({
                'student': student,
                'presentCount': presentCount,
                'absentCount': absentCount,
                'lateCount': lateCount,
                'excusedCount': excusedCount,
                'totalAttendance': totalAttendance,
                'presentPercentage':
                    totalAttendance > 0
                        ? (presentCount / totalAttendance * 100)
                        : 0.0,
              });
            }
          } // Sort by roll number
          studentStats.sort(
            (a, b) => (a['student'] as StudentModel).rollNumber.compareTo(
              (b['student'] as StudentModel).rollNumber,
            ),
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 1,
                text: 'Student Attendance Details',
                textStyle: pw.TextStyle(font: ttfBold, fontSize: 18),
              ),
              pw.Divider(thickness: 1),

              pw.SizedBox(height: 10),

              // Table header
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: const pw.FractionColumnWidth(0.05), // S.No
                  1: const pw.FractionColumnWidth(0.25), // Name
                  2: const pw.FractionColumnWidth(0.15), // Roll No
                  3: const pw.FractionColumnWidth(0.1), // Present
                  4: const pw.FractionColumnWidth(0.1), // Absent
                  5: const pw.FractionColumnWidth(0.1), // Late
                  6: const pw.FractionColumnWidth(0.1), // Excused
                  7: const pw.FractionColumnWidth(0.15), // Percentage
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'No.',
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Name',
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Roll No',
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'P',
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'A',
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'L',
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'E',
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Attendance %',
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  // Data rows
                  ...studentStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    final student = stat['student'] as StudentModel;

                    // Highlight low attendance in red
                    final attendancePercentage =
                        stat['presentPercentage'] as double;
                    final attendanceColor =
                        attendancePercentage < 75
                            ? PdfColors.red
                            : attendancePercentage < 85
                            ? PdfColors.orange
                            : PdfColors.black;

                    return pw.TableRow(
                      children: [
                        // Index
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${index + 1}',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Name
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            student.name,
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          ),
                        ),
                        // Roll No
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            student.rollNumber,
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          ),
                        ),
                        // Present
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${stat['presentCount']}',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Absent
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${stat['absentCount']}',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Late
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${stat['lateCount']}',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Excused
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${stat['excusedCount']}',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Percentage
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${attendancePercentage.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 10,
                              color: attendanceColor,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Legend
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Legend:',
                      style: pw.TextStyle(font: ttfBold, fontSize: 12),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 10,
                          height: 10,
                          color: PdfColors.green,
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'P - Present',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Container(
                          width: 10,
                          height: 10,
                          color: PdfColors.red,
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'A - Absent',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 10,
                          height: 10,
                          color: PdfColors.orange,
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'L - Late',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Container(
                          width: 10,
                          height: 10,
                          color: PdfColors.blue,
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'E - Excused',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Notes
              pw.Text(
                'Notes:',
                style: pw.TextStyle(font: ttfBold, fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '1. Students with attendance below 75% are marked in red.',
                style: pw.TextStyle(font: ttf, fontSize: 10),
              ),
              pw.Text(
                '2. Students with attendance between 75% and 85% are marked in orange.',
                style: pw.TextStyle(font: ttf, fontSize: 10),
              ),

              // Footer with page number
              pw.Footer(
                title: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: ttf, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Daily attendance records page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // Group attendance records by date
          final Map<String, List<AttendanceRecord>> dateAttendance = {};
          for (final record in attendanceRecords) {
            if (record.classId == classModel.id) {
              final dateStr = dateFormat.format(record.date);
              if (!dateAttendance.containsKey(dateStr)) {
                dateAttendance[dateStr] = [];
              }
              dateAttendance[dateStr]!.add(record);
            }
          }

          // Sort dates (recent first)
          final sortedDates =
              dateAttendance.keys.toList()..sort(
                (a, b) => dateFormat.parse(b).compareTo(dateFormat.parse(a)),
              );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 1,
                text: 'Daily Attendance Records',
                textStyle: pw.TextStyle(font: ttfBold, fontSize: 18),
              ),
              pw.Divider(thickness: 1),

              pw.SizedBox(height: 10),

              // Daily records
              pw.Expanded(
                child: pw.ListView(
                  children:
                      sortedDates.map((dateStr) {
                        final records = dateAttendance[dateStr]!;
                        final presentCount =
                            records
                                .where(
                                  (r) => r.status == AttendanceStatus.present,
                                )
                                .length;
                        final absentCount =
                            records
                                .where(
                                  (r) => r.status == AttendanceStatus.absent,
                                )
                                .length;
                        final lateCount =
                            records
                                .where((r) => r.status == AttendanceStatus.late)
                                .length;
                        final excusedCount =
                            records
                                .where(
                                  (r) => r.status == AttendanceStatus.excused,
                                )
                                .length;

                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Date header with stat summary
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              margin: const pw.EdgeInsets.only(bottom: 5),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.all(
                                  pw.Radius.circular(4),
                                ),
                              ),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    dateStr,
                                    style: pw.TextStyle(
                                      font: ttfBold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  pw.Text(
                                    'P: $presentCount | A: $absentCount | L: $lateCount | E: $excusedCount',
                                    style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Show all records for each date for better details
                            for (final record in records)
                              _buildAttendanceRecordRow(
                                record,
                                students,
                                ttf,
                                ttfBold,
                                getStatusColor,
                                getStatusLabel,
                              ),

                            pw.SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                ),
              ),

              // Footer with page number
              pw.Footer(
                title: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: ttf, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    ); // Add detailed student records pages - sorted by roll number
    final sortedStudents =
        students.where((s) => s.classIds.contains(classModel.id)).toList()
          ..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));

    for (final student in sortedStudents) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            // Get all attendance records for this student
            final studentRecords =
                attendanceRecords
                    .where(
                      (record) =>
                          record.classId == classModel.id &&
                          record.studentId == student.id,
                    )
                    .toList();

            // Sort by date (recent first)
            studentRecords.sort((a, b) => b.date.compareTo(a.date));

            // Calculate statistics
            final presentCount =
                studentRecords
                    .where((r) => r.status == AttendanceStatus.present)
                    .length;
            final absentCount =
                studentRecords
                    .where((r) => r.status == AttendanceStatus.absent)
                    .length;
            final lateCount =
                studentRecords
                    .where((r) => r.status == AttendanceStatus.late)
                    .length;
            final excusedCount =
                studentRecords
                    .where((r) => r.status == AttendanceStatus.excused)
                    .length;
            final totalRecords = studentRecords.length;
            final presentPercentage =
                totalRecords > 0 ? (presentCount / totalRecords * 100) : 0.0;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Student header with profile
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Student basic info
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Student Profile',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 18,
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  'Name: ${student.name}',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 14,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Roll Number: ${student.rollNumber}',
                                  style: pw.TextStyle(font: ttf, fontSize: 12),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Class: ${classModel.name}',
                                  style: pw.TextStyle(font: ttf, fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                          // Attendance summary
                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(8),
                              ),
                              border: pw.Border.all(color: PdfColors.grey300),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(
                                  'Attendance Summary',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 12,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'Present: $presentCount',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.green,
                                  ),
                                ),
                                pw.Text(
                                  'Absent: $absentCount',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.red,
                                  ),
                                ),
                                pw.Text(
                                  'Late: $lateCount',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.orange,
                                  ),
                                ),
                                pw.Text(
                                  'Excused: $excusedCount',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.blue,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Total: $totalRecords days',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 10,
                                  ),
                                ),
                                pw.Text(
                                  'Attendance Rate: ${presentPercentage.toStringAsFixed(1)}%',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 10,
                                    color:
                                        presentPercentage < 75
                                            ? PdfColors.red
                                            : presentPercentage < 85
                                            ? PdfColors.orange
                                            : PdfColors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Attendance history header
                pw.Text(
                  'Detailed Attendance History',
                  style: pw.TextStyle(font: ttfBold, fontSize: 14),
                ),

                pw.SizedBox(height: 10),

                // Detailed attendance table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FractionColumnWidth(0.15), // Date
                    1: const pw.FractionColumnWidth(0.15), // Day
                    2: const pw.FractionColumnWidth(0.15), // Status
                    3: const pw.FractionColumnWidth(0.55), // Remarks
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(font: ttfBold, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Day',
                            style: pw.TextStyle(font: ttfBold, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Status',
                            style: pw.TextStyle(font: ttfBold, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Remarks',
                            style: pw.TextStyle(font: ttfBold, fontSize: 10),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                      ],
                    ),

                    // Data rows - show all attendance records for this student
                    ...studentRecords.map((record) {
                      final statusColor = getStatusColor(record.status);
                      final statusLabel = getStatusLabel(record.status);

                      return pw.TableRow(
                        children: [
                          // Date
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              dateFormat.format(record.date),
                              style: pw.TextStyle(font: ttf, fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Day
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              DateFormat('EEEE').format(record.date),
                              style: pw.TextStyle(font: ttf, fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Status
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: 8,
                                  height: 8,
                                  decoration: pw.BoxDecoration(
                                    color: statusColor,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.SizedBox(width: 3),
                                pw.Text(
                                  statusLabel,
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 9,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Remarks
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              record.remark ?? '-',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 9,
                                fontStyle:
                                    record.remark != null &&
                                            record.remark!.isNotEmpty
                                        ? pw.FontStyle.italic
                                        : pw.FontStyle.normal,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                pw.SizedBox(height: 15),

                // Monthly attendance pattern
                pw.Text(
                  'Monthly Attendance Pattern',
                  style: pw.TextStyle(font: ttfBold, fontSize: 14),
                ),

                pw.SizedBox(height: 10),

                // Create monthly statistics
                _buildMonthlyAttendancePatternChart(
                  studentRecords,
                  ttf,
                  ttfBold,
                  getStatusColor,
                ),

                pw.Spacer(),

                // Footer explanation
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Generated on: ${dateFormat.format(DateTime.now())}',
                        style: pw.TextStyle(font: ttf, fontSize: 8),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: pw.TextStyle(font: ttf, fontSize: 8),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Save the PDF file
    final output = await getTemporaryDirectory();
    final String reportName =
        'hajiri_${classModel.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$reportName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Helper to build a PDF attendance record row
  static pw.Widget _buildAttendanceRecordRow(
    AttendanceRecord record,
    List<StudentModel> students,
    pw.Font ttf,
    pw.Font ttfBold,
    Function getStatusColor,
    Function getStatusLabel,
  ) {
    // Find student
    final student = students.firstWhere(
      (s) => s.id == record.studentId,
      orElse:
          () => StudentModel(
            name: 'Unknown Student',
            rollNumber: 'N/A',
            classIds: [],
          ),
    );

    final statusColor = getStatusColor(record.status);
    final statusLabel = getStatusLabel(record.status);
    final dateFormat = DateFormat('dd MMM yyyy');

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          // Roll Number first
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              student.rollNumber,
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
          ),
          // Date
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              dateFormat.format(record.date),
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
          ),
          // Status
          pw.Expanded(
            flex: 2,
            child: pw.Row(
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  decoration: pw.BoxDecoration(
                    color: statusColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 3),
                pw.Text(
                  statusLabel,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 10,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          // Remarks
          record.remark != null && record.remark!.isNotEmpty
              ? pw.Expanded(
                flex: 5,
                child: pw.Text(
                  'Remark: ${record.remark}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              )
              : pw.Expanded(flex: 5, child: pw.Container()),
        ],
      ),
    );
  }

  /// Helper to build a PDF stat row
  static pw.Widget _buildPdfStatRow(
    String title,
    int count,
    int total,
    double percentage,
    PdfColor color,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(font: ttfBold, fontSize: 12),
            ),
          ),
          pw.Text(
            '$count/$total',
            style: pw.TextStyle(font: ttf, fontSize: 12),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            '${percentage.toStringAsFixed(1)}%',
            style: pw.TextStyle(font: ttfBold, fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  /// Helper to build a PDF stat circle
  static pw.Widget _buildPdfStatCircle(
    String title,
    String value,
    PdfColor color,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    return pw.Column(
      children: [
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: color, width: 2),
          ),
          child: pw.Center(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: ttfBold, fontSize: 12, color: color),
            ),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(title, style: pw.TextStyle(font: ttf, fontSize: 10)),
      ],
    );
  }

  /// Helper to build a monthly attendance pattern chart for a student
  static pw.Widget _buildMonthlyAttendancePatternChart(
    List<AttendanceRecord> studentRecords,
    pw.Font ttf,
    pw.Font ttfBold,
    Function getStatusColor,
  ) {
    // Group records by month
    final Map<String, List<AttendanceRecord>> monthlyRecords = {};

    for (final record in studentRecords) {
      final monthKey = DateFormat('MMM yyyy').format(record.date);
      if (!monthlyRecords.containsKey(monthKey)) {
        monthlyRecords[monthKey] = [];
      }
      monthlyRecords[monthKey]!.add(record);
    }

    // Sort months chronologically
    final sortedMonths =
        monthlyRecords.keys.toList()..sort((a, b) {
          final aDate = DateFormat('MMM yyyy').parse(a);
          final bDate = DateFormat('MMM yyyy').parse(b);
          return aDate.compareTo(bDate);
        });

    // No data available
    if (sortedMonths.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Center(
          child: pw.Text(
            'No attendance data available for chart visualization',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ),
      );
    }

    // Calculate monthly statistics for the chart
    final List<Map<String, dynamic>> monthlyStats = [];

    for (final month in sortedMonths) {
      final records = monthlyRecords[month]!;
      final total = records.length;
      final presentCount =
          records.where((r) => r.status == AttendanceStatus.present).length;
      final absentCount =
          records.where((r) => r.status == AttendanceStatus.absent).length;
      final lateCount =
          records.where((r) => r.status == AttendanceStatus.late).length;
      final excusedCount =
          records.where((r) => r.status == AttendanceStatus.excused).length;

      final presentPercent = total > 0 ? (presentCount / total * 100) : 0.0;
      final absentPercent = total > 0 ? (absentCount / total * 100) : 0.0;
      final latePercent = total > 0 ? (lateCount / total * 100) : 0.0;
      final excusedPercent = total > 0 ? (excusedCount / total * 100) : 0.0;

      monthlyStats.add({
        'month': month,
        'total': total,
        'present': presentCount,
        'absent': absentCount,
        'late': lateCount,
        'excused': excusedCount,
        'presentPercent': presentPercent,
        'absentPercent': absentPercent,
        'latePercent': latePercent,
        'excusedPercent': excusedPercent,
      });
    }
    // Calculate maximum bar height for scaling
    const maxBarHeight = 100.0;
    const barWidth = 40.0;

    // Build the chart
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Chart title
          pw.Text(
            'Monthly Attendance Pattern',
            style: pw.TextStyle(font: ttfBold, fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 10),

          // Chart description
          pw.Text(
            'This chart shows the student\'s attendance pattern across months. Each bar represents a month.',
            style: pw.TextStyle(font: ttf, fontSize: 8),
          ),

          pw.SizedBox(height: 10),

          // Chart area
          pw.Container(
            height: 160,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Y-axis labels (percentages)
                pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '100%',
                      style: pw.TextStyle(font: ttf, fontSize: 6),
                    ),
                    pw.Text('75%', style: pw.TextStyle(font: ttf, fontSize: 6)),
                    pw.Text('50%', style: pw.TextStyle(font: ttf, fontSize: 6)),
                    pw.Text('25%', style: pw.TextStyle(font: ttf, fontSize: 6)),
                    pw.Text('0%', style: pw.TextStyle(font: ttf, fontSize: 6)),
                  ],
                ),

                pw.SizedBox(width: 5),

                // Chart bars
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children:
                        monthlyStats.map((stat) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              // Stacked bar segments
                              pw.Container(
                                width: barWidth,
                                height: maxBarHeight,
                                child: pw.Column(
                                  children: [
                                    // Present (from top)
                                    pw.Container(
                                      width: barWidth,
                                      height:
                                          (stat['presentPercent'] / 100) *
                                          maxBarHeight,
                                      color: PdfColors.green,
                                    ),
                                    // Late
                                    pw.Container(
                                      width: barWidth,
                                      height:
                                          (stat['latePercent'] / 100) *
                                          maxBarHeight,
                                      color: PdfColors.orange,
                                    ),
                                    // Excused
                                    pw.Container(
                                      width: barWidth,
                                      height:
                                          (stat['excusedPercent'] / 100) *
                                          maxBarHeight,
                                      color: PdfColors.blue,
                                    ),
                                    // Absent (bottom)
                                    pw.Container(
                                      width: barWidth,
                                      height:
                                          (stat['absentPercent'] / 100) *
                                          maxBarHeight,
                                      color: PdfColors.red,
                                    ),
                                  ],
                                ),
                              ),

                              // X-axis labels (months)
                              pw.SizedBox(height: 5),
                              pw.Text(
                                stat['month'],
                                style: pw.TextStyle(font: ttf, fontSize: 6),
                              ),
                              pw.Text(
                                '(${stat['total']} days)',
                                style: pw.TextStyle(font: ttf, fontSize: 5),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 15),

          // Legend
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildChartLegendItem(PdfColors.green, 'Present', ttf),
              pw.SizedBox(width: 15),
              _buildChartLegendItem(PdfColors.orange, 'Late', ttf),
              pw.SizedBox(width: 15),
              _buildChartLegendItem(PdfColors.blue, 'Excused', ttf),
              pw.SizedBox(width: 15),
              _buildChartLegendItem(PdfColors.red, 'Absent', ttf),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build a legend item for the chart
  static pw.Widget _buildChartLegendItem(
    PdfColor color,
    String label,
    pw.Font ttf,
  ) {
    return pw.Row(
      children: [
        pw.Container(width: 8, height: 8, color: color),
        pw.SizedBox(width: 4),
        pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 7)),
      ],
    );
  }

  /// Share the generated PDF file
  static Future<void> shareReport(File reportFile) async {
    await Share.shareXFiles(
      [XFile(reportFile.path)],
      subject: 'Attendance Report',
      text: 'Please find the attendance report attached.',
    );
  }
}
