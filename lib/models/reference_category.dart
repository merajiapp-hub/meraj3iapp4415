import 'package:cloud_firestore/cloud_firestore.dart';

class ReferenceCategory {
  final String id;
  final String name;
  final String? parentId;
  final String? description;
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  const ReferenceCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.description,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory ReferenceCategory.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? createdAt;
    final rawDate = map['createdAt'] ?? map['created_at'];
    if (rawDate is Timestamp) {
      createdAt = rawDate.toDate();
    } else if (rawDate is DateTime) {
      createdAt = rawDate;
    }

    return ReferenceCategory(
      id: documentId,
      name: map['name'] ?? '',
      parentId: map['parentId'],
      description: map['description'],
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? map['is_active'] ?? true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (parentId != null) 'parentId': parentId,
      if (description != null) 'description': description,
      'order': order,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  ReferenceCategory copyWith({
    String? name,
    String? parentId,
    int? order,
    bool? isActive,
  }) {
    return ReferenceCategory(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
