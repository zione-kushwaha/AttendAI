import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/common/widgets/animated_empty_state.dart';
import 'package:hajiri/common/widgets/stylish_container.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:hajiri/features/classes/add_edit_class_screen.dart';
import 'class_detail_screen.dart';

class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classProvider);
    final students = ref.watch(studentProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Classes', showBackButton: false),
      body:
          classes.isEmpty
              ? AnimatedEmptyState(
                message: 'No classes added yet',
                icon: Icons.class_outlined,
                buttonText: 'Add Class',
                onButtonPressed: () => _navigateToAddClass(context),
                animationAsset: 'assets/animations/empty_state.json',
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classItem = classes[index];
                  return _buildClassCard(
                    context,
                    ref,
                    classItem,
                    students,
                    index,
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddClass(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
        backgroundColor: AppColors.primary,
      ).animate().scale(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    WidgetRef ref,
    ClassModel classItem,
    List<dynamic> students,
    int index,
  ) {
    // Calculate the number of students in this class
    final studentCount =
        students
            .where((student) => student.classIds.contains(classItem.id))
            .length;

    return StylishContainer(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(0),
          elevation: 2,
          child: InkWell(
            onTap: () => _navigateToClassDetail(context, classItem),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getClassColor(index),
                              child: Text(
                                classItem.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    classItem.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Subject: ${classItem.subject}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _navigateToEditClass(context, classItem);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(context, ref, classItem);
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
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        context,
                        Icons.person,
                        '$studentCount Students',
                        AppColors.secondary,
                      ),
                      _buildInfoItem(
                        context,
                        Icons.access_time,
                        _formatSchedule(classItem.schedule),
                        AppColors.accent1,
                      ),
                      _buildInfoItem(
                        context,
                        Icons.description,
                        classItem.description ?? 'No description',
                        AppColors.accent2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed:
                            () => _navigateToClassDetail(context, classItem),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fade(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
        )
        .slideY(
          begin: 0.2,
          end: 0,
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          curve: Curves.easeOutQuad,
        );
  }

  String _formatSchedule(Map<String, dynamic> schedule) {
    if (schedule.isEmpty) {
      return 'No schedule';
    }

    final days = schedule.keys.toList();
    if (days.length > 1) {
      return '${days.length} days/week';
    } else if (days.length == 1) {
      final day = days.first;
      final timeSlot = schedule[day];
      if (timeSlot is List && timeSlot.length == 2) {
        return '$day ${timeSlot[0]} - ${timeSlot[1]}';
      }
      return day;
    }
    return 'Scheduled';
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getClassColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors
          .accent3, // Replace with an existing color getter or define 'tertiary' in AppColors
      AppColors.accent1,
      AppColors.accent2,
    ];
    return colors[index % colors.length];
  }

  void _navigateToAddClass(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddEditClassScreen()));
  }

  void _navigateToEditClass(BuildContext context, ClassModel classItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditClassScreen(classModel: classItem),
      ),
    );
  }

  void _navigateToClassDetail(BuildContext context, ClassModel classItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassDetailScreen(classModel: classItem),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    ClassModel classItem,
  ) {
    final students = ref.read(studentProvider);
    final hasStudents = students.any(
      (student) => student.classIds.contains(classItem.id),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Class'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete ${classItem.name}?'),
                if (hasStudents) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Warning: This class has students. Deleting it will remove this class from their profiles.',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ],
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
                  if (hasStudents) {
                    // Update student records to remove this class
                    for (final student in students) {
                      if (student.classIds.contains(classItem.id)) {
                        // Use the removeClass method provided by StudentModel
                        student.removeClass(classItem.id);
                        // Notify the provider about the change
                        ref
                            .read(studentProvider.notifier)
                            .updateStudent(student);
                      }
                    }
                  }
                  // Delete the class
                  ref.read(classProvider.notifier).deleteClass(classItem.id);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
