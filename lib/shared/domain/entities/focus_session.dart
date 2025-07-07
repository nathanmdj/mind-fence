import 'package:equatable/equatable.dart';

enum FocusSessionStatus { active, paused, completed, cancelled }

class FocusSession extends Equatable {
  final String id;
  final String name;
  final int duration; // in minutes
  final DateTime startTime;
  final DateTime? endTime;
  final FocusSessionStatus status;
  final List<String> blockedApps;
  final String? description;
  final int breakDuration; // in minutes
  final bool allowEmergencyOverride;
  final Map<String, dynamic> metadata;
  
  const FocusSession({
    required this.id,
    required this.name,
    required this.duration,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.blockedApps,
    this.description,
    this.breakDuration = 5,
    this.allowEmergencyOverride = true,
    this.metadata = const {},
  });
  
  FocusSession copyWith({
    String? id,
    String? name,
    int? duration,
    DateTime? startTime,
    DateTime? endTime,
    FocusSessionStatus? status,
    List<String>? blockedApps,
    String? description,
    int? breakDuration,
    bool? allowEmergencyOverride,
    Map<String, dynamic>? metadata,
  }) {
    return FocusSession(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      blockedApps: blockedApps ?? this.blockedApps,
      description: description ?? this.description,
      breakDuration: breakDuration ?? this.breakDuration,
      allowEmergencyOverride: allowEmergencyOverride ?? this.allowEmergencyOverride,
      metadata: metadata ?? this.metadata,
    );
  }
  
  Duration get remainingTime {
    if (status == FocusSessionStatus.completed || status == FocusSessionStatus.cancelled) {
      return Duration.zero;
    }
    
    final targetEndTime = startTime.add(Duration(minutes: duration));
    final now = DateTime.now();
    
    if (now.isAfter(targetEndTime)) {
      return Duration.zero;
    }
    
    return targetEndTime.difference(now);
  }
  
  double get progressPercentage {
    final totalDuration = Duration(minutes: duration);
    final elapsed = DateTime.now().difference(startTime);
    
    if (elapsed >= totalDuration) {
      return 1.0;
    }
    
    return elapsed.inMilliseconds / totalDuration.inMilliseconds;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    duration,
    startTime,
    endTime,
    status,
    blockedApps,
    description,
    breakDuration,
    allowEmergencyOverride,
    metadata,
  ];
}