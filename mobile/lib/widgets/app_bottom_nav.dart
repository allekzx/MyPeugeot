import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NavItem {
  const NavItem({required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Barre de navigation minimale : icône + petit point d'accent au-dessus de
/// l'onglet actif, sans fond coloré.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: _NavTile(item: items[i], active: i == currentIndex),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.goldBright : AppColors.ashDim;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 6,
            child: active
                ? Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
                : null,
          ),
          const SizedBox(height: 4),
          Icon(active ? item.selectedIcon : item.icon, size: 21, color: color),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: color),
          ),
        ],
      ),
    );
  }
}
