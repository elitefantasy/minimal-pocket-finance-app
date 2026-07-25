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
    this.deviceId,
    this.updatedAt,
    this.attachments = const <Attachment>[],
  });

  static const Object _unset = Object();

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final generatedAtValue = map['generated_at'] as String?;
    final deletedAtValue = map['deleted_at'] as String?;
    final updatedAtValue = map['updated_at'] as String?;
    final rawAttachments = map['attachments'] as List<dynamic>?;

    return Transaction(
      id: map['id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String,
      date: DateTime.parse(map['date'] as String),
      recurringTransactionId: map['recurring_transaction_id'] as String?,
      generatedAt: generatedAtValue == null
          ? null
          : DateTime.parse(generatedAtValue),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
      deviceId: map['device_id'] as String?,
      updatedAt: updatedAtValue == null ? null : DateTime.parse(updatedAtValue),
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

  final String? id;
  final String type;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String? recurringTransactionId;
  final DateTime? generatedAt;
  final DateTime? deletedAt;
  final String? deviceId;
  final DateTime? updatedAt;
  final List<Attachment> attachments;

  bool get isRecurring => recurringTransactionId != null;
  bool get hasAttachments => attachments.isNotEmpty;

  Transaction copyWith({
    Object? id = _unset,
    String? type,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    Object? recurringTransactionId = _unset,
    Object? generatedAt = _unset,
    Object? deletedAt = _unset,
    Object? deviceId = _unset,
    Object? updatedAt = _unset,
    List<Attachment>? attachments,
  }) {
    return Transaction(
      id: id == _unset ? this.id : id as String?,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      recurringTransactionId: recurringTransactionId == _unset
          ? this.recurringTransactionId
          : recurringTransactionId as String?,
      generatedAt: generatedAt == _unset
          ? this.generatedAt
          : generatedAt as DateTime?,
      deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
      deviceId: deviceId == _unset ? this.deviceId : deviceId as String?,
      updatedAt: updatedAt == _unset ? this.updatedAt : updatedAt as DateTime?,
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
      'device_id': deviceId,
      'updated_at': updatedAt?.toIso8601String(),
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
      'device_id': deviceId,
      'updated_at': updatedAt?.toIso8601String(),
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
            other.deviceId == deviceId &&
            other.updatedAt == updatedAt &&
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
        deviceId,
        updatedAt,
        Object.hashAll(attachments),
      );

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, '
        'category: $category, note: $note, date: $date, '
        'recurringTransactionId: $recurringTransactionId, '
        'generatedAt: $generatedAt, deletedAt: $deletedAt, '
        'deviceId: $deviceId, updatedAt: $updatedAt, '
        'attachments: ${attachments.length})';
  }
}
