import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Photo de la voiture en pleine largeur ; un tap fait apparaître un clin
/// d'œil (silhouette mécanique générique, pas un personnage sous licence).
class HeroPhoto extends StatefulWidget {
  const HeroPhoto({super.key, required this.isLocked, this.height = 320});

  final bool isLocked;
  final double height;

  @override
  State<HeroPhoto> createState() => _HeroPhotoState();
}

class _HeroPhotoState extends State<HeroPhoto> {
  bool _revealed = false;

  void _toggle() => setState(() => _revealed = !_revealed);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: _revealed
                  ? Image.asset(
                      'assets/images/robot_hero.jpg',
                      key: const ValueKey('robot'),
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.3),
                    )
                  : Image.asset(
                      'assets/images/car_hero.jpg',
                      key: const ValueKey('car'),
                      fit: BoxFit.cover,
                      alignment: const Alignment(-0.1, 0),
                    ),
            ),
            // Dégradé pour la lisibilité des chips + fondu avec le reste de l'écran.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 0.97],
                  colors: [Colors.transparent, AppColors.background],
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: _Chip(
                child: Text(_revealed ? 'Plus qu\'une voiture.' : 'e-208 · Jaune Faro'),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: _Chip(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.isLocked ? Icons.lock : Icons.lock_open, size: 12, color: AppColors.paper),
                    const SizedBox(width: 6),
                    Text(widget.isLocked ? 'Verrouillée' : 'Déverrouillée'),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 10,
              right: 18,
              child: Text(
                '👆 Touche la photo',
                style: TextStyle(
                  color: AppColors.paper.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.55),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: AppColors.paper, fontSize: 11, fontWeight: FontWeight.w600),
        child: child,
      ),
    );
  }
}
