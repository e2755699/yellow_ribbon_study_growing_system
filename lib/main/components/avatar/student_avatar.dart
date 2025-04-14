import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/storage_service.dart';

class StudentAvatar extends StatefulWidget {
  final String? avatarFileName;
  final double size;
  final bool isEditable;
  final Function(XFile file)? onAvatarSelected;

  const StudentAvatar({
    Key? key,
    this.avatarFileName,
    this.size = 120.0,
    this.isEditable = false,
    this.onAvatarSelected,
  }) : super(key: key);

  @override
  State<StudentAvatar> createState() => _StudentAvatarState();
}

class _StudentAvatarState extends State<StudentAvatar> {
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  @override
  void didUpdateWidget(StudentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarFileName != widget.avatarFileName) {
      _loadAvatarUrl();
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
    return GestureDetector(
      onTap: widget.isEditable ? _pickImage : null,
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
    );
  }

  Widget _buildAvatarContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_avatarUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _avatarUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.person,
            size: 60,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.person,
          size: 60,
          color: Colors.grey,
        ),
        if (widget.isEditable)
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
}
