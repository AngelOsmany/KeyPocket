import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String userId;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
  });

  // Mapa para Firestore (usa Timestamp para createdAt)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Mapa para almacenamiento local (Hive) usando tipos primitivos
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Category.fromMap(Map<dynamic, dynamic> map) {
    DateTime created;
    final raw = map['createdAt'];
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      created = DateTime.fromMillisecondsSinceEpoch(int.tryParse(raw) ?? 0);
    } else if (raw is DateTime) {
      created = raw;
    } else {
      created = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Category(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      createdAt: created,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}