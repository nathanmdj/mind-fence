import 'package:equatable/equatable.dart';

class Schedule extends Equatable {
  final String id;
  final String name;
  final String startTime; // Format: "HH:MM"
  final String endTime; // Format: "HH:MM"
  final List<int> daysOfWeek; // 1-7 (Monday to Sunday)
  final bool isActive;
  final List<String> blockedApps;
  final List<String> blockedWebsites;
  final DateTime createdAt;

  const Schedule({
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

  Schedule copyWith({
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
    return Schedule(
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

  bool isActiveNow() {
    final now = DateTime.now();
    final currentDay = now.weekday; // 1-7 (Monday to Sunday)
    final currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Check if current day is in scheduled days
    if (!daysOfWeek.contains(currentDay)) {
      return false;
    }

    // Check if current time is within scheduled time range
    return _isTimeInRange(currentTime, startTime, endTime);
  }

  bool _isTimeInRange(String currentTime, String startTime, String endTime) {
    final current = _timeToMinutes(currentTime);
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);

    if (start <= end) {
      // Same day range (e.g., 09:00 to 17:00)
      return current >= start && current <= end;
    } else {
      // Overnight range (e.g., 23:00 to 06:00)
      return current >= start || current <= end;
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  String get daysOfWeekDisplay {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = daysOfWeek.map((day) => dayNames[day - 1]).toList();
    
    if (selectedDays.length == 7) {
      return 'Every day';
    } else if (selectedDays.length == 5 && 
               daysOfWeek.every((day) => day >= 1 && day <= 5)) {
      return 'Weekdays';
    } else if (selectedDays.length == 2 && 
               daysOfWeek.contains(6) && daysOfWeek.contains(7)) {
      return 'Weekends';
    } else {
      return selectedDays.join(', ');
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    startTime,
    endTime,
    daysOfWeek,
    isActive,
    blockedApps,
    blockedWebsites,
    createdAt,
  ];
}