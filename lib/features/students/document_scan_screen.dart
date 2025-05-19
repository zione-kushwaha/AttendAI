import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/core/services/document_scanner_service.dart';
import 'package:hajiri/models/student_model.dart';
import 'package:hajiri/providers/student_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class DocumentScanScreen extends ConsumerStatefulWidget {
  final String classID;

  const DocumentScanScreen({super.key, required this.classID});

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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Processing Image...',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Extracting student information',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageSection() {
    return InkWell(
      onTap: _imagePath == null ? _pickImage : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Stack(
          children: [
            if (_imagePath != null) ...[
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Gradient overlay for better visibility of controls
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: .3),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              // Image controls
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _buildControlButton(
                      icon: Icons.refresh_rounded,
                      onPressed: _pickImage,
                      tooltip: 'Change Image',
                    ),
                    const SizedBox(width: 8),
                    _buildControlButton(
                      icon: Icons.close_rounded,
                      onPressed: () {
                        setState(() {
                          _imagePath = null;
                          _recognizedText = null;
                          _extractedStudents = null;
                          _selectedStudents.clear();
                        });
                      },
                      tooltip: 'Remove Image',
                    ),
                  ],
                ),
              ),
              _buildLoadingOverlay(),
            ] else
              // Empty state UI
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.document_scanner_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Tap to scan document',

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use camera or select from gallery',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: .5),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedStudents.length == _extractedStudents!.length) {
                    _selectedStudents.clear();
                  } else {
                    _selectedStudents.addAll(
                      List.generate(
                        _extractedStudents!.length,
                        (i) => i.toString(),
                      ),
                    );
                  }
                });
              },
              icon: Icon(
                _selectedStudents.length == _extractedStudents!.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              label: FittedBox(
                child: Text(
                  _selectedStudents.length == _extractedStudents!.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: TextStyle(fontSize: 10),
                ),
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
            color: Colors.black.withValues(alpha: .1),
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
                onPressed:
                    _selectedStudents.isEmpty || _isProcessing
                        ? null
                        : _importSelectedStudents,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isProcessing
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Image Source',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildSourceOption(
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                        preferredCameraDevice: CameraDevice.rear,
                      );
                      _handleImageSelection(image);
                    },
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    context: context,
                  ),
                  _buildSourceOption(
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      _handleImageSelection(image);
                    },
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    context: context,
                  ),
                  _buildSourceOption(
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                          allowMultiple: false,
                        );

                        if (result != null &&
                            result.files.single.path != null) {
                          _handleImageSelection(
                            XFile(result.files.single.path!),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to pick file. Please try again.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icons.file_present_rounded,
                    label: 'File',
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleImageSelection(XFile? image) {
    if (image != null && mounted) {
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
      // Directly analyze the image with Gemini AI
      List<Map<String, String>> students =
          await DocumentScannerService.analyzeImageWithGemini(
            File(_imagePath!),
          );
      if (mounted) {
        setState(() {
          // We don't need to show recognized text anymore as we're directly analyzing the image
          _recognizedText = "Image processed directly with AI";
          _extractedStudents = students;
          _isProcessing = false;
        });
      }

      // Show success message for better UX
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully extracted ${students.length} student records',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show a more informative error dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Error Processing Document'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      const Text(
                        'There was an error while processing the document:',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Exception: Failed to analyse document. *Error * >  The connection error occurred. Please check your internet connection and try again.",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Possible solutions:'),
                      const SizedBox(height: 4),
                      const Text('• Check your internet connection'),
                      const Text('• Make sure the image is clear and readable'),
                      const Text('• Try with a different document'),
                      const Text('• Restart the app and try again'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
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
      final studentsToImport =
          _selectedStudents
              .map((index) => int.parse(index))
              .map((index) => _extractedStudents![index])
              .toList();

      for (final studentData in studentsToImport) {
        final student = StudentModel(
          name: studentData['name']!,
          rollNumber: studentData['rollNumber']!,
          classIds: [widget.classID],
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing students: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildLoadingOverlay() {
    if (!_isProcessing) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Processing Image...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Extracting student information',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
