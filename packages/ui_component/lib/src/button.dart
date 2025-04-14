import 'package:flutter/material.dart';

class DefaultTextButton extends StatelessWidget {
  final String text;

  const DefaultTextButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(text),
    );
  }
}
