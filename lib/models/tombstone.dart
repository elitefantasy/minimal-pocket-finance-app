import 'package:flutter/foundation.dart';

@immutable
class Tombstone {
  const Tombstone({
    required this.id,
    required this.tableName,
    required this.deletedAt,
  });

  final String id;
  final String tableName;
  final DateTime deletedAt;

  Tombstone copyWith({
    String? id,
    String? tableName,
    DateTime? deletedAt,
  }) {
    return Tombstone(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'table_name': tableName,
      'deleted_at': deletedAt.toUtc().toIso8601String(),
    };
  }

  factory Tombstone.fromMap(Map<String, dynamic> map) {
    return Tombstone(
      id: map['id'] as String,
      tableName: map['table_name'] as String,
      deletedAt: DateTime.parse(map['deleted_at'] as String).toLocal(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tombstone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tableName == other.tableName &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(id, tableName, deletedAt);
}
