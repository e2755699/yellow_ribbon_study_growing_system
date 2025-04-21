import 'package:flutter/material.dart';

class YellowRibbonCount extends StatelessWidget {
  final int count;
  final double? size;

  const YellowRibbonCount({
    super.key,
    required this.count,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/yellow_ribbon.png',
          width: size,
          height: size,
        ),
        const SizedBox(width: 2),
        Text(
          'x$count',
          style: TextStyle(
            color: Colors.red[300],
            fontWeight: FontWeight.bold,
            fontSize: size,
          ),
        ),
      ],
    );
  }
}
