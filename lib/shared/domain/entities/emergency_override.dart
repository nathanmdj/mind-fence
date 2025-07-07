import 'package:equatable/equatable.dart';

class EmergencyOverride extends Equatable {
  final String id;
  final DateTime requestedAt;
  final DateTime? activatedAt;
  final Duration delayDuration;
  final Duration overrideDuration;
  final String reason;
  final bool isActive;
  final bool hasExpired;

  const EmergencyOverride({
    required this.id,
    required this.requestedAt,
    this.activatedAt,
    required this.delayDuration,
    required this.overrideDuration,
    required this.reason,
    required this.isActive,
    required this.hasExpired,
  });

  EmergencyOverride copyWith({
    String? id,
    DateTime? requestedAt,
    DateTime? activatedAt,
    Duration? delayDuration,
    Duration? overrideDuration,
    String? reason,
    bool? isActive,
    bool? hasExpired,
  }) {
    return EmergencyOverride(
      id: id ?? this.id,
      requestedAt: requestedAt ?? this.requestedAt,
      activatedAt: activatedAt ?? this.activatedAt,
      delayDuration: delayDuration ?? this.delayDuration,
      overrideDuration: overrideDuration ?? this.overrideDuration,
      reason: reason ?? this.reason,
      isActive: isActive ?? this.isActive,
      hasExpired: hasExpired ?? this.hasExpired,
    );
  }

  bool get canActivate {
    if (isActive || hasExpired) return false;
    final now = DateTime.now();
    final activationTime = requestedAt.add(delayDuration);
    return now.isAfter(activationTime);
  }

  bool get shouldExpire {
    if (!isActive || hasExpired) return false;
    if (activatedAt == null) return false;
    final now = DateTime.now();
    final expirationTime = activatedAt!.add(overrideDuration);
    return now.isAfter(expirationTime);
  }

  Duration get remainingDelayTime {
    if (isActive || hasExpired) return Duration.zero;
    final now = DateTime.now();
    final activationTime = requestedAt.add(delayDuration);
    final remaining = activationTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get remainingOverrideTime {
    if (!isActive || hasExpired || activatedAt == null) return Duration.zero;
    final now = DateTime.now();
    final expirationTime = activatedAt!.add(overrideDuration);
    final remaining = expirationTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get statusText {
    if (hasExpired) return 'Expired';
    if (isActive) return 'Active';
    if (canActivate) return 'Ready to activate';
    return 'Waiting...';
  }

  @override
  List<Object?> get props => [
    id,
    requestedAt,
    activatedAt,
    delayDuration,
    overrideDuration,
    reason,
    isActive,
    hasExpired,
  ];
}