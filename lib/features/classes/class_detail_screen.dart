import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hajiri/common/widgets/animated_empty_state.dart';
import 'package:hajiri/common/widgets/stylish_container.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/features/attendance/take_attendance_screen.dart';
import 'package:hajiri/features/students/add_edit_student_screen.dart';
import 'package:hajiri/features/students/bulk_add_students_screen.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:intl/intl.dart';

class ClassDetailScreen extends ConsumerWidget {
  final ClassModel classModel;

  const ClassDetailScreen({Key? key, required this.classModel})
    : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students =
        ref
            .watch(studentProvider)
            .where((student) => student.classIds.contains(classModel.id))
            .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    classModel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.subject,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Subject: ${classModel.subject}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Schedule: ${_formatScheduleString(classModel.schedule)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Description: ${classModel.description ?? "N/A"}',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.how_to_reg),
                    onPressed: () => _navigateToTakeAttendance(context),
                    tooltip: 'Take Attendance',
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () => _navigateToAddStudent(context),
                    tooltip: 'Add Student',
                  ),
                  IconButton(
                    icon: const Icon(Icons.group_add),
                    onPressed: () => _navigateToBulkAddStudents(context, ref),
                    tooltip: 'Bulk Add Students',
                  ),
                ],
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.people), text: 'Students'),
                      Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'),
                    ],
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildStudentsTab(context, ref, students),
              _buildScheduleTab(context),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToTakeAttendance(context),
          icon: const Icon(Icons.how_to_reg),
          label: const Text('Take Attendance'),
          backgroundColor: AppColors.primary,
        ).animate().scale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  Widget _buildStudentsTab(
    BuildContext context,
    WidgetRef ref,
    List<StudentModel> students,
  ) {
    if (students.isEmpty) {
      return AnimatedEmptyState(
        message: 'No students in this class yet',
        icon: Icons.people_outline,
        buttonText: 'Add Student',
        onButtonPressed: () => _navigateToAddStudent(context),
        animationAsset: 'assets/animations/empty_state.json',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return StylishContainer(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(0),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      student.photoPath != null
                          ? FileImage(File(student.photoPath!))
                          : null,
                  backgroundColor:
                      student.photoPath == null ? AppColors.secondary : null,
                  child:
                      student.photoPath == null
                          ? Text(
                            student.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                title: Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Roll No: ${student.rollNumber}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToEditStudent(context, student);
                    } else if (value == 'remove') {
                      _showRemoveConfirmation(context, ref, student);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Remove from Class',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
                onTap: () => _navigateToEditStudent(context, student),
              ),
            )
            .animate()
            .fade(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 50 * index),
            )
            .slideY(
              begin: 0.1,
              end: 0,
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 50 * index),
              curve: Curves.easeOutQuad,
            );
      },
    );
  }

  Widget _buildScheduleTab(BuildContext context) {
    // Convert the schedule map to a list of day-time strings
    final daySchedules =
        classModel.schedule.entries.map((entry) {
          final day = entry.key;
          final timeRange = entry.value;
          final startTime = timeRange[0];
          final endTime = timeRange.length > 1 ? timeRange[1] : '';
          return '$day: $startTime${endTime.isNotEmpty ? ' - $endTime' : ''}';
        }).toList();
    final today = DateFormat('EEEE').format(DateTime.now());
    final isClassToday = _hasDaySchedule(today);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StylishContainer(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.7),
                AppColors.primary.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Schedule',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Schedule for ${classModel.name}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
          const SizedBox(height: 24),
          if (isClassToday)
            StylishContainer(
              color: AppColors.secondary.withOpacity(0.1),
              borderColor: AppColors.secondary,
              borderWidth: 1,
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.secondary,
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Today\'s Class',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You have a $today class at ${_formatScheduleString({today: classModel.schedule[today]})}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToTakeAttendance(context),
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Take Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ).animate().slideX(
              begin: -0.2,
              end: 0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuad,
            ),
          const Text(
            'Weekly Schedule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 300),
            delay: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 16),
          ...daySchedules.asMap().entries.map((entry) {
            final index = entry.key;
            final daySchedule = entry.value;
            final parts = daySchedule.split(': ');
            final day = parts[0];
            final time = parts[1];
            final isToday = day == today;

            return StylishContainer(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: isToday ? AppColors.secondary.withOpacity(0.1) : null,
              borderColor: isToday ? AppColors.secondary : null,
              borderWidth: isToday ? 1 : 0,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        isToday
                            ? AppColors.secondary
                            : Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7),
                    child: Text(
                      day[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 8),
                            Text(time),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isToday)
                    const Icon(
                      Icons.notifications_active,
                      color: AppColors.secondary,
                    ),
                ],
              ),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 100 * index),
            );
          }).toList(),
          const SizedBox(height: 24),
          StylishContainer(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Class Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.subject, 'Subject', classModel.subject),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.description,
                  'Description',
                  classModel.description ?? 'No description',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.schedule,
                  'Schedule Details',
                  classModel.schedule.entries
                      .map((e) => '${e.key}: ${e.value[0]} - ${e.value[1]}')
                      .join(', '),
                ),
              ],
            ),
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToAddStudent(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                AddEditStudentScreen(preselectedClassId: classModel.id),
      ),
    );
  }

  void _navigateToBulkAddStudents(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulkStudentAddScreen(classModel: classModel),
      ),
    );
  }

  void _navigateToEditStudent(BuildContext context, StudentModel student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditStudentScreen(student: student),
      ),
    );
  }

  void _navigateToTakeAttendance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TakeAttendanceScreen(classModel: classModel),
      ),
    );
  }

  void _showRemoveConfirmation(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove from Class'),
            content: Text(
              'Are you sure you want to remove ${student.name} from ${classModel.name}?',
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
                  final updatedClassIds = [...student.classIds];
                  updatedClassIds.remove(classModel.id);

                  // Use the removeClass method directly
                  student.removeClass(classModel.id);

                  // Update the student in the provider
                  ref.read(studentProvider.notifier).updateStudent(student);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // Helper method to format schedule for display
  String _formatScheduleString(Map<String, dynamic> schedule) {
    if (schedule.isEmpty) {
      return 'Not set';
    }

    final entry = schedule.entries.first;
    final day = entry.key;
    final times = entry.value;

    if (times is List && times.isNotEmpty) {
      if (times.length > 1) {
        return '$day: ${times[0]} - ${times[1]}';
      } else {
        return '$day: ${times[0]}';
      }
    }

    return 'Schedule info unavailable';
  }

  // Check if a specific day has classes
  bool _hasDaySchedule(String day) {
    return classModel.schedule.containsKey(day);
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
