import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/widgets/custom_app_bar.dart';
import 'package:hajiri/models/class_model.dart';
import 'package:hajiri/providers/class_provider.dart';
import 'package:intl/intl.dart';

class AddEditClassScreen extends ConsumerStatefulWidget {
  final ClassModel? classModel;

  const AddEditClassScreen({super.key, this.classModel});

  @override
  ConsumerState<AddEditClassScreen> createState() => _AddEditClassScreenState();
}

class _AddEditClassScreenState extends ConsumerState<AddEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Map<String, List<TimeOfDay>> _schedule = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  bool get _isEditing => widget.classModel != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.classModel!.name;
      _subjectController.text = widget.classModel!.subject;
      _descriptionController.text = widget.classModel!.description ?? '';

      // Load schedule
      widget.classModel!.schedule.forEach((day, times) {
        if (times is List && times.length == 2) {
          final startTime = _parseTimeString(times[0]);
          final endTime = _parseTimeString(times[1]);

          if (startTime != null && endTime != null) {
            _schedule[day] = [startTime, endTime];
          }
        }
      });
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _isEditing ? 'Edit Class' : 'Add Class'),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                hintText: 'Enter class name',
                prefixIcon: Icon(Icons.class_),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a class name';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'Enter subject name',
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter class description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Class Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._schedule.entries.map(
              (entry) => _buildDayScheduleCard(entry.key, entry.value),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveClass,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                _isEditing ? 'Update Class' : 'Save Class',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayScheduleCard(String day, List<TimeOfDay> times) {
    final hasSchedule = times.length == 2;
    final startTimeStr =
        hasSchedule ? _formatTimeOfDay(times[0]) : 'Not scheduled';
    final endTimeStr = hasSchedule ? _formatTimeOfDay(times[1]) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Switch(
                  value: hasSchedule,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        // Set default times if enabled
                        _schedule[day] = [
                          const TimeOfDay(hour: 9, minute: 0),
                          const TimeOfDay(hour: 10, minute: 0),
                        ];
                      } else {
                        _schedule[day] = [];
                      }
                    });
                  },
                ),
              ],
            ),
            if (hasSchedule) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, day, 0),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(startTimeStr),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, day, 1),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(endTimeStr),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String day, int index) async {
    final initialTime =
        _schedule[day]!.isNotEmpty ? _schedule[day]![index] : TimeOfDay.now();

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      setState(() {
        _schedule[day]![index] = selectedTime;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    return DateFormat.jm().format(dt);
  }

  void _saveClass() {
    if (_formKey.currentState!.validate()) {
      // Prepare schedule data
      final scheduleData = <String, dynamic>{};

      _schedule.forEach((day, times) {
        if (times.length == 2) {
          scheduleData[day] = [
            '${times[0].hour}:${times[0].minute}',
            '${times[1].hour}:${times[1].minute}',
          ];
        }
      });

      if (_isEditing) {
        // Update existing class
        widget.classModel!.updateDetails(
          name: _nameController.text,
          subject: _subjectController.text,
          description:
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          schedule: scheduleData,
        );

        ref.read(classProvider.notifier).updateClass(widget.classModel!);
      } else {
        // Create new class
        final newClass = ClassModel(
          name: _nameController.text,
          subject: _subjectController.text,
          description:
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          schedule: scheduleData,
        );

        ref.read(classProvider.notifier).addClass(newClass);
      }

      Navigator.of(context).pop();
    }
  }
}
