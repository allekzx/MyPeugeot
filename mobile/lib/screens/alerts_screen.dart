import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _GeofenceZone {
  _GeofenceZone({required this.name, required this.enabled});
  final String name;
  bool enabled;
}

/// Alertes / géofencing (notif si la voiture bouge sans toi, ou sort d'une
/// zone définie). `psa_car_controller` n'expose pas ce type de règle côté
/// serveur pour l'instant : ces réglages restent locaux à l'appareil.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _movementAlert = true;
  final _zones = [
    _GeofenceZone(name: 'Domicile', enabled: true),
    _GeofenceZone(name: 'Travail', enabled: false),
  ];

  Future<void> _addZone() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle zone'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex: Parents, Travail…'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      setState(() => _zones.add(_GeofenceZone(name: name.trim(), enabled: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.warning_amber_rounded, color: AppColors.goldBright),
              title: const Text('Alerte mouvement suspect'),
              subtitle: const Text('Notification si la voiture démarre sans ton téléphone à proximité'),
              value: _movementAlert,
              onChanged: (v) => setState(() => _movementAlert = v),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Zones géofencing', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('local', style: TextStyle(fontSize: 11, color: AppColors.ashDim)),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final zone in _zones)
                  SwitchListTile(
                    secondary: const Icon(Icons.location_on_outlined, color: AppColors.goldBright),
                    title: Text(zone.name),
                    subtitle: const Text('Alerte si la voiture entre/sort de cette zone'),
                    value: zone.enabled,
                    onChanged: (v) => setState(() => zone.enabled = v),
                  ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: AppColors.goldBright),
                  title: const Text('Ajouter une zone'),
                  onTap: _addZone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Ces réglages restent sur cet appareil pour l\'instant : le backend ne propose pas encore de règles de géofencing.',
              style: TextStyle(fontSize: 11.5, color: AppColors.ashDim),
            ),
          ),
        ],
      ),
    );
  }
}
