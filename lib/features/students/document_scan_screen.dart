import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/core/services/document_scanner_service.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:image_picker/image_picker.dart';

class DocumentScanScreen extends ConsumerStatefulWidget {
  final ClassModel? classModel;

  const DocumentScanScreen({Key? key, this.classModel}) : super(key: key);

  @override
  ConsumerState<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends ConsumerState<DocumentScanScreen> {
  bool _isProcessing = false;
  String? _imagePath;
  String? _recognizedText;
  List<Map<String, String>>? _extractedStudents;
  final Set<String> _selectedStudents = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Scan Document'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            if (_recognizedText != null) ...[
              const SizedBox(height: 20),
              _buildRecognizedTextSection(),
            ],
            if (_extractedStudents != null) ...[
              const SizedBox(height: 20),
              _buildExtractedStudentsSection(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: _imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to select document',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRecognizedTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recognized Text:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Text(_recognizedText!),
        ),
      ],
    );
  }

  Widget _buildExtractedStudentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Extracted Students:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedStudents.length == _extractedStudents!.length) {
                    _selectedStudents.clear();
                  } else {
                    _selectedStudents.addAll(
                      List.generate(
                          _extractedStudents!.length, (i) => i.toString()),
                    );
                  }
                });
              },
              icon: Icon(
                _selectedStudents.length == _extractedStudents!.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              label: Text(
                _selectedStudents.length == _extractedStudents!.length
                    ? 'Deselect All'
                    : 'Select All',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _extractedStudents!.length,
          itemBuilder: (context, index) {
            final student = _extractedStudents![index];
            final isSelected = _selectedStudents.contains(index.toString());

            return CheckboxListTile(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedStudents.add(index.toString());
                  } else {
                    _selectedStudents.remove(index.toString());
                  }
                });
              },
              title: Text(student['name'] ?? 'Unknown'),
              subtitle: Text('Roll Number: ${student['rollNumber'] ?? 'N/A'}'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_imagePath != null)
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _processImage,
                child: const Text('Process Image'),
              ),
            ),
          if (_extractedStudents != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedStudents.isEmpty || _isProcessing
                    ? null
                    : _importSelectedStudents,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Import Selected'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _recognizedText = null;
        _extractedStudents = null;
        _selectedStudents.clear();
      });
    }
  }

  Future<void> _processImage() async {
    if (_imagePath == null) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = null;
      _extractedStudents = null;
      _selectedStudents.clear();
    });

    try {
      final text = await DocumentScannerService.recognizeText(_imagePath!);
      final students = await DocumentScannerService.analyzeWithGemini(text);

      if (mounted) {
        setState(() {
          _recognizedText = text;
          _extractedStudents = students;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _importSelectedStudents() async {
    setState(() => _isProcessing = true);

    try {
      // Check if class model is null
      if (widget.classModel == null) {
        throw Exception('No class selected for importing students');
      }

      final studentsToImport = _selectedStudents
          .map((index) => int.parse(index))
          .map((index) => _extractedStudents![index])
          .toList();

      for (final studentData in studentsToImport) {
        final student = StudentModel(
          name: studentData['name']!,
          rollNumber: studentData['rollNumber']!,
          classIds: [widget.classModel!.id],
        );

        await ref.read(studentProvider.notifier).addStudent(student);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${studentsToImport.length} students',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing students: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
