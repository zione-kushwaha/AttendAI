import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/core/database/database_service.dart';
import 'package:hajiri/models/class_model.dart';

class ClassNotifier extends StateNotifier<List<ClassModel>> {
  final DatabaseService _db = DatabaseService();

  ClassNotifier() : super([]) {
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    state = _db.classesBox.values.toList();
  }

  // Add a new class
  Future<void> addClass(ClassModel classModel) async {
    await _db.classesBox.add(classModel);
    _loadClasses();
  }

  // Update a class
  Future<void> updateClass(ClassModel classModel) async {
    await classModel.save();
    _loadClasses();
  }

  // Delete a class and all associated students
  Future<void> deleteClass(String classId) async {
    // Get the class to delete
    final classToDelete = _db.classesBox.values.firstWhere(
      (element) => element.id == classId,
      orElse: () => throw Exception('ClassModel with id $classId not found'),
    );

    // Find all students associated with this class
    final studentsToDelete =
        _db.studentsBox.values
            .where((student) => student.classIds.contains(classId))
            .toList();

    // Delete all students associated with this class
    for (final student in studentsToDelete) {
      await student.delete();
    }

    // Delete the class
    await classToDelete.delete();
    _loadClasses();
  }

  // Get a class by ID
  ClassModel? getClassById(String classId) {
    try {
      return state.firstWhere((element) => element.id == classId);
    } catch (_) {
      return null;
    }
  }
}

final classProvider = StateNotifierProvider<ClassNotifier, List<ClassModel>>((
  ref,
) {
  return ClassNotifier();
});
