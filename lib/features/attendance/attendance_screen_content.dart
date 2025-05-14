import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/empty_state_widget.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:hajiri/features/attendance/class_attendance_screen.dart';
import 'package:intl/intl.dart';
import 'take_attendance_screen.dart';

// Content-only version of AttendanceScreen without AppBar
class AttendanceScreenContent extends ConsumerWidget {
  const AttendanceScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classProvider);
    final today = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(today),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              classes.isEmpty
                  ? const EmptyStateWidget(
                    icon: Icons.class_outlined,
                    message: 'No classes available for attendance',
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark Attendance',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...classes.map(
                          (classModel) => _buildClassCard(context, classModel),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Attendance Records',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...classes.map(
                          (classModel) =>
                              _buildAttendanceRecordCard(context, classModel),
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildClassCard(BuildContext context, ClassModel classModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          classModel.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(classModel.description ?? 'No description available'),
            const SizedBox(height: 8),
            _buildScheduleChip(classModel),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _navigateToTakeAttendance(context, classModel),
          child: const Text('Mark Now'),
        ),
      ),
    );
  }

  Widget _buildAttendanceRecordCard(
    BuildContext context,
    ClassModel classModel,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          classModel.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('View and edit attendance records'),
        trailing: OutlinedButton(
          onPressed: () => _navigateToClassAttendance(context, classModel),
          child: const Text('View Records'),
        ),
      ),
    );
  }

  Widget _buildScheduleChip(ClassModel classModel) {
    final todayName = DateFormat('EEEE').format(DateTime.now());
    final hasClassToday = classModel.schedule.containsKey(todayName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            hasClassToday
                ? Colors.green.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        hasClassToday ? 'Class Today' : 'No Class Today',
        style: TextStyle(
          color: hasClassToday ? Colors.green[800] : Colors.grey[700],
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  void _navigateToTakeAttendance(BuildContext context, ClassModel classModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TakeAttendanceScreen(classModel: classModel),
      ),
    );
  }

  void _navigateToClassAttendance(BuildContext context, ClassModel classModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassAttendanceScreen(classModel: classModel),
      ),
    );
  }
}
