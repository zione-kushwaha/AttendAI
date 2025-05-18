import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/student_provider.dart';

class ClassCard extends ConsumerWidget {
  final ClassModel classItem;
  final int index;
  final Color color;
  final Function(BuildContext, ClassModel) onEdit;
  final Function(BuildContext, WidgetRef, ClassModel) onDelete;
  final Function(BuildContext, ClassModel) onTap;

  const ClassCard({
    super.key,
    required this.classItem,
    required this.index,
    required this.color,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentProvider);
    final studentCount = students
        .where((student) => student.classIds.contains(classItem.id))
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with background color
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    classItem.name[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Subject: ${classItem.subject}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Class details
          InkWell(
            onTap: () => onTap(context, classItem),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Icons.schedule,
                        _formatSchedule(classItem.schedule),
                        AppColors.accent1,
                      ),
                    ],
                  ),
                  if (classItem.description != null && classItem.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      context,
                      Icons.description,
                      classItem.description!,
                      AppColors.accent2,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Action buttons
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => onTap(context, classItem),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('VIEW'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey.withOpacity(0.3),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => onEdit(context, classItem),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('EDIT'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey.withOpacity(0.3),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => onDelete(context, ref, classItem),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('DELETE'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
        ).slideY(
          begin: 0.2,
          end: 0,
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          curve: Curves.easeOutQuad,
        );
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
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
            ),
          ),
        ],
      ),
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
}
