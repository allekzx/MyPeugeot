import 'package:flutter/material.dart';

/// Stub de programmation de charge intelligente (seuil cible + heures
/// creuses). Purement local pour l'instant : à relier à l'endpoint de
/// programmation de charge du backend une fois confirmé.
class ChargeScheduleScreen extends StatefulWidget {
  const ChargeScheduleScreen({super.key});

  @override
  State<ChargeScheduleScreen> createState() => _ChargeScheduleScreenState();
}

class _ChargeScheduleScreenState extends State<ChargeScheduleScreen> {
  double _targetPercent = 80;
  bool _offPeakEnabled = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charge programmée')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seuil de charge cible', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: _targetPercent,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '${_targetPercent.round()} %',
                    onChanged: (v) => setState(() => _targetPercent = v),
                  ),
                  Text('${_targetPercent.round()} %', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Charger aux heures creuses'),
                  subtitle: const Text('Décale le démarrage de la charge sur la plage définie'),
                  value: _offPeakEnabled,
                  onChanged: (v) => setState(() => _offPeakEnabled = v),
                ),
                if (_offPeakEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.bedtime_outlined),
                    title: const Text('Début'),
                    trailing: Text(_startTime.format(context)),
                    onTap: () => _pickTime(true),
                  ),
                  ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Fin'),
                    trailing: Text(_endTime.format(context)),
                    onTap: () => _pickTime(false),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Programmation enregistrée (pas encore reliée au backend).')),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
