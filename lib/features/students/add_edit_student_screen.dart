import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AddEditStudentScreen extends ConsumerStatefulWidget {
  final StudentModel? student;
  final String? preselectedClassId;

  const AddEditStudentScreen({
    super.key,
    this.student,
    this.preselectedClassId,
  });

  @override
  ConsumerState<AddEditStudentScreen> createState() =>
      _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  late List<String> _selectedClassIds;
  String? _photoPath;
  final _additionalInfoController = TextEditingController();

  bool get _isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _nameController.text = widget.student!.name;
      _rollNumberController.text = widget.student!.rollNumber;
      _selectedClassIds = List.from(widget.student!.classIds);
      _photoPath = widget.student!.photoPath;

      if (widget.student!.additionalInfo != null) {
        _additionalInfoController.text =
            widget.student!.additionalInfo!.toString();
      }
    } else {
      _selectedClassIds = [];
      if (widget.preselectedClassId != null) {
        _selectedClassIds.add(widget.preselectedClassId!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classProvider);

    return Scaffold(
      appBar: CustomAppBar(title: _isEditing ? 'Edit Student' : 'Add Student'),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          _photoPath != null
                              ? FileImage(File(_photoPath!))
                              : null,
                      child:
                          _photoPath == null
                              ? Icon(
                                Icons.person,
                                size: 60,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              )
                              : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 24,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                hintText: 'Enter student name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a student name';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rollNumberController,
              decoration: const InputDecoration(
                labelText: 'Roll Number',
                hintText: 'Enter roll number',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a roll number';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Please enter numbers only';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),
            const Text(
              'Classes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (classes.isEmpty) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No classes available. Please create a class first.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else ...[
              ...classes.map(
                (classItem) => CheckboxListTile(
                  title: Text(classItem.name),
                  subtitle: Text(classItem.subject),
                  value: _selectedClassIds.contains(classItem.id),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedClassIds.add(classItem.id);
                      } else {
                        _selectedClassIds.remove(classItem.id);
                      }
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: _additionalInfoController,
              decoration: const InputDecoration(
                labelText: 'Additional Information (Optional)',
                hintText: 'Enter any additional information',
                prefixIcon: Icon(Icons.info),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: classes.isEmpty ? null : _saveStudent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                _isEditing ? 'Update Student' : 'Save Student',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );

    if (image != null) {
      // Save image to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final savedImage = await File(
        image.path,
      ).copy('${appDir.path}/$fileName');

      setState(() {
        _photoPath = savedImage.path;
      });
    }
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClassIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one class')),
        );
        return;
      } // Check for duplicate roll numbers within the same classes
      final studentNotifier = ref.read(studentProvider.notifier);
      final rollNumber = _rollNumberController.text;
      final excludeStudentId = _isEditing ? widget.student!.id : null;

      for (final classId in _selectedClassIds) {
        if (studentNotifier.hasRollNumberInClass(
          rollNumber,
          classId,
          excludeStudentId: excludeStudentId,
        )) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Roll number $rollNumber already exists in class. Please use a unique roll number.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Parse additional info
      Map<String, dynamic>? additionalInfo;
      if (_additionalInfoController.text.isNotEmpty) {
        additionalInfo = {'notes': _additionalInfoController.text};
      }

      if (_isEditing) {
        // Update existing student
        widget.student!.updateDetails(
          name: _nameController.text,
          rollNumber: _rollNumberController.text,
          photoPath: _photoPath,
          additionalInfo: additionalInfo,
        );

        // Update class assignments
        widget.student!.classIds.clear();
        widget.student!.classIds.addAll(_selectedClassIds);

        ref.read(studentProvider.notifier).updateStudent(widget.student!);
      } else {
        // Create new student
        final newStudent = StudentModel(
          name: _nameController.text,
          rollNumber: _rollNumberController.text,
          photoPath: _photoPath,
          classIds: _selectedClassIds,
          additionalInfo: additionalInfo,
        );

        ref.read(studentProvider.notifier).addStudent(newStudent);
      }

      Navigator.of(context).pop();
    }
  }
}
