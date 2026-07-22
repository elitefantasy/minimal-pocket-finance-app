import 'dart:convert';

/// Supported types of file attachments.
enum AttachmentType {
  image('image'),
  pdf('pdf'),
  other('other');

  const AttachmentType(this.value);

  final String value;

  static AttachmentType fromString(String rawValue) {
    final lower = rawValue.toLowerCase().trim();
    if (lower == 'image' || lower.startsWith('image/')) {
      return AttachmentType.image;
    }
    if (lower == 'pdf' || lower.endsWith('.pdf') || lower == 'application/pdf') {
      return AttachmentType.pdf;
    }
    return AttachmentType.other;
  }

  @override
  String toString() => value;
}

/// An immutable file attachment associated with a transaction.
class Attachment {
  const Attachment({
    this.id,
    this.transactionId,
    required this.filePath,
    required this.fileType,
    this.fileName,
    this.fileSize,
    required this.createdAt,
  });

  static const Object _unset = Object();

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int?,
      filePath: map['file_path'] as String,
      fileType: AttachmentType.fromString(map['file_type'] as String? ?? 'other'),
      fileName: map['file_name'] as String?,
      fileSize: map['file_size'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Attachment.fromJson(String source) {
    return Attachment.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  final int? id;
  final int? transactionId;
  final String filePath;
  final AttachmentType fileType;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;

  bool get isImage => fileType == AttachmentType.image;
  bool get isPdf => fileType == AttachmentType.pdf;

  Attachment copyWith({
    Object? id = _unset,
    Object? transactionId = _unset,
    String? filePath,
    AttachmentType? fileType,
    Object? fileName = _unset,
    Object? fileSize = _unset,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id == _unset ? this.id : id as int?,
      transactionId: transactionId == _unset
          ? this.transactionId
          : transactionId as int?,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileName: fileName == _unset ? this.fileName : fileName as String?,
      fileSize: fileSize == _unset ? this.fileSize : fileSize as int?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      'file_path': filePath,
      'file_type': fileType.value,
      'file_name': fileName,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Attachment &&
            other.id == id &&
            other.transactionId == transactionId &&
            other.filePath == filePath &&
            other.fileType == fileType &&
            other.fileName == fileName &&
            other.fileSize == fileSize &&
            other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        transactionId,
        filePath,
        fileType,
        fileName,
        fileSize,
        createdAt,
      );

  @override
  String toString() {
    return 'Attachment(id: $id, transactionId: $transactionId, filePath: $filePath, '
        'fileType: $fileType, fileName: $fileName, fileSize: $fileSize, createdAt: $createdAt)';
  }
}
