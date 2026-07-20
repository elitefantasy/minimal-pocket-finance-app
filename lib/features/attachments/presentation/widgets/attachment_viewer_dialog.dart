import 'dart:io';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/models/attachment.dart';
import 'package:flutter/material.dart';

/// Full-screen interactive dialog to view attachments (images, PDFs, files).
class AttachmentViewerDialog extends StatefulWidget {
  const AttachmentViewerDialog({
    required this.attachments,
    this.initialIndex = 0,
    super.key,
  });

  final List<Attachment> attachments;
  final int initialIndex;

  @override
  State<AttachmentViewerDialog> createState() => _AttachmentViewerDialogState();
}

class _AttachmentViewerDialogState extends State<AttachmentViewerDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.attachments.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentAttachment = widget.attachments[_currentIndex];

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      currentAttachment.fileName ?? 'Attachment',
                      style: context.text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.attachments.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.attachments.length}',
                        style: context.text.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Interactive PageView content area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.attachments.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = widget.attachments[index];
                  final file = File(item.filePath);

                  if (item.isImage) {
                    return InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(
                        child: file.existsSync()
                            ? Image.file(
                                file,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildErrorView(context, item),
                              )
                            : _buildErrorView(context, item),
                      ),
                    );
                  } else if (item.isPdf) {
                    return _buildDocumentCard(
                      context,
                      icon: Icons.picture_as_pdf,
                      iconColor: Colors.redAccent,
                      title: item.fileName ?? 'PDF Document',
                      subtitle: 'PDF File Attachment',
                    );
                  } else {
                    return _buildDocumentCard(
                      context,
                      icon: Icons.insert_drive_file_outlined,
                      iconColor: Colors.blueAccent,
                      title: item.fileName ?? 'File Attachment',
                      subtitle: 'Document Attachment',
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, Attachment item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Image not available',
          style: context.text.bodyMedium?.copyWith(color: Colors.white70),
        ),
        if (item.fileName != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.fileName!,
            style: context.text.bodySmall?.copyWith(color: Colors.white38),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: context.text.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: context.text.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
