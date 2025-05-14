import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'attendance_model.g.dart';

@HiveType(typeId: 3)
enum AttendanceStatus {
  @HiveField(0)
  present,

  @HiveField(1)
  absent,

  @HiveField(2)
  late,

  @HiveField(3)
  excused,
}

@HiveType(typeId: 4)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String classId;

  @HiveField(2)
  final String studentId;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  AttendanceStatus status;

  @HiveField(5)
  String? remark;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  AttendanceRecord({
    String? id,
    required this.classId,
    required this.studentId,
    required this.date,
    required this.status,
    this.remark,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'remark': remark,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      classId: json['classId'],
      studentId: json['studentId'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      remark: json['remark'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Update attendance status
  void updateStatus(AttendanceStatus status, {String? remark}) {
    this.status = status;
    if (remark != null) this.remark = remark;
    updatedAt = DateTime.now();
    save();
  }
}
