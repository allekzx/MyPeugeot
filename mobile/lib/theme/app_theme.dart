import 'package:flutter/material.dart';

/// Palette "Jaune Faro" premium — noir chaud, jaune moutarde profond en
/// accent, dans l'esprit des tableaux de bord Tesla/MySkoda.
class AppColors {
  static const background = Color(0xFF131110);
  static const surface = Color(0xFF1D1916);
  static const surfaceAlt = Color(0xFF262019);
  static const line = Color(0xFF35302A);
  static const gold = Color(0xFFD2A02A);
  static const goldBright = Color(0xFFF0C34C);
  static const goldDim = Color(0xFF8A6C1F);
  static const paper = Color(0xFFF4EFE4);
  static const ash = Color(0xFF9C9284);
  static const ashDim = Color(0xFF6B6459);
  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF5FAE72);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.paper,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.goldBright,
        foregroundColor: AppColors.background,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.goldBright,
        side: const BorderSide(color: AppColors.goldDim),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? AppColors.gold : AppColors.surfaceAlt;
      }),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.paper,
      displayColor: AppColors.paper,
    ),
  );
}
