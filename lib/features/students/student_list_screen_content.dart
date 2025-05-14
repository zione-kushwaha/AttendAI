import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/animated_empty_state.dart';
import 'package:hajiri/common/widgets/stylish_container.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/features/students/add_edit_student_screen.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Content-only version of StudentListScreen without AppBar
class StudentListScreenContent extends ConsumerStatefulWidget {
  const StudentListScreenContent({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentListScreenContent> createState() =>
      _StudentListScreenContentState();
}

class _StudentListScreenContentState
    extends ConsumerState<StudentListScreenContent> {
  String _searchQuery = '';
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final allStudents = ref.watch(studentProvider);
    final classes = ref.watch(classProvider);

    // Filter students based on search query and selected class
    final students =
        allStudents.where((student) {
          final matchesSearch =
              student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              student.rollNumber.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
          final matchesClass =
              _selectedClassId == null ||
              student.classIds.contains(_selectedClassId);
          return matchesSearch && matchesClass;
        }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildClassFilter(classes),
            ],
          ),
        ),
        Expanded(
          child:
              students.isEmpty &&
                      (_searchQuery.isEmpty && _selectedClassId == null)
                  ? AnimatedEmptyState(
                    message: 'No students added yet',
                    icon: Icons.people_outline,
                    buttonText: 'Add Student',
                    onButtonPressed: () => _navigateToAddStudent(context),
                    animationAsset: 'assets/animations/empty_students.json',
                  )
                  : students.isEmpty
                  ? Center(
                    child: Text(
                      'No students match your search',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final studentClass = classes.firstWhere(
                        (c) => student.classIds.contains(c.id),
                        orElse:
                            () => ClassModel(
                              id: '',
                              name: 'Unknown Class',
                              description: '',
                              schedule: {},
                              subject: '',
                            ),
                      );

                      return _buildStudentCard(context, student, studentClass)
                          .animate()
                          .fade(
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            delay: Duration(milliseconds: index * 30),
                          )
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: Duration(
                              milliseconds: 300 + (index * 30),
                            ),
                            curve: Curves.easeOutQuad,
                          );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search students...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildClassFilter(List<ClassModel> classes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _selectedClassId,
          hint: const Text('Filter by class'),
          onChanged: (String? value) {
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
        ),
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    StudentModel student,
    ClassModel studentClass,
  ) {
    return GestureDetector(
      onTap: () => _navigateToEditStudent(context, student),
      child: StylishContainer(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStudentAvatar(student),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll: ${student.rollNumber}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      studentClass.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAvatar(StudentModel student) {
    final hasProfileImage =
        student.photoPath != null && student.photoPath!.isNotEmpty;

    return CircleAvatar(
      radius: 28,
      backgroundColor:
          hasProfileImage
              ? Colors.transparent
              : AppColors.primary.withOpacity(0.2),
      backgroundImage:
          hasProfileImage ? FileImage(File(student.photoPath!)) : null,
      child:
          hasProfileImage
              ? null
              : Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
    );
  }

  void _navigateToAddStudent(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditStudentScreen()),
    );
  }

  void _navigateToEditStudent(BuildContext context, StudentModel student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditStudentScreen(student: student),
      ),
    );
  }
}
