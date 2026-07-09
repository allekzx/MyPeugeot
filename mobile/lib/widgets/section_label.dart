import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Libellé de section façon instrument (majuscules, tracking large) —
/// même registre typographique que "AUTONOMIE ESTIMÉE" sur le dashboard.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.ashDim),
    );
    if (trailing == null) return label;
    return Row(children: [label, const Spacer(), trailing!]);
  }
}

/// Icône dans un petit médaillon arrondi — même registre que le plateau
/// d'actions du dashboard.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 40, this.iconSize = 18});

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, size: iconSize, color: AppColors.goldBright),
    );
  }
}
