import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

/// Stub d'écran de connexion. La vraie authentification passera par le
/// backend (session/token PSA géré côté serveur), pas directement par l'app.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyPeugeot')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.electric_car, size: 96),
              const SizedBox(height: 16),
              const Text(
                'Connexion au backend à venir.\nPour l\'instant, accès direct au dashboard (données simulées).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                },
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
