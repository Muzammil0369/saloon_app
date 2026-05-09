import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_helper.dart';

class UploadBox extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Function(File?)? onImagePicked;
  final File? initialImage;

  const UploadBox({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.camera_alt_outlined,
    this.onImagePicked,
    this.initialImage,
  });

  @override
  State<UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<UploadBox> {
  File? _imageFile;
  bool _uploaded = false;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
    _uploaded = _imageFile != null;
  }

  void _toggleUpload() {
    setState(() {
      if (_imageFile == null) {
        _uploaded = !_uploaded;
      }
    });
    if (widget.onImagePicked != null) {
      widget.onImagePicked!(_imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return GestureDetector(
      onTap: _toggleUpload,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: DottedDecoration(
          color: theme.isDark ? AppColors.primaryPink.withOpacity(0.5) : Colors.pink.shade200,
          shape: Shape.box,
          strokeWidth: 2,
          borderRadius: BorderRadius.circular(12),
          dash: const [8, 4],
        ),
        child: _imageFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        )
            : Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.borderColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _uploaded ? Icons.check_circle_rounded : widget.icon,
                  size: 32,
                  color: _uploaded ? AppColors.success : theme.mutedTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _uploaded ? 'Uploaded ✓' : widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _uploaded ? AppColors.success : theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _uploaded ? 'Tap to change' : widget.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.mutedTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}