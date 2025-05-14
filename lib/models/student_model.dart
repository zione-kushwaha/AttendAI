import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'student_model.g.dart';

@HiveType(typeId: 2)
class StudentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String rollNumber;

  @HiveField(3)
  String? photoPath; // Path to local photo file

  @HiveField(4)
  List<String> classIds; // List of class IDs this student belongs to

  @HiveField(5)
  Map<String, dynamic>? additionalInfo; // Optional additional information

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  StudentModel({
    String? id,
    required this.name,
    required this.rollNumber,
    this.photoPath,
    required this.classIds,
    this.additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
      'photoPath': photoPath,
      'classIds': classIds,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['name'],
      rollNumber: json['rollNumber'],
      photoPath: json['photoPath'],
      classIds: List<String>.from(json['classIds']),
      additionalInfo: json['additionalInfo'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Add student to a class
  void addClass(String classId) {
    if (!classIds.contains(classId)) {
      classIds.add(classId);
      updatedAt = DateTime.now();
      save();
    }
  }

  // Remove student from a class
  void removeClass(String classId) {
    if (classIds.contains(classId)) {
      classIds.remove(classId);
      updatedAt = DateTime.now();
      save();
    }
  }

  // Update student details
  void updateDetails({
    String? name,
    String? rollNumber,
    String? photoPath,
    Map<String, dynamic>? additionalInfo,
  }) {
    if (name != null) this.name = name;
    if (rollNumber != null) this.rollNumber = rollNumber;
    if (photoPath != null) this.photoPath = photoPath;
    if (additionalInfo != null) this.additionalInfo = additionalInfo;
    updatedAt = DateTime.now();
    save();
  }
}
