import 'package:flutter/material.dart';
import 'dart:async';
import '../../../domain/utils/request_timeout.dart';

class AvatarNetworkImage extends StatefulWidget {
  const AvatarNetworkImage(
      {super.key,
      required this.url,
      required this.size,
      required this.onError});
  final String url;
  final double size;
  final Widget Function() onError;

  @override
  State<AvatarNetworkImage> createState() => _AvatarNetworkImageState();
}

class _AvatarNetworkImageState extends State<AvatarNetworkImage> {
  Timer? _timer;
  bool _failed = false;

  void _start() {
    _timer?.cancel();
    _failed = false;
    _timer = Timer(requestTimeout, () {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant AvatarNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _failed
      ? widget.onError()
      : Image.network(widget.url,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          frameBuilder: (_, child, frame, synchronous) {
            if (frame != null || synchronous) _timer?.cancel();
            return child;
          },
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, __, ___) {
            _timer?.cancel();
            return widget.onError();
          });
}
