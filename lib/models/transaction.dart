import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:akm_finance_manager/models/attachment.dart';

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
    this.deletedAt,
    this.attachments = const <Attachment>[],
  });

  static const Object _unset = Object();

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final generatedAtValue = map['generated_at'] as String?;
    final deletedAtValue = map['deleted_at'] as String?;
    final rawAttachments = map['attachments'] as List<dynamic>?;

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
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
      attachments: rawAttachments == null
          ? const <Attachment>[]
          : rawAttachments
              .map((item) => Attachment.fromMap(item as Map<String, dynamic>))
              .toList(),
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
  final DateTime? deletedAt;
  final List<Attachment> attachments;

  bool get isRecurring => recurringTransactionId != null;
  bool get hasAttachments => attachments.isNotEmpty;

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    Object? recurringTransactionId = _unset,
    Object? generatedAt = _unset,
    Object? deletedAt = _unset,
    List<Attachment>? attachments,
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
      deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
      attachments: attachments ?? this.attachments,
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
      'deleted_at': deletedAt?.toIso8601String(),
      'attachments': attachments.map((a) => a.toMap()).toList(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'recurring_transaction_id': recurringTransactionId,
      'generated_at': generatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
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
            other.generatedAt == generatedAt &&
            other.deletedAt == deletedAt &&
            listEquals(other.attachments, attachments);
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
        deletedAt,
        Object.hashAll(attachments),
      );

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, '
        'category: $category, note: $note, date: $date, '
        'recurringTransactionId: $recurringTransactionId, '
        'generatedAt: $generatedAt, deletedAt: $deletedAt, '
        'attachments: ${attachments.length})';
  }
}
