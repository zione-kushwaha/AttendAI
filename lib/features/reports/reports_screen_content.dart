import 'dart:io';

import 'package:cross_file/cross_file.dart';
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

// Content-only version of ReportsScreen without AppBar
class ReportsScreenContent extends ConsumerStatefulWidget {
  const ReportsScreenContent({super.key});

  @override
  ConsumerState<ReportsScreenContent> createState() =>
      _ReportsScreenContentState();
}

class _ReportsScreenContentState extends ConsumerState<ReportsScreenContent> {
  String? _selectedClassId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGeneratingReport = false;
  bool _showDataFilters = true;

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classProvider);
    final students = ref.watch(studentProvider);
    final attendanceRecords = ref.watch(attendanceProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Reports',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Data filters section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showDataFilters ? null : 0,
            child: Visibility(
              visible: _showDataFilters,
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Data',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Class selection dropdown
                      _buildClassDropdown(classes),
                      const SizedBox(height: 16),

                      // Date range selection
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              context,
                              'Start Date',
                              _startDate,
                              (date) => setState(() => _startDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              context,
                              'End Date',
                              _endDate,
                              (date) => setState(() => _endDate = date),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Generate report button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isGeneratingReport
                                  ? null
                                  : () => _generateReport(
                                    context,
                                    classes,
                                    students,
                                    attendanceRecords,
                                  ),
                          child:
                              _isGeneratingReport
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Generate Report'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Report previews/summaries
          Expanded(
            child:
                attendanceRecords.isEmpty
                    ? const EmptyStateWidget(
                      icon: Icons.assessment_outlined,
                      message: 'No attendance data available',
                    )
                    : _buildReportSummaries(
                      classes,
                      students,
                      attendanceRecords,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown(List<ClassModel> classes) {
    return DropdownButtonFormField<String?>(
      decoration: InputDecoration(
        labelText: 'Select Class',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      value: _selectedClassId,
      onChanged: (value) {
        setState(() {
          _selectedClassId = value;
        });
      },
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Classes'),
        ),
        ...classes.map(
          (c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name)),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime initialDate,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        child: Text(
          DateFormat('MMM dd, yyyy').format(initialDate),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildReportSummaries(
    List<ClassModel> classes,
    List<dynamic> students,
    List<AttendanceRecord> attendanceRecords,
  ) {
    // Filter attendance records based on selected criteria
    final filteredAttendance =
        attendanceRecords.where((record) {
          final isInDateRange =
              record.date.isAfter(
                _startDate.subtract(const Duration(days: 1)),
              ) &&
              record.date.isBefore(_endDate.add(const Duration(days: 1)));

          final isInSelectedClass =
              _selectedClassId == null || record.classId == _selectedClassId;

          return isInDateRange && isInSelectedClass;
        }).toList();

    if (filteredAttendance.isEmpty) {
      return const Center(
        child: Text('No attendance data for the selected filters'),
      );
    }

    // Group attendance records by class
    final attendanceByClass = <String, List<AttendanceRecord>>{};
    for (final record in filteredAttendance) {
      if (!attendanceByClass.containsKey(record.classId)) {
        attendanceByClass[record.classId] = [];
      }
      attendanceByClass[record.classId]!.add(record);
    }

    return ListView.builder(
      itemCount: attendanceByClass.length,
      itemBuilder: (context, index) {
        final classId = attendanceByClass.keys.elementAt(index);
        final classAttendance = attendanceByClass[classId]!;
        final classModel = classes.firstWhere(
          (c) => c.id == classId,
          orElse:
              () => ClassModel(
                id: classId,
                name: 'Unknown Class',
                description: '',
                schedule: {},
                subject: 'Unknown Subject',
              ),
        );

        // Calculate total attendance statistics
        final totalRecords = classAttendance.length;
        int presentCount = 0;
        int absentCount = 0;

        for (final record in classAttendance) {
          switch (record.status) {
            case AttendanceStatus.present:
              presentCount++;
              break;
            case AttendanceStatus.absent:
              absentCount++;
              break;
            case AttendanceStatus.late:
            case AttendanceStatus.excused:
              // Handle late and excused if needed
              break;
          }
        }

        final totalAttendance = presentCount + absentCount;
        final presentPercentage =
            totalAttendance > 0
                ? (presentCount / totalAttendance * 100).toStringAsFixed(1)
                : '0.0';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classModel.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(
                      context,
                      'Days',
                      totalRecords.toString(),
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      context,
                      'Present',
                      '$presentCount',
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      context,
                      'Absent',
                      '$absentCount',
                      Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      context,
                      'Attendance',
                      '$presentPercentage%',
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isGeneratingReport = true;
                        });

                        await _generateClassReport(
                          context,
                          classModel,
                          classAttendance,
                          students,
                        );

                        setState(() {
                          _isGeneratingReport = false;
                        });
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport(
    BuildContext context,
    List<ClassModel> classes,
    List<dynamic> students,
    List<AttendanceRecord> attendanceRecords,
  ) async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      // Implementation for generating the report
      // This can be complex and would involve creating PDFs using the pdf package

      setState(() {
        _isGeneratingReport = false;
        _showDataFilters = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isGeneratingReport = false;
      });
    }
  }

  Future<void> _generateClassReport(
    BuildContext context,
    ClassModel classModel,
    List<AttendanceRecord> classAttendance,
    List<dynamic> allStudents,
  ) async {
    // Implementation for generating a report for a specific class
    // This would also involve creating PDFs using the pdf package
  }
}
