import 'package:flutter/material.dart';

class YellowRibbonCountBadge extends StatelessWidget {
  final int count;
  final double? size;

  const YellowRibbonCountBadge({
    super.key,
    required this.count,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
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
      ),
    );
  }
}
