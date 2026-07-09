import 'package:flutter/material.dart';

class _GeofenceZone {
  _GeofenceZone({required this.name, required this.enabled});
  final String name;
  bool enabled;
}

/// Stub d'alertes / géofencing (notif si la voiture bouge sans toi, ou sort
/// d'une zone définie). Données locales pour l'instant.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.warning_amber_rounded),
              title: const Text('Alerte mouvement suspect'),
              subtitle: const Text('Notification si la voiture démarre sans ton téléphone à proximité'),
              value: _movementAlert,
              onChanged: (v) => setState(() => _movementAlert = v),
            ),
          ),
          const SizedBox(height: 16),
          Text('Zones géofencing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final zone in _zones)
                  SwitchListTile(
                    secondary: const Icon(Icons.location_on_outlined),
                    title: Text(zone.name),
                    subtitle: const Text('Alerte si la voiture entre/sort de cette zone'),
                    value: zone.enabled,
                    onChanged: (v) => setState(() => zone.enabled = v),
                  ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Ajouter une zone'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sélection de zone à venir.')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
