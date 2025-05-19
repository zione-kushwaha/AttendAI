import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/common/widgets/empty_state_widget.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/models/attendance_model.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:hajiri/providers/attendance_provider.dart';
import 'package:intl/intl.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  final ClassModel classModel;

  const TakeAttendanceScreen({super.key, required this.classModel});

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  late DateTime _selectedDate;

  // Map of studentId to attendance status
  final Map<String, AttendanceStatus> _attendanceStatus = {};
  // Map of studentId to remarks
  final Map<String, String> _remarks = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadExistingAttendance();
  }

  void _loadExistingAttendance() {
    // Load existing attendance records for this class and date
    final attendanceRecords = ref
        .read(attendanceProvider.notifier)
        .getAttendanceByClassAndDate(widget.classModel.id, _selectedDate);

    // Pre-populate attendance status and remarks
    for (final record in attendanceRecords) {
      _attendanceStatus[record.studentId] = record.status;
      if (record.remark != null) {
        _remarks[record.studentId] = record.remark!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final students =
        ref
            .watch(studentProvider)
            .where((student) => student.classIds.contains(widget.classModel.id))
            .toList()
          ..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Take Attendance',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          Expanded(
            child:
                students.isEmpty
                    ? EmptyStateWidget(
                      message: 'No students in this class',
                      icon: Icons.people_outline,
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _buildAttendanceItem(student);
                      },
                    ),
          ),
          _buildSubmitButton(students),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Text(
              '${widget.classModel.name} - ${widget.classModel.subject}',
              style: TextStyle(
                fontWeight: FontWeight.bold,

                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          FittedBox(
            child: Text(
              DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(StudentModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(student.name[0].toUpperCase())),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('Roll No: ${student.rollNumber}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusButton(
                    student.id,
                    AttendanceStatus.present,
                    'Present',
                    Colors.green,
                    Icons.check_circle,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    student.id,
                    AttendanceStatus.absent,
                    'Absent',
                    Colors.red,
                    Icons.cancel,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    student.id,
                    AttendanceStatus.late,
                    'Late',
                    Colors.orange,
                    Icons.access_time,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    student.id,
                    AttendanceStatus.excused,
                    'Excused',
                    Colors.blue,
                    Icons.medical_services,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _addRemark(student.id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _remarks.containsKey(student.id)
                          ? Icons.edit_note
                          : Icons.add_comment,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _remarks.containsKey(student.id)
                          ? 'Edit Remark'
                          : 'Add Remark',
                    ),
                  ],
                ),
              ),
            ),
            if (_remarks.containsKey(student.id)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Text(_remarks[student.id]!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String studentId,
    AttendanceStatus status,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = _attendanceStatus[studentId] == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _attendanceStatus[studentId] = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(List<StudentModel> students) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: students.isEmpty ? null : _submitAttendance,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save),
            SizedBox(width: 8),
            Text('Save Attendance', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _attendanceStatus.clear();
        _remarks.clear();
      });

      _loadExistingAttendance();
    }
  }

  void _addRemark(String studentId) {
    final controller = TextEditingController(text: _remarks[studentId] ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Remark'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter remark here',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (controller.text.isNotEmpty) {
                      _remarks[studentId] = controller.text;
                    } else {
                      _remarks.remove(studentId);
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _submitAttendance() {
    final students =
        ref
            .read(studentProvider)
            .where((student) => student.classIds.contains(widget.classModel.id))
            .toList();

    // Ensure all students have an attendance status
    for (final student in students) {
      if (!_attendanceStatus.containsKey(student.id)) {
        _attendanceStatus[student.id] = AttendanceStatus.present;
      }

      final attendanceRecord = AttendanceRecord(
        classId: widget.classModel.id,
        studentId: student.id,
        date: _selectedDate,
        status: _attendanceStatus[student.id]!,
        remark: _remarks[student.id],
      );

      ref.read(attendanceProvider.notifier).markAttendance(attendanceRecord);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance saved successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }
}
