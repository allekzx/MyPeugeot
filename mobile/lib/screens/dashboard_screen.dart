import 'package:flutter/material.dart';

import '../models/vehicle_status.dart';
import '../services/api_service.dart';
import '../widgets/battery_gauge.dart';
import '../widgets/car_hero.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.vin});

  final String vin;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService(useMockData: true);
  late Future<VehicleStatus> _statusFuture;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _statusFuture = _api.fetchStatus(widget.vin);
  }

  void _refresh() {
    setState(() {
      _statusFuture = _api.fetchStatus(widget.vin);
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CarHero(),
              const SizedBox(height: 16),
              // Vue équilibrée : cartes de même poids visuel, rien ne domine.
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _StatusCard(
                    icon: Icons.battery_charging_full,
                    title: 'Batterie',
                    child: BatteryGauge(percent: status.batteryLevelPercent, rangeKm: status.rangeKm),
                  ),
                  _StatusCard(
                    icon: status.isLocked ? Icons.lock : Icons.lock_open,
                    title: status.isLocked ? 'Verrouillée' : 'Déverrouillée',
                  ),
                  _StatusCard(
                    icon: status.isCharging ? Icons.bolt : Icons.bolt_outlined,
                    title: status.isCharging ? 'En charge' : 'Non en charge',
                  ),
                  _StatusCard(
                    icon: Icons.access_time,
                    title: 'Mis à jour',
                    child: Text(
                      '${status.updatedAt.hour.toString().padLeft(2, '0')}:${status.updatedAt.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _actionInProgress
                        ? null
                        : () => _runAction(() => status.isLocked
                            ? _api.unlockDoors(widget.vin)
                            : _api.lockDoors(widget.vin)),
                    icon: Icon(status.isLocked ? Icons.lock_open : Icons.lock),
                    label: Text(status.isLocked ? 'Déverrouiller' : 'Verrouiller'),
                  ),
                  FilledButton.icon(
                    onPressed: _actionInProgress
                        ? null
                        : () => _runAction(() => status.isCharging
                            ? _api.stopCharge(widget.vin)
                            : _api.startCharge(widget.vin)),
                    icon: const Icon(Icons.bolt),
                    label: Text(status.isCharging ? 'Arrêter la charge' : 'Démarrer la charge'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _actionInProgress
                        ? null
                        : () => _runAction(() => _api.preconditionCabin(widget.vin)),
                    icon: const Icon(Icons.ac_unit),
                    label: const Text('Préconditionner'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.title, this.child});

  final IconData icon;
  final String title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            child!,
          ],
        ),
      ),
    );
  }
}
