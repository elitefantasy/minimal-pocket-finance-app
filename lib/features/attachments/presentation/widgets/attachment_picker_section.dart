import 'dart:io';
import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/attachments/presentation/widgets/attachment_viewer_dialog.dart';
import 'package:akm_finance_manager/models/attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive UI section for picking, managing, and viewing transaction attachments.
class AttachmentPickerSection extends ConsumerWidget {
  const AttachmentPickerSection({
    required this.attachments,
    required this.onAttachmentsChanged,
    this.isEnabled = true,
    super.key,
  });

  final List<Attachment> attachments;
  final ValueChanged<List<Attachment>> onAttachmentsChanged;
  final bool isEnabled;

  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    try {
      final newAttachments = await ref
          .read(attachmentServiceProvider)
          .pickImagesFromGallery();
      if (newAttachments.isNotEmpty) {
        onAttachmentsChanged(<Attachment>[...attachments, ...newAttachments]);
      }
    } catch (e) {
      if (context.mounted) {
        ref
            .read(appSnackbarProvider)
            .showError('Could not select images: $e');
      }
    }
  }

  Future<void> _pickFromCamera(BuildContext context, WidgetRef ref) async {
    try {
      final newAttachment = await ref
          .read(attachmentServiceProvider)
          .pickImageFromCamera();
      if (newAttachment != null) {
        onAttachmentsChanged(<Attachment>[...attachments, newAttachment]);
      }
    } catch (e) {
      if (context.mounted) {
        ref
            .read(appSnackbarProvider)
            .showError('Could not capture photo: $e');
      }
    }
  }

  Future<void> _pickDocument(BuildContext context, WidgetRef ref) async {
    try {
      final newAttachments = await ref
          .read(attachmentServiceProvider)
          .pickFiles();
      if (newAttachments.isNotEmpty) {
        onAttachmentsChanged(<Attachment>[...attachments, ...newAttachments]);
      }
    } catch (e) {
      if (context.mounted) {
        ref
            .read(appSnackbarProvider)
            .showError('Could not select files: $e');
      }
    }
  }

  void _removeAttachment(Attachment attachment) {
    final updated = attachments.where((a) => a != attachment).toList();
    onAttachmentsChanged(updated);
  }

  void _openViewer(BuildContext context, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (context) => AttachmentViewerDialog(
        attachments: attachments,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Title and Add Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(AppIcons.receipt, size: AppIcons.mediumSize),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Attachments (${attachments.length})',
                  style: context.text.titleSmall,
                ),
              ],
            ),
            if (isEnabled)
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => _pickFromGallery(context, ref),
                    icon: const Icon(Icons.photo_library_outlined),
                    tooltip: 'Add Images from Gallery',
                  ),
                  IconButton(
                    onPressed: () => _pickFromCamera(context, ref),
                    icon: const Icon(Icons.camera_alt_outlined),
                    tooltip: 'Take Photo',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'More Attachment Options',
                    onSelected: (value) {
                      if (value == 'document') {
                        _pickDocument(context, ref);
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'document',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.attach_file, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('Add File / Document'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        // Thumbnails preview area
        if (attachments.isEmpty)
          GestureDetector(
            onTap: isEnabled ? () => _pickFromGallery(context, ref) : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colors.outlineVariant.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap to attach receipt or images',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final attachment = attachments[index];
                return _buildThumbnailCard(context, attachment, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailCard(
    BuildContext context,
    Attachment attachment,
    int index,
  ) {
    final file = File(attachment.filePath);

    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: () => _openViewer(context, index),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: context.colors.surfaceContainerHighest,
              border: Border.all(color: context.colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: attachment.isImage
                ? (file.existsSync()
                    ? Image.file(file, fit: BoxFit.cover)
                    : const Icon(Icons.broken_image))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        attachment.isPdf
                            ? Icons.picture_as_pdf
                            : Icons.insert_drive_file,
                        size: 36,
                        color: attachment.isPdf
                            ? Colors.redAccent
                            : context.colors.primary,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          attachment.fileName ?? 'File',
                          style: context.text.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (isEnabled)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeAttachment(attachment),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
