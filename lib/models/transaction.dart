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
    this.recurringTransactionId,
    this.generatedAt,
  });

  static const Object _unset = Object();

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final generatedAtValue = map['generated_at'] as String?;

    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String,
      date: DateTime.parse(map['date'] as String),
      recurringTransactionId: map['recurring_transaction_id'] as int?,
      generatedAt: generatedAtValue == null
          ? null
          : DateTime.parse(generatedAtValue),
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
  final int? recurringTransactionId;
  final DateTime? generatedAt;

  bool get isRecurring => recurringTransactionId != null;

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    Object? recurringTransactionId = _unset,
    Object? generatedAt = _unset,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      recurringTransactionId: recurringTransactionId == _unset
          ? this.recurringTransactionId
          : recurringTransactionId as int?,
      generatedAt: generatedAt == _unset
          ? this.generatedAt
          : generatedAt as DateTime?,
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
      'recurring_transaction_id': recurringTransactionId,
      'generated_at': generatedAt?.toIso8601String(),
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
            other.date == date &&
            other.recurringTransactionId == recurringTransactionId &&
            other.generatedAt == generatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    category,
    note,
    date,
    recurringTransactionId,
    generatedAt,
  );

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, '
        'category: $category, note: $note, date: $date, '
        'recurringTransactionId: $recurringTransactionId, '
        'generatedAt: $generatedAt)';
  }
}
