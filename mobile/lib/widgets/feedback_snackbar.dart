import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// SnackBar coloré succès/erreur pour donner un retour clair après une
/// action véhicule (verrouillage, charge, klaxon, etc.).
void showActionFeedback(BuildContext context, {required bool success, required String message}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      duration: Duration(seconds: success ? 3 : 8),
      backgroundColor: success ? AppColors.success : AppColors.danger,
      content: Row(
        children: [
          Icon(success ? Icons.check_circle_outline : Icons.error_outline, color: Colors.black, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600))),
        ],
      ),
    ),
  );
}
