import 'package:flutter/material.dart';

import '../models/vehicle_status.dart';
import '../services/api_service.dart';
import '../widgets/battery_gauge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // TODO: mettre le vrai VIN une fois le backend configuré (voir backend/README.md).
  static const _vin = 'VFXXXXXXXXXXXXXXX';

  final _api = ApiService(useMockData: true);
  late Future<VehicleStatus> _statusFuture;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _statusFuture = _api.fetchStatus(_vin);
  }

  void _refresh() {
    setState(() {
      _statusFuture = _api.fetchStatus(_vin);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _actionInProgress = true);
    try {
      await action();
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma e-208'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<VehicleStatus>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final status = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BatteryGauge(
                      percent: status.batteryLevelPercent,
                      rangeKm: status.rangeKm,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(status.isLocked ? Icons.lock : Icons.lock_open),
                  title: Text(status.isLocked ? 'Verrouillée' : 'Déverrouillée'),
                ),
                ListTile(
                  leading: Icon(status.isCharging ? Icons.bolt : Icons.bolt_outlined),
                  title: Text(status.isCharging ? 'En charge' : 'Non en charge'),
                ),
                const Spacer(),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _actionInProgress
                          ? null
                          : () => _runAction(() => status.isLocked
                              ? _api.unlockDoors(_vin)
                              : _api.lockDoors(_vin)),
                      icon: Icon(status.isLocked ? Icons.lock_open : Icons.lock),
                      label: Text(status.isLocked ? 'Déverrouiller' : 'Verrouiller'),
                    ),
                    FilledButton.icon(
                      onPressed: _actionInProgress
                          ? null
                          : () => _runAction(() => status.isCharging
                              ? _api.stopCharge(_vin)
                              : _api.startCharge(_vin)),
                      icon: const Icon(Icons.bolt),
                      label: Text(status.isCharging ? 'Arrêter la charge' : 'Démarrer la charge'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _actionInProgress
                          ? null
                          : () => _runAction(() => _api.preconditionCabin(_vin)),
                      icon: const Icon(Icons.ac_unit),
                      label: const Text('Préconditionner'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
