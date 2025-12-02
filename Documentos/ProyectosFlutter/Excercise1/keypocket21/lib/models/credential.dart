import 'package:cloud_firestore/cloud_firestore.dart';

class Credential {
  final String id;
  final String title;
  final String username;
  final String email;
  final String password;
  final String? website;
  final String? notes;
  final String categoryId;
  final String userId;
  final DateTime createdAt;

  Credential({
    required this.id,
    required this.title,
    required this.username,
    required this.email,
    required this.password,
    this.website,
    this.notes,
    required this.categoryId,
    required this.userId,
    required this.createdAt,
  });

  // Mapa para Firestore (usa Timestamp)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'email': email,
      'password': password,
      'website': website,
      'notes': notes,
      'categoryId': categoryId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Mapa para almacenamiento local (Hive) usando tipos primitivos
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'email': email,
      'password': password,
      'website': website,
      'notes': notes,
      'categoryId': categoryId,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Credential.fromMap(Map<dynamic, dynamic> map) {
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

    return Credential(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      website: map['website']?.toString(),
      notes: map['notes']?.toString(),
      categoryId: map['categoryId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      createdAt: created,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Credential && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}