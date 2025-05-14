import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/core/database/database_service.dart';
import 'package:hajiri/models/student_model.dart';

class StudentNotifier extends StateNotifier<List<StudentModel>> {
  final DatabaseService _db = DatabaseService();

  StudentNotifier() : super([]) {
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    state = _db.studentsBox.values.toList();
  }

  // Add a new student
  Future<void> addStudent(StudentModel student) async {
    await _db.studentsBox.add(student);
    _loadStudents();
  }

  // Update a student
  Future<void> updateStudent(StudentModel student) async {
    await student.save();
    _loadStudents();
  }

  // Delete a student
  Future<void> deleteStudent(String studentId) async {
    final studentToDelete = _db.studentsBox.values.firstWhere(
      (element) => element.id == studentId,
      orElse: () => throw Exception('Student not found'),
    );

    await studentToDelete.delete();
    _loadStudents();
  }

  // Get a student by ID
  StudentModel? getStudentById(String studentId) {
    try {
      return state.firstWhere((element) => element.id == studentId);
    } catch (_) {
      return null;
    }
  }

  // Get students by class ID
  List<StudentModel> getStudentsByClassId(String classId) {
    return state
        .where((student) => student.classIds.contains(classId))
        .toList();
  }
}

final studentProvider =
    StateNotifierProvider<StudentNotifier, List<StudentModel>>((ref) {
      return StudentNotifier();
    });
