import 'dart:io';
import 'package:akm_finance_manager/models/attachment.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for picking and managing physical file attachments stored in app storage.
class AttachmentService {
  AttachmentService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Returns directory where transaction attachments are stored safely.
  Future<Directory> get _attachmentsDirectory async {
    final docsDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(path.join(docsDir.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  /// Saves raw binary bytes (e.g. from P2P sync) into app storage.
  Future<Attachment> saveBytesToStorage(
    List<int> bytes, {
    required AttachmentType fileType,
    String? originalName,
  }) async {
    final targetDir = await _attachmentsDirectory;
    final fileName = originalName ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = '${timestamp}_$fileName';
    final destinationPath = path.join(targetDir.path, safeFileName);

    final savedFile = File(destinationPath);
    await savedFile.writeAsBytes(bytes);
    final fileSize = await savedFile.length();

    return Attachment(
      filePath: savedFile.path,
      fileType: fileType,
      fileName: fileName,
      fileSize: fileSize,
      createdAt: DateTime.now(),
    );
  }

  /// Copies a raw file into app document storage under unique name.
  Future<Attachment> _saveFileToStorage(
    File sourceFile, {
    required AttachmentType fileType,
    String? originalName,
  }) async {
    final targetDir = await _attachmentsDirectory;
    final fileName = originalName ?? path.basename(sourceFile.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = '${timestamp}_$fileName';
    final destinationPath = path.join(targetDir.path, safeFileName);

    final savedFile = await sourceFile.copy(destinationPath);
    final fileSize = await savedFile.length();

    return Attachment(
      filePath: savedFile.path,
      fileType: fileType,
      fileName: fileName,
      fileSize: fileSize,
      createdAt: DateTime.now(),
    );
  }

  /// Pick one or multiple images from the device gallery.
  Future<List<Attachment>> pickImagesFromGallery() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles.isEmpty) return <Attachment>[];

    final attachments = <Attachment>[];
    for (final xFile in pickedFiles) {
      final attachment = await _saveFileToStorage(
        File(xFile.path),
        fileType: AttachmentType.image,
        originalName: xFile.name,
      );
      attachments.add(attachment);
    }
    return attachments;
  }

  /// Capture a new photo using the device camera.
  Future<Attachment?> pickImageFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile == null) return null;

    return _saveFileToStorage(
      File(pickedFile.path),
      fileType: AttachmentType.image,
      originalName: pickedFile.name,
    );
  }

  /// Generic file picker designed for future extension (PDFs, Documents, etc.).
  Future<List<Attachment>> pickFiles({
    List<String>? allowedExtensions,
    FileType fileType = FileType.any,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: fileType,
      allowedExtensions: allowedExtensions,
    );

    if (result == null || result.files.isEmpty) return <Attachment>[];

    final attachments = <Attachment>[];
    for (final platformFile in result.files) {
      final filePath = platformFile.path;
      if (filePath == null) continue;

      final extension = path.extension(filePath).toLowerCase();
      final type = (extension == '.pdf')
          ? AttachmentType.pdf
          : (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic']
                  .contains(extension))
              ? AttachmentType.image
              : AttachmentType.other;

      final attachment = await _saveFileToStorage(
        File(filePath),
        fileType: type,
        originalName: platformFile.name,
      );
      attachments.add(attachment);
    }
    return attachments;
  }

  /// Deletes the physical file from the local app storage.
  Future<void> deletePhysicalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore physical deletion errors if file is missing or inaccessible
    }
  }
}
