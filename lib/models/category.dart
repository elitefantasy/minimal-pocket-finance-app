import 'dart:convert';

/// An immutable transaction category.
class Category {
  const Category({
    this.id,
    required this.name,
    this.deviceId,
    this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    final updatedAtValue = map['updated_at'] as String?;
    return Category(
      id: map['id'] as String?,
      name: map['name'] as String,
      deviceId: map['device_id'] as String?,
      updatedAt: updatedAtValue == null ? null : DateTime.parse(updatedAtValue),
    );
  }

  factory Category.fromJson(String source) {
    return Category.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  final String? id;
  final String name;
  final String? deviceId;
  final DateTime? updatedAt;

  Category copyWith({
    String? id,
    String? name,
    String? deviceId,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'device_id': deviceId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Category &&
            other.id == id &&
            other.name == name &&
            other.deviceId == deviceId &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, name, deviceId, updatedAt);

  @override
  String toString() =>
      'Category(id: $id, name: $name, deviceId: $deviceId, updatedAt: $updatedAt)';
}
