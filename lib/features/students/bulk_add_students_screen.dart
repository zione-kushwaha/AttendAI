import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/common/utils/animation_helpers.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/common/widgets/stylish_container.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:uuid/uuid.dart';

class BulkStudentAddScreen extends ConsumerStatefulWidget {
  final ClassModel classModel;

  const BulkStudentAddScreen({Key? key, required this.classModel})
    : super(key: key);

  @override
  ConsumerState<BulkStudentAddScreen> createState() =>
      _BulkStudentAddScreenState();
}

class _BulkStudentAddScreenState extends ConsumerState<BulkStudentAddScreen> {
  final formKey = GlobalKey<FormState>();
  final List<StudentEntry> studentEntries = [StudentEntry()];
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add Multiple Students',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimationHelpers.fadeInDown(
              child: StylishContainer.gradient(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adding students to:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.classModel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Students: ${studentEntries.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  ...AnimationHelpers.staggeredList(
                    children: _buildStudentEntryFields(),
                  ),
                  const SizedBox(height: 16),
                  AnimationHelpers.fadeInUp(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _addNewStudentEntry,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Another'),
                        ),
                        if (studentEntries.length > 1)
                          FittedBox(
                            child: OutlinedButton.icon(
                              onPressed: _removeLastEntry,
                              icon: const Icon(Icons.remove),
                              label: const Text(
                                'Remove Last',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimationHelpers.fadeInUp(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: isProcessing ? null : _saveBulkStudents,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
            ),
            child:
                isProcessing
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Processing...'),
                      ],
                    )
                    : const Text('Save All Students'),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudentEntryFields() {
    return List.generate(
      studentEntries.length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: StylishContainer.card(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Student ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (studentEntries.length > 1)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: () => _removeStudentEntry(index),
                      tooltip: 'Remove this student',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                onChanged: (value) => studentEntries[index].name = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  prefixIcon: Icon(Icons.numbers),
                ),
                onChanged: (value) => studentEntries[index].rollNumber = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Roll number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => studentEntries[index].phoneNumber = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => studentEntries[index].email = value,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewStudentEntry() {
    setState(() {
      studentEntries.add(StudentEntry());
    });
  }

  void _removeLastEntry() {
    if (studentEntries.length > 1) {
      setState(() {
        studentEntries.removeLast();
      });
    }
  }

  void _removeStudentEntry(int index) {
    if (studentEntries.length > 1) {
      setState(() {
        studentEntries.removeAt(index);
      });
    }
  }

  void _saveBulkStudents() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isProcessing = true;
      });

      // Add a small delay to simulate processing
      await Future.delayed(const Duration(milliseconds: 800));

      final studentNotifier = ref.read(studentProvider.notifier);
      final students =
          studentEntries.map((entry) {
            return StudentModel(
              id: const Uuid().v4(),
              name: entry.name.trim(),
              rollNumber: entry.rollNumber.trim(),
              classIds: [widget.classModel.id],
            );
          }).toList();

      // Add all students
      for (final student in students) {
        await studentNotifier.addStudent(student);
      }

      if (mounted) {
        setState(() {
          isProcessing = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added ${students.length} students'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bulk Add Help'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How to use:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Fill out the details for each student'),
                  Text('2. Use "Add Another" to add more students'),
                  Text(
                    '3. Remove entries with the delete button or "Remove Last"',
                  ),
                  Text('4. Click "Save All Students" when finished'),
                  SizedBox(height: 16),
                  Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Name and Roll Number are required'),
                  Text('• Phone and Email are optional'),
                  Text('• You can add photos later by editing each student'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }
}

class StudentEntry {
  String name = '';
  String rollNumber = '';
  String? phoneNumber;
  String? email;

  StudentEntry({
    this.name = '',
    this.rollNumber = '',
    this.phoneNumber,
    this.email,
  });
}
