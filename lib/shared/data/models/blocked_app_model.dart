import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/blocked_app.dart';

part 'blocked_app_model.g.dart';

@JsonSerializable()
class BlockedAppModel {
  final String id;
  final String name;
  final String packageName;
  final String iconPath;
  final bool isBlocked;
  final DateTime? lastModified;
  final List<String> categories;
  final int dailyTimeLimit;
  final bool allowNotifications;

  const BlockedAppModel({
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

  factory BlockedAppModel.fromJson(Map<String, dynamic> json) =>
      _$BlockedAppModelFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedAppModelToJson(this);

  factory BlockedAppModel.fromInstalledApp(Map<String, dynamic> app) {
    return BlockedAppModel(
      id: app['packageName'] as String,
      name: app['appName'] as String,
      packageName: app['packageName'] as String,
      iconPath: '', // Will be populated later
      isBlocked: false,
      lastModified: DateTime.now(),
      categories: [],
      dailyTimeLimit: 0,
      allowNotifications: false,
    );
  }

  BlockedApp toDomain() {
    return BlockedApp(
      id: id,
      name: name,
      packageName: packageName,
      iconPath: iconPath,
      isBlocked: isBlocked,
      lastModified: lastModified,
      categories: categories,
      dailyTimeLimit: dailyTimeLimit,
      allowNotifications: allowNotifications,
    );
  }

  static BlockedAppModel fromDomain(BlockedApp blockedApp) {
    return BlockedAppModel(
      id: blockedApp.id,
      name: blockedApp.name,
      packageName: blockedApp.packageName,
      iconPath: blockedApp.iconPath,
      isBlocked: blockedApp.isBlocked,
      lastModified: blockedApp.lastModified,
      categories: blockedApp.categories,
      dailyTimeLimit: blockedApp.dailyTimeLimit,
      allowNotifications: blockedApp.allowNotifications,
    );
  }

  BlockedAppModel copyWith({
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
    return BlockedAppModel(
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

  // Database mapping methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'package_name': packageName,
      'icon_path': iconPath,
      'is_blocked': isBlocked ? 1 : 0,
      'last_modified': lastModified?.millisecondsSinceEpoch,
      'categories': categories.join(','),
      'daily_time_limit': dailyTimeLimit,
      'allow_notifications': allowNotifications ? 1 : 0,
    };
  }

  factory BlockedAppModel.fromMap(Map<String, dynamic> map) {
    return BlockedAppModel(
      id: map['id'] as String,
      name: map['name'] as String,
      packageName: map['package_name'] as String,
      iconPath: map['icon_path'] as String? ?? '',
      isBlocked: (map['is_blocked'] as int) == 1,
      lastModified: map['last_modified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_modified'] as int)
          : null,
      categories: map['categories'] != null 
          ? (map['categories'] as String).split(',').where((c) => c.isNotEmpty).toList()
          : [],
      dailyTimeLimit: map['daily_time_limit'] as int? ?? 0,
      allowNotifications: (map['allow_notifications'] as int?) == 1,
    );
  }
}