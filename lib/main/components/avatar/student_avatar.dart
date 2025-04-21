import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/storage_service.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yellow_ribbon/yellow_ribbon_count_badge.dart';

class StudentAvatar extends StatefulWidget {
  final String? avatarFileName;
  final double size;
  final Function(XFile file)? onAvatarSelected;
  final XFile? pendingImageFile;
  final int? yellowRibbonCount;

  const StudentAvatar({
    Key? key,
    this.avatarFileName,
    this.size = 120.0,
    this.onAvatarSelected,
    this.pendingImageFile,
    this.yellowRibbonCount,
  }) : super(key: key);

  @override
  State<StudentAvatar> createState() => _StudentAvatarState();
}

class _StudentAvatarState extends State<StudentAvatar> {
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;
  bool _isLoading = false;
  Uint8List? _webPendingImage;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
    _loadPendingImage();
  }

  @override
  void didUpdateWidget(StudentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarFileName != widget.avatarFileName) {
      _loadAvatarUrl();
    }

    if (oldWidget.pendingImageFile != widget.pendingImageFile) {
      _loadPendingImage();
    }
  }

  Future<void> _loadPendingImage() async {
    if (widget.pendingImageFile != null) {
      if (kIsWeb) {
        _webPendingImage = await widget.pendingImageFile!.readAsBytes();
        setState(() {});
      } else {
        setState(() {});
      }
    }
  }

  Future<void> _loadAvatarUrl() async {
    if (widget.avatarFileName != null) {
      setState(() {
        _isLoading = true;
      });

      final url = await _storageService.getAvatarUrl(widget.avatarFileName);

      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null && widget.onAvatarSelected != null) {
        widget.onAvatarSelected!(image);
      }
    } catch (e) {
      debugPrint('選擇圖片失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onAvatarSelected != null ? _pickImage : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildAvatarContent(),
          ),
        ),
        if (widget.yellowRibbonCount != null)
          Positioned(
            top: 0,
            right: -10,
            child: YellowRibbonCountBadge(
              count: widget.yellowRibbonCount!,
              size: widget.size * 0.2,
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent() {
    if (widget.pendingImageFile != null) {
      return ClipOval(
        child: kIsWeb
            ? (_webPendingImage != null
                ? Image.memory(
                    _webPendingImage!,
                    fit: BoxFit.cover,
                  )
                : const CircularProgressIndicator())
            : Image.file(
                File(widget.pendingImageFile!.path),
                fit: BoxFit.cover,
              ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_avatarUrl != null) {
      return Stack(
        children: [
          ClipOval(
            child: Image.network(
              _avatarUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person,
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),
          if (widget.onAvatarSelected != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.person,
          size: widget.size * 0.5,
          color: Colors.grey,
        ),
        if (widget.onAvatarSelected != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: widget.size * 0.2,
              ),
            ),
          ),
      ],
    );
  }
}
