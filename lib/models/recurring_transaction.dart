import 'dart:convert';

/// An immutable monthly recurring transaction definition.
class RecurringTransaction {
  const RecurringTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.dayOfMonth,
    required this.isEnabled,
    required this.lastProcessedDate,
    required this.createdAt,
    required this.startDate,
    required this.updatedAt,
    this.deviceId,
  });

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    final lastProcessedDate = map['last_processed_date'] as String?;
    return RecurringTransaction(
      id: map['id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String,
      dayOfMonth: map['day_of_month'] as int,
      isEnabled: (map['is_enabled'] as int) == 1,
      lastProcessedDate: lastProcessedDate == null
          ? null
          : DateTime.tryParse(lastProcessedDate),
      createdAt: DateTime.parse(map['created_at'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deviceId: map['device_id'] as String?,
    );
  }

  factory RecurringTransaction.fromJson(String source) {
    return RecurringTransaction.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  final String? id;
  final String type;
  final double amount;
  final String category;
  final String note;
  final int dayOfMonth;
  final bool isEnabled;
  final DateTime? lastProcessedDate;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime updatedAt;
  final String? deviceId;

  RecurringTransaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    String? note,
    int? dayOfMonth,
    bool? isEnabled,
    DateTime? lastProcessedDate,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? updatedAt,
    String? deviceId,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isEnabled: isEnabled ?? this.isEnabled,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'day_of_month': dayOfMonth,
      'is_enabled': isEnabled ? 1 : 0,
      'last_processed_date': lastProcessedDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'device_id': deviceId,
    };
  }

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecurringTransaction &&
            other.id == id &&
            other.type == type &&
            other.amount == amount &&
            other.category == category &&
            other.note == note &&
            other.dayOfMonth == dayOfMonth &&
            other.isEnabled == isEnabled &&
            other.lastProcessedDate == lastProcessedDate &&
            other.createdAt == createdAt &&
            other.startDate == startDate &&
            other.updatedAt == updatedAt &&
            other.deviceId == deviceId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    category,
    note,
    dayOfMonth,
    isEnabled,
    lastProcessedDate,
    createdAt,
    startDate,
    updatedAt,
    deviceId,
  );

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, type: $type, amount: $amount, '
        'category: $category, note: $note, dayOfMonth: $dayOfMonth, '
        'isEnabled: $isEnabled, lastProcessedDate: $lastProcessedDate, '
        'createdAt: $createdAt, startDate: $startDate, '
        'updatedAt: $updatedAt, deviceId: $deviceId)';
  }
}
