import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/emergency_override.dart';

part 'emergency_override_model.g.dart';

@JsonSerializable()
class EmergencyOverrideModel {
  final String id;
  final DateTime requestedAt;
  final DateTime? activatedAt;
  final int delayDurationMinutes;
  final int overrideDurationMinutes;
  final String reason;
  final bool isActive;
  final bool hasExpired;

  const EmergencyOverrideModel({
    required this.id,
    required this.requestedAt,
    this.activatedAt,
    required this.delayDurationMinutes,
    required this.overrideDurationMinutes,
    required this.reason,
    required this.isActive,
    required this.hasExpired,
  });

  factory EmergencyOverrideModel.fromJson(Map<String, dynamic> json) =>
      _$EmergencyOverrideModelFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyOverrideModelToJson(this);

  EmergencyOverride toDomain() {
    return EmergencyOverride(
      id: id,
      requestedAt: requestedAt,
      activatedAt: activatedAt,
      delayDuration: Duration(minutes: delayDurationMinutes),
      overrideDuration: Duration(minutes: overrideDurationMinutes),
      reason: reason,
      isActive: isActive,
      hasExpired: hasExpired,
    );
  }

  static EmergencyOverrideModel fromDomain(EmergencyOverride override) {
    return EmergencyOverrideModel(
      id: override.id,
      requestedAt: override.requestedAt,
      activatedAt: override.activatedAt,
      delayDurationMinutes: override.delayDuration.inMinutes,
      overrideDurationMinutes: override.overrideDuration.inMinutes,
      reason: override.reason,
      isActive: override.isActive,
      hasExpired: override.hasExpired,
    );
  }

  EmergencyOverrideModel copyWith({
    String? id,
    DateTime? requestedAt,
    DateTime? activatedAt,
    int? delayDurationMinutes,
    int? overrideDurationMinutes,
    String? reason,
    bool? isActive,
    bool? hasExpired,
  }) {
    return EmergencyOverrideModel(
      id: id ?? this.id,
      requestedAt: requestedAt ?? this.requestedAt,
      activatedAt: activatedAt ?? this.activatedAt,
      delayDurationMinutes: delayDurationMinutes ?? this.delayDurationMinutes,
      overrideDurationMinutes: overrideDurationMinutes ?? this.overrideDurationMinutes,
      reason: reason ?? this.reason,
      isActive: isActive ?? this.isActive,
      hasExpired: hasExpired ?? this.hasExpired,
    );
  }

  // Database mapping methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requested_at': requestedAt.millisecondsSinceEpoch,
      'activated_at': activatedAt?.millisecondsSinceEpoch,
      'delay_duration_minutes': delayDurationMinutes,
      'override_duration_minutes': overrideDurationMinutes,
      'reason': reason,
      'is_active': isActive ? 1 : 0,
      'has_expired': hasExpired ? 1 : 0,
    };
  }

  factory EmergencyOverrideModel.fromMap(Map<String, dynamic> map) {
    return EmergencyOverrideModel(
      id: map['id'] as String,
      requestedAt: DateTime.fromMillisecondsSinceEpoch(map['requested_at'] as int),
      activatedAt: map['activated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['activated_at'] as int)
          : null,
      delayDurationMinutes: map['delay_duration_minutes'] as int,
      overrideDurationMinutes: map['override_duration_minutes'] as int,
      reason: map['reason'] as String,
      isActive: (map['is_active'] as int) == 1,
      hasExpired: (map['has_expired'] as int) == 1,
    );
  }
}