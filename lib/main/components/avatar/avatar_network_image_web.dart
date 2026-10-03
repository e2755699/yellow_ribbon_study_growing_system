import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../../domain/utils/request_timeout.dart';

/// Display the Storage URL as an ordinary browser image. Flutter 3.24's
/// network image loader requires CORS, even when the photo can be displayed
/// directly by an img element. This does not change bucket permissions.
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
  StreamSubscription<html.Event>? _loadSubscription;
  StreamSubscription<html.Event>? _errorSubscription;
  bool _loaded = false;
  bool _failed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _loadSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.onError();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(fit: StackFit.expand, children: [
        HtmlElementView.fromTagName(
          tagName: 'img',
          onElementCreated: (element) {
            final image = element as html.ImageElement;
            image.alt = '學生頭像';
            image.style
              ..width = '100%'
              ..height = '100%'
              ..objectFit = 'cover'
              ..borderRadius = '50%'
              ..pointerEvents = 'none';
            _loadSubscription = image.onLoad.listen((_) {
              _timer?.cancel();
              if (mounted) setState(() => _loaded = true);
            });
            _errorSubscription = image.onError.listen((_) {
              _timer?.cancel();
              if (mounted) setState(() => _failed = true);
            });
            image.src = widget.url;
            _timer?.cancel();
            _timer = Timer(requestTimeout, () {
              if (mounted) setState(() => _failed = true);
            });
          },
        ),
        if (!_loaded) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
