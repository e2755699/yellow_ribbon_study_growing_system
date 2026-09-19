import 'package:flutter/material.dart';

class AvatarNetworkImage extends StatelessWidget {
  const AvatarNetworkImage(
      {super.key,
      required this.url,
      required this.size,
      required this.onError});
  final String url;
  final double size;
  final Widget Function() onError;

  @override
  Widget build(BuildContext context) => Image.network(url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __, ___) => onError());
}
