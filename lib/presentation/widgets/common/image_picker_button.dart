import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';

/// A reusable button widget for picking and uploading entity images.
///
/// Shows a bottom sheet with Camera and Gallery options when tapped.
/// After image selection, compresses and enqueues the image for upload
/// via [ImageUploadNotifier], then calls [onImageSelected] with the
/// `local://{uuid}` key for immediate UI display.
///
/// Supports an optional [child] for custom UI. When no child is provided,
/// renders a default circular button with a camera icon.
///
/// Example:
/// ```dart
/// ImagePickerButton(
///   entityType: 'aquarium',
///   entityId: aquarium.id,
///   onImageSelected: (localKey) {
///     // Update entity's photoKey with the local key
///   },
///   child: EntityImage(...),
/// )
/// ```
class ImagePickerButton extends ConsumerStatefulWidget {
  /// Creates an [ImagePickerButton].
  ///
  /// [entityType] must be one of: `"aquarium"`, `"fish"`, or `"avatar"`.
  /// [entityId] is the entity's unique identifier.
  /// [onImageSelected] is called with the `local://{uuid}` key after
  /// the image is successfully queued for upload.
  const ImagePickerButton({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.onImageSelected,
    this.child,
    @visibleForTesting this.imagePicker,
    @visibleForTesting this.readImageBytes,
  });

  /// Entity type: `"aquarium"`, `"fish"`, or `"avatar"`.
  final String entityType;

  /// The entity's unique identifier.
  final String entityId;

  /// Called with the `local://{uuid}` key after the image is queued for upload.
  final ValueChanged<String> onImageSelected;

  /// Optional custom child widget. When tapped, shows the image picker.
  /// If null, a default camera icon button is rendered.
  final Widget? child;

  /// Optional [ImagePicker] instance for dependency injection in tests.
  @visibleForTesting
  final ImagePicker? imagePicker;

  /// Optional callback to read image bytes from a file path.
  /// Defaults to [File.readAsBytes]. Exposed for testing to avoid
  /// real I/O in the FakeAsync zone of widget tests.
  @visibleForTesting
  final Future<Uint8List> Function(String path)? readImageBytes;

  @override
  ConsumerState<ImagePickerButton> createState() => ImagePickerButtonState();
}

/// State for [ImagePickerButton].
///
/// Exposed as public for testing purposes (verify [isProcessing] state).
@visibleForTesting
class ImagePickerButtonState extends ConsumerState<ImagePickerButton> {
  late final ImagePicker _picker = widget.imagePicker ?? ImagePicker();

  /// Whether the widget is currently processing an image pick + upload.
  @visibleForTesting
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return GestureDetector(
        onTap: isProcessing ? null : _showPickerModal,
        child: widget.child,
      );
    }

    return _DefaultPickerButton(
      isProcessing: isProcessing,
      onTap: _showPickerModal,
    );
  }

  /// Shows the bottom sheet with Camera and Gallery options.
  void _showPickerModal() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.choosePhoto, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Picks an image from the given [source], compresses, enqueues for upload,
  /// and notifies via [onImageSelected].
  Future<void> _pickImage(ImageSource source) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile == null) {
        // User cancelled the picker
        return;
      }

      final imageBytes = widget.readImageBytes != null
          ? await widget.readImageBytes!(pickedFile.path)
          : await File(pickedFile.path).readAsBytes();

      final localKey = await ref
          .read(imageUploadNotifierProvider.notifier)
          .queueUpload(
            entityType: widget.entityType,
            entityId: widget.entityId,
            imageBytes: imageBytes,
          );

      if (mounted) {
        widget.onImageSelected(localKey);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(e);
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void _showErrorSnackbar(Object error) {
    final l10n = AppLocalizations.of(context)!;
    final message = _getErrorMessage(error, l10n);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Maps error types to localized user-facing messages.
  static String _getErrorMessage(Object error, AppLocalizations l10n) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return l10n.permissionDenied;
    }
    return l10n.failedToPickImage;
  }
}

/// Default button rendered when no [child] is provided.
class _DefaultPickerButton extends StatelessWidget {
  const _DefaultPickerButton({required this.isProcessing, required this.onTap});

  final bool isProcessing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: isProcessing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              )
            : Icon(
                Icons.add_a_photo,
                size: 24,
                color: theme.colorScheme.onPrimaryContainer,
              ),
      ),
    );
  }
}
