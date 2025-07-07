import 'package:equatable/equatable.dart';

class BlockedWebsite extends Equatable {
  final String id;
  final String domain;
  final String name;
  final bool isBlocked;
  final DateTime? lastModified;
  final List<String> categories;
  
  const BlockedWebsite({
    required this.id,
    required this.domain,
    required this.name,
    required this.isBlocked,
    this.lastModified,
    this.categories = const [],
  });
  
  BlockedWebsite copyWith({
    String? id,
    String? domain,
    String? name,
    bool? isBlocked,
    DateTime? lastModified,
    List<String>? categories,
  }) {
    return BlockedWebsite(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      name: name ?? this.name,
      isBlocked: isBlocked ?? this.isBlocked,
      lastModified: lastModified ?? this.lastModified,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [
    id,
    domain,
    name,
    isBlocked,
    lastModified,
    categories,
  ];
}