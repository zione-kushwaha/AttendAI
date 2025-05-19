import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/empty_state_widget.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:hajiri/features/attendance/class_attendance_screen.dart';
import 'package:intl/intl.dart';
import 'take_attendance_screen.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classProvider);
    final today = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      body: Column(
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(today),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a class to view or take attendance',
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
                      message:
                          'No classes added yet.\nAdd classes to take attendance.',
                      icon: Icons.class_outlined,
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final classItem = classes[index];
                        return _buildClassCard(context, classItem);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, ClassModel classItem) {
    // Check if the class is scheduled for today
    final now = DateTime.now();
    final today = DateFormat('EEEE').format(now);
    final isScheduledToday =
        classItem.schedule.containsKey(today) &&
        classItem.schedule[today] is List &&
        (classItem.schedule[today] as List).length == 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToClassAttendance(context, classItem),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classItem.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classItem.subject,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isScheduledToday
                              ? Colors.green.withValues(alpha: .2)
                              : Colors.grey.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isScheduledToday ? 'Today' : 'Not Today',
                      style: TextStyle(
                        color: isScheduledToday ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _navigateToClassAttendance(context, classItem),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('View Records'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _navigateToTakeAttendance(context, classItem),
                      icon: const Icon(Icons.how_to_reg),
                      label: FittedBox(child: const Text('Take Attendance')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToClassAttendance(BuildContext context, ClassModel classItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassAttendanceScreen(classModel: classItem),
      ),
    );
  }

  void _navigateToTakeAttendance(BuildContext context, ClassModel classItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TakeAttendanceScreen(classModel: classItem),
      ),
    );
  }
}
