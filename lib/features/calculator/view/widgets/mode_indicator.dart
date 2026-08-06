import 'package:flutter/material.dart';

import '../../../../core/math/angle_mode.dart';

class ModeIndicator extends StatelessWidget {
  const ModeIndicator({
    required this.angleMode,
    required this.onPressed,
    super.key,
  });

  final AngleMode angleMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(angleMode.label),
      avatar: const Icon(Icons.straighten, size: 18),
      onPressed: onPressed,
    );
  }
}
