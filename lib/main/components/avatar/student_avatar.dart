import '../../../design_system/presentation/system_theme.dart';
import 'avatar_network_image.dart';
import 'dart:io';
import 'dart:typed_data';
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
  final Widget? placeholder;
  final Color? backgroundColor;
  final String? gender;
  final StorageService? storageService;

  const StudentAvatar({
    Key? key,
    this.avatarFileName,
    this.size = 120.0,
    this.onAvatarSelected,
    this.pendingImageFile,
    this.yellowRibbonCount,
    this.placeholder,
    this.backgroundColor,
    this.gender,
    this.storageService,
  }) : super(key: key);

  @override
  State<StudentAvatar> createState() => _StudentAvatarState();
}

class _StudentAvatarState extends State<StudentAvatar> {
  late final StorageService _storageService =
      widget.storageService ?? StorageService();
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;
  bool _isLoading = false;
  Uint8List? _webPendingImage;
  int _avatarRequest = 0;
  bool _loadFailed = false;

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
    final pending = widget.pendingImageFile;
    _webPendingImage = null;
    if (pending == null || !kIsWeb) return;
    try {
      final bytes = await pending.readAsBytes();
      if (mounted && identical(pending, widget.pendingImageFile)) {
        setState(() => _webPendingImage = bytes);
      }
    } catch (_) {
      if (mounted && identical(pending, widget.pendingImageFile)) {
        setState(() => _loadFailed = true);
      }
    }
  }

  Future<void> _loadAvatarUrl() async {
    final request = ++_avatarRequest;
    final fileName = widget.avatarFileName;
    setState(() {
      _avatarUrl = null;
      _loadFailed = false;
      _isLoading = fileName != null && fileName.trim().isNotEmpty;
    });
    if (!_isLoading) return;
    String? url;
    try {
      url = await _storageService.getAvatarUrl(fileName);
    } catch (_) {
      // Show a retry affordance, while keeping the stored photo reference.
    }
    if (!mounted || request != _avatarRequest) return;
    setState(() {
      _avatarUrl = url;
      _isLoading = false;
      _loadFailed = url == null;
    });
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onAvatarSelected != null ? _pickImage : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.backgroundColor ??
                  SystemTheme.of(context).color('secondary'),
              boxShadow: [
                BoxShadow(
                  color: SystemTheme.of(context)
                      .color('primaryText')
                      .withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildAvatarContent(),
          ),
        ),
        if (widget.yellowRibbonCount != null)
          Padding(
            padding: EdgeInsets.only(
                top: SystemTheme.of(context).metric('spaceSmall')),
            child: YellowRibbonCountBadge(
              count: widget.yellowRibbonCount!,
              showLabel: widget.size >= 100,
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
                : (_loadFailed
                    ? _buildLoadError()
                    : const CircularProgressIndicator()))
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

    if (_loadFailed) return _buildLoadError();

    if (_avatarUrl != null) {
      return Stack(
        children: [
          ClipOval(
            child: AvatarNetworkImage(
              key: ValueKey('$_avatarUrl:$_avatarRequest'),
              url: _avatarUrl!,
              size: widget.size,
              onError: _buildLoadError,
            ),
          ),
          if (widget.onAvatarSelected != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: SystemTheme.of(context).primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: SystemTheme.of(context).onPrimary,
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
        _buildPlaceholder(),
        if (widget.onAvatarSelected != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: SystemTheme.of(context).primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                color: SystemTheme.of(context).onPrimary,
                size: widget.size * 0.2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadError() => Stack(
        alignment: Alignment.center,
        children: [
          _buildPlaceholder(),
          Positioned(
            bottom: 0,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  backgroundColor:
                      SystemTheme.of(context).color('secondaryBackground')),
              onPressed: _loadAvatarUrl,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('重新載入',
                  style: TextStyle(
                      fontSize: SystemTheme.of(context).metric('labelSize'))),
            ),
          ),
        ],
      );

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;
    final asset = switch (widget.gender?.trim()) {
      '男' => 'assets/images/student_avatar_boy.png',
      '女' => 'assets/images/student_avatar_girl.png',
      _ => null,
    };
    if (asset == null) {
      return Icon(Icons.person,
          size: widget.size * 0.5,
          color: SystemTheme.of(context).color('secondaryText'));
    }
    return ClipOval(
      child: Image.asset(asset,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          semanticLabel: widget.gender?.trim() == '女' ? '女生預設頭像' : '男生預設頭像'),
    );
  }
}
