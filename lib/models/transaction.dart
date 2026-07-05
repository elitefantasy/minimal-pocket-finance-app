import 'dart:convert';

/// An immutable financial transaction.
class Transaction {
  const Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  factory Transaction.fromJson(String source) {
    return Transaction.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  final int? id;
  final String type;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Transaction &&
            other.id == id &&
            other.type == type &&
            other.amount == amount &&
            other.category == category &&
            other.note == note &&
            other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, type, amount, category, note, date);

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, '
        'category: $category, note: $note, date: $date)';
  }
}
