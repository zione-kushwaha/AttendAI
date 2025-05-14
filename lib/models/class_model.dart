import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'class_model.g.dart';

@HiveType(typeId: 1)
class ClassModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String subject;

  @HiveField(3)
  String? description;

  @HiveField(4)
  Map<String, dynamic> schedule; // {day: [startTime, endTime]}

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  ClassModel({
    String? id,
    required this.name,
    required this.subject,
    this.description,
    required this.schedule,
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
      'subject': subject,
      'description': description,
      'schedule': schedule,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      subject: json['subject'],
      description: json['description'],
      schedule: json['schedule'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Update class details
  void updateDetails({
    String? name,
    String? subject,
    String? description,
    Map<String, dynamic>? schedule,
  }) {
    if (name != null) this.name = name;
    if (subject != null) this.subject = subject;
    if (description != null) this.description = description;
    if (schedule != null) this.schedule = schedule;
    updatedAt = DateTime.now();
    save();
  }
}
