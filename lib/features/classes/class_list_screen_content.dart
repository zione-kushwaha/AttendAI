import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hajiri/common/widgets/animated_empty_state.dart';
import 'package:hajiri/common/widgets/stylish_container.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:hajiri/features/classes/add_edit_class_screen.dart';
import 'class_detail_screen.dart';

// This is a content-only version of ClassListScreen without AppBar
class ClassListScreenContent extends ConsumerWidget {
  const ClassListScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classProvider);
    final students = ref.watch(studentProvider);

    if (classes.isEmpty) {
      return AnimatedEmptyState(
        message: 'No classes added yet',
        icon: Icons.class_outlined,
        buttonText: 'Add Class',
        onButtonPressed: () => _navigateToAddClass(context),
        animationAsset: 'assets/animations/empty_state.json',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Your Classes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classModel = classes[index];
                final studentCount =
                    students
                        .where((student) => student.classIds == classModel.id)
                        .length;

                return _buildClassCard(context, classModel, studentCount)
                    .animate()
                    .fade(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      delay: Duration(milliseconds: index * 50),
                    )
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOutQuad,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    ClassModel classModel,
    int studentCount,
  ) {
    return GestureDetector(
      onTap: () => _navigateToClassDetail(context, classModel),
      child: StylishContainer(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    classModel.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        studentCount.toString(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              classModel.description ?? 'No description available',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            _buildSchedulePreview(classModel),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulePreview(ClassModel classModel) {
    if (classModel.schedule.isEmpty) {
      return const Text('No schedule set');
    }

    // Display up to 2 schedule days as preview
    final previewDays = classModel.schedule.entries.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          previewDays.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatScheduleEntry(entry),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _formatScheduleEntry(MapEntry<String, dynamic> entry) {
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

  void _navigateToClassDetail(BuildContext context, ClassModel classModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassDetailScreen(classModel: classModel),
      ),
    );
  }

  void _navigateToAddClass(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddEditClassScreen()));
  }
}
