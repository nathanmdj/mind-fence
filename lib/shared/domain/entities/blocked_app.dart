import 'package:equatable/equatable.dart';

class BlockedApp extends Equatable {
  final String id;
  final String name;
  final String packageName;
  final String iconPath;
  final bool isBlocked;
  final DateTime? lastModified;
  final List<String> categories;
  final int dailyTimeLimit; // in minutes
  final bool allowNotifications;
  
  const BlockedApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.iconPath,
    required this.isBlocked,
    this.lastModified,
    this.categories = const [],
    this.dailyTimeLimit = 0,
    this.allowNotifications = false,
  });
  
  BlockedApp copyWith({
    String? id,
    String? name,
    String? packageName,
    String? iconPath,
    bool? isBlocked,
    DateTime? lastModified,
    List<String>? categories,
    int? dailyTimeLimit,
    bool? allowNotifications,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      iconPath: iconPath ?? this.iconPath,
      isBlocked: isBlocked ?? this.isBlocked,
      lastModified: lastModified ?? this.lastModified,
      categories: categories ?? this.categories,
      dailyTimeLimit: dailyTimeLimit ?? this.dailyTimeLimit,
      allowNotifications: allowNotifications ?? this.allowNotifications,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    packageName,
    iconPath,
    isBlocked,
    lastModified,
    categories,
    dailyTimeLimit,
    allowNotifications,
  ];
}