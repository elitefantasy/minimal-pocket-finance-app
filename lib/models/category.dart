import 'dart:convert';

/// An immutable transaction category.
class Category {
  const Category({this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'] as int?, name: map['name'] as String);
  }

  factory Category.fromJson(String source) {
    return Category.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  final int? id;
  final String name;

  Category copyWith({int? id, String? name}) {
    return Category(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'name': name};
  }

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Category && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
