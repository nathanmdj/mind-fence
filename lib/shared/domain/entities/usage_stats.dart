import 'package:equatable/equatable.dart';

class UsageStats extends Equatable {
  final String id;
  final String appPackageName;
  final String appName;
  final DateTime date;
  final int totalTimeInMillis;
  final int launchCount;
  final DateTime firstTimeStamp;
  final DateTime lastTimeStamp;
  final Map<String, dynamic> additionalData;
  
  const UsageStats({
    required this.id,
    required this.appPackageName,
    required this.appName,
    required this.date,
    required this.totalTimeInMillis,
    required this.launchCount,
    required this.firstTimeStamp,
    required this.lastTimeStamp,
    this.additionalData = const {},
  });
  
  UsageStats copyWith({
    String? id,
    String? appPackageName,
    String? appName,
    DateTime? date,
    int? totalTimeInMillis,
    int? launchCount,
    DateTime? firstTimeStamp,
    DateTime? lastTimeStamp,
    Map<String, dynamic>? additionalData,
  }) {
    return UsageStats(
      id: id ?? this.id,
      appPackageName: appPackageName ?? this.appPackageName,
      appName: appName ?? this.appName,
      date: date ?? this.date,
      totalTimeInMillis: totalTimeInMillis ?? this.totalTimeInMillis,
      launchCount: launchCount ?? this.launchCount,
      firstTimeStamp: firstTimeStamp ?? this.firstTimeStamp,
      lastTimeStamp: lastTimeStamp ?? this.lastTimeStamp,
      additionalData: additionalData ?? this.additionalData,
    );
  }
  
  Duration get totalTime => Duration(milliseconds: totalTimeInMillis);
  
  String get formattedTotalTime {
    final hours = totalTime.inHours;
    final minutes = totalTime.inMinutes % 60;
    final seconds = totalTime.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  double get averageSessionDuration {
    if (launchCount == 0) return 0.0;
    return totalTimeInMillis / launchCount;
  }

  @override
  List<Object?> get props => [
    id,
    appPackageName,
    appName,
    date,
    totalTimeInMillis,
    launchCount,
    firstTimeStamp,
    lastTimeStamp,
    additionalData,
  ];
}