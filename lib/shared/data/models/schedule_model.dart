import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/schedule.dart';

part 'schedule_model.g.dart';

@JsonSerializable()
class ScheduleModel {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final List<int> daysOfWeek;
  final bool isActive;
  final List<String> blockedApps;
  final List<String> blockedWebsites;
  final DateTime createdAt;

  const ScheduleModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
    required this.isActive,
    required this.blockedApps,
    required this.blockedWebsites,
    required this.createdAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleModelToJson(this);

  Schedule toDomain() {
    return Schedule(
      id: id,
      name: name,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek,
      isActive: isActive,
      blockedApps: blockedApps,
      blockedWebsites: blockedWebsites,
      createdAt: createdAt,
    );
  }

  static ScheduleModel fromDomain(Schedule schedule) {
    return ScheduleModel(
      id: schedule.id,
      name: schedule.name,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      daysOfWeek: schedule.daysOfWeek,
      isActive: schedule.isActive,
      blockedApps: schedule.blockedApps,
      blockedWebsites: schedule.blockedWebsites,
      createdAt: schedule.createdAt,
    );
  }

  ScheduleModel copyWith({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    List<int>? daysOfWeek,
    bool? isActive,
    List<String>? blockedApps,
    List<String>? blockedWebsites,
    DateTime? createdAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      blockedApps: blockedApps ?? this.blockedApps,
      blockedWebsites: blockedWebsites ?? this.blockedWebsites,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Database mapping methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'days_of_week': daysOfWeek.join(','),
      'is_active': isActive ? 1 : 0,
      'blocked_apps': blockedApps.join(','),
      'blocked_websites': blockedWebsites.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as String,
      name: map['name'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      daysOfWeek: map['days_of_week'] != null 
          ? (map['days_of_week'] as String).split(',').map((e) => int.parse(e)).toList()
          : [],
      isActive: (map['is_active'] as int) == 1,
      blockedApps: map['blocked_apps'] != null 
          ? (map['blocked_apps'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      blockedWebsites: map['blocked_websites'] != null 
          ? (map['blocked_websites'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}