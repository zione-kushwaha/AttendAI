import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/common/widgets/animated_empty_state.dart';
import 'package:hajiri/common/widgets/stylish_container.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/features/students/add_edit_student_screen.dart';
import 'package:hajiri/features/students/bulk_add_students_screen.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  String _searchQuery = '';
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final allStudents = ref.watch(studentProvider);
    final classes = ref.watch(classProvider);

    // Filter students based on search query and selected class
    final filteredStudents =
        allStudents.where((student) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              student.rollNumber.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          final matchesClass =
              _selectedClassId == null ||
              student.classIds.contains(_selectedClassId);

          return matchesSearch && matchesClass;
        }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Students', showBackButton: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
                const SizedBox(height: 16),
                StylishContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedClassId,
                      hint: const Text('Filter by class'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Classes'),
                        ),
                        ...classes.map(
                          (classItem) => DropdownMenuItem<String?>(
                            value: classItem.id,
                            child: Text(classItem.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value;
                        });
                      },
                    ),
                  ),
                ).animate().fadeIn(
                  duration: const Duration(milliseconds: 300),
                  delay: const Duration(milliseconds: 100),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                filteredStudents.isEmpty
                    ? AnimatedEmptyState(
                      message: 'No students found',
                      icon: Icons.person_search,
                      buttonText: 'Add Student',
                      onButtonPressed: () => _navigateToAddStudent(context),
                      animationAsset: 'assets/animations/empty_state.json',
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];

                        // Get class names for this student
                        final studentClasses = classes
                            .where((c) => student.classIds.contains(c.id))
                            .map((c) => c.name)
                            .join(', ');

                        return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                      student.photoPath == null
                                          ? AppColors.secondary
                                          : null,
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
                                    Text(
                                      'Classes: $studentClasses',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _navigateToEditStudent(context, student);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(context, student);
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
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                                onTap:
                                    () => _navigateToEditStudent(
                                      context,
                                      student,
                                    ),
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
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFloatingActionMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFloatingActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.person_add, color: Colors.white),
                    ),
                    title: const Text('Add Single Student'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToAddStudent(context);
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary,
                      child: const Icon(Icons.group_add, color: Colors.white),
                    ),
                    title: const Text('Bulk Add Students'),
                    onTap: () {
                      Navigator.pop(context);
                      _showBulkAddOptions(context);
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent1,
                      child: const Icon(
                        Icons.import_export,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text('Import/Export'),
                    subtitle: const Text('Coming soon'),
                    onTap: () {
                      Navigator.pop(context);
                      _showImportExportOptions(context);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _navigateToAddStudent(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                AddEditStudentScreen(preselectedClassId: _selectedClassId),
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

  void _showBulkAddOptions(BuildContext context) {
    final classes = ref.read(classProvider);

    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please create a class first before adding multiple students',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select a Class for Bulk Add',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...classes
                    .map(
                      (classModel) => ListTile(
                        leading: CircleAvatar(
                          child: Text(classModel.name[0]),
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                        title: Text(classModel.name),
                        subtitle: Text(classModel.subject),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToBulkAddScreen(context, classModel);
                        },
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
    );
  }

  void _navigateToBulkAddScreen(BuildContext context, ClassModel classModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulkStudentAddScreen(classModel: classModel),
      ),
    );
  }

  void _showImportExportOptions(BuildContext context) {
    // Future feature: Import/Export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import/Export functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StudentModel student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Student'),
            content: Text('Are you sure you want to delete ${student.name}?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(studentProvider.notifier).deleteStudent(student.id);
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
