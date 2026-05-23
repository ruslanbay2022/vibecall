import 'package:flutter/material.dart';

class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double radius;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.5,
        ),
      ),
    );
  }
}
