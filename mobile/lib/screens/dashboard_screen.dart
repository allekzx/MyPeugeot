import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/vehicle_status.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_photo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.vin});

  final String vin;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService(useMockData: const bool.fromEnvironment('USE_MOCK_DATA'));
  late Future<VehicleStatus> _statusFuture;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _statusFuture = _api.fetchStatus(widget.vin);
  }

  void _refresh() {
    setState(() {
      _statusFuture = _api.fetchStatus(widget.vin, forceRefresh: true);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _actionInProgress = true);
    try {
      await action();
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), duration: const Duration(seconds: 8)),
        );
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
            padding: EdgeInsets.zero,
            children: [
              HeroPhoto(isLocked: status.isLocked),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUTONOMIE ESTIMÉE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: AppColors.ashDim,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${status.batteryLevelPercent}',
                          style: const TextStyle(
                            fontSize: 58,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.5,
                            height: 1,
                            color: AppColors.paper,
                          ),
                        ),
                        const Text(
                          '%',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.ash),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${status.rangeKm} km',
                          style: const TextStyle(
                            fontSize: 17,
                            fontFamily: 'monospace',
                            color: AppColors.ash,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: status.batteryLevelPercent / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation(AppColors.goldBright),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _GlassActionTray(
                  actionInProgress: _actionInProgress,
                  status: status,
                  onLockToggle: () => _runAction(
                    () => status.isLocked ? _api.unlockDoors(widget.vin) : _api.lockDoors(widget.vin),
                  ),
                  onPrecondition: () => _runAction(() => _api.preconditionCabin(widget.vin)),
                  onChargeToggle: () => _runAction(
                    () => status.isCharging ? _api.stopCharge(widget.vin) : _api.startCharge(widget.vin),
                  ),
                  onHorn: () => _runAction(() => _api.honk(widget.vin)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: _InstrumentStrip(status: status),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassActionTray extends StatelessWidget {
  const _GlassActionTray({
    required this.actionInProgress,
    required this.status,
    required this.onLockToggle,
    required this.onPrecondition,
    required this.onChargeToggle,
    required this.onHorn,
  });

  final bool actionInProgress;
  final VehicleStatus status;
  final VoidCallback onLockToggle;
  final VoidCallback onPrecondition;
  final VoidCallback onChargeToggle;
  final VoidCallback onHorn;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: status.isLocked ? Icons.lock : Icons.lock_open,
                  label: status.isLocked ? 'Déverrouiller' : 'Verrouiller',
                  onTap: actionInProgress ? null : onLockToggle,
                ),
              ),
              Expanded(
                child: _ActionTile(icon: Icons.ac_unit, label: 'Climat.', onTap: actionInProgress ? null : onPrecondition),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.bolt,
                  label: 'Charge',
                  onTap: actionInProgress ? null : onChargeToggle,
                ),
              ),
              Expanded(
                child: _ActionTile(icon: Icons.campaign, label: 'Klaxon', onTap: actionInProgress ? null : onHorn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 19, color: AppColors.goldBright),
            ),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.ash), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InstrumentStrip extends StatelessWidget {
  const _InstrumentStrip({required this.status});

  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final updated =
        '${status.updatedAt.hour.toString().padLeft(2, '0')}:${status.updatedAt.minute.toString().padLeft(2, '0')}';
    final odometer = status.odometerKm != null ? '${status.odometerKm} km' : '—';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: _Instrument(label: 'Mis à jour', value: updated)),
          _divider(),
          Expanded(child: _Instrument(label: 'Odomètre', value: odometer)),
          _divider(),
          Expanded(
            child: _Instrument(
              label: 'Charge',
              chip: status.isCharging ? 'En charge' : 'Débranchée',
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 52, color: AppColors.line);
}

class _Instrument extends StatelessWidget {
  const _Instrument({required this.label, this.value, this.chip});

  final String label;
  final String? value;
  final String? chip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.ashDim),
          ),
          const SizedBox(height: 8),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppColors.paper),
            ),
          if (chip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(100)),
              child: Text(chip!, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ash)),
            ),
        ],
      ),
    );
  }
}
