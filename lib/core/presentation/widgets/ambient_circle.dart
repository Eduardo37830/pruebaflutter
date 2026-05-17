import 'package:flutter/material.dart';

class AmbientCircle extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const AmbientCircle({
    super.key,
    required this.color,
    this.size = 260,
    this.opacity = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
