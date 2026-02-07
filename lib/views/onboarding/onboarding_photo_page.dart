import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class OnboardingPhotoPage extends StatefulWidget {
  final File? selectedImage;
  final ValueChanged<File?> onImageSelected;

  const OnboardingPhotoPage({
    super.key,
    required this.selectedImage,
    required this.onImageSelected,
  });

  @override
  State<OnboardingPhotoPage> createState() => _OnboardingPhotoPageState();
}

class _OnboardingPhotoPageState extends State<OnboardingPhotoPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (image != null) {
        widget.onImageSelected(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      // Show snackbar if mounted
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            l10n.profilePhotoTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.indigoInk,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profilePhotoDesc,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),

          // Photo Circle
          Center(
            child: Stack(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                    image: widget.selectedImage != null
                        ? DecorationImage(
                            image: FileImage(widget.selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.selectedImage == null
                      ? const Icon(Icons.person, size: 100, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      _showPickerOptions(context, l10n);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Optional: Text implying it's purely cosmetic
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.indigoInk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.indigoInk),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.photoPrivacyNote,
                    style: GoogleFonts.outfit(
                      color: AppTheme.indigoInk,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (widget.selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    l10n.removePhoto,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onImageSelected(null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
