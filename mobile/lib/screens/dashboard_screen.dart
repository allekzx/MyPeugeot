import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/vehicle_status.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback_snackbar.dart';
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
  String? _pendingAction;

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

  Future<void> _runAction(String id, String successMessage, Future<void> Function() action) async {
    setState(() => _pendingAction = id);
    try {
      await action();
      _refresh();
      if (mounted) showActionFeedback(context, success: true, message: successMessage);
    } catch (e) {
      if (mounted) showActionFeedback(context, success: false, message: '$e');
    } finally {
      if (mounted) setState(() => _pendingAction = null);
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
                    const Text(
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
                  pendingAction: _pendingAction,
                  status: status,
                  onLockToggle: () => _runAction(
                    'lock',
                    status.isLocked ? 'Déverrouillage envoyé.' : 'Verrouillage envoyé.',
                    () => status.isLocked ? _api.unlockDoors(widget.vin) : _api.lockDoors(widget.vin),
                  ),
                  onPrecondition: () => _runAction(
                    'climate',
                    'Climatisation demandée.',
                    () => _api.preconditionCabin(widget.vin),
                  ),
                  onChargeToggle: () => _runAction(
                    'charge',
                    status.isCharging ? 'Arrêt de charge envoyé.' : 'Démarrage de charge envoyé.',
                    () => status.isCharging ? _api.stopCharge(widget.vin) : _api.startCharge(widget.vin),
                  ),
                  onHorn: () => _runAction('horn', 'Klaxon envoyé.', () => _api.honk(widget.vin)),
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
    required this.pendingAction,
    required this.status,
    required this.onLockToggle,
    required this.onPrecondition,
    required this.onChargeToggle,
    required this.onHorn,
  });

  final String? pendingAction;
  final VehicleStatus status;
  final VoidCallback onLockToggle;
  final VoidCallback onPrecondition;
  final VoidCallback onChargeToggle;
  final VoidCallback onHorn;

  @override
  Widget build(BuildContext context) {
    final busy = pendingAction != null;

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
                  active: !status.isLocked,
                  loading: pendingAction == 'lock',
                  onTap: busy ? null : onLockToggle,
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.ac_unit,
                  label: status.isPreconditioning ? 'Climat. active' : 'Climat.',
                  active: status.isPreconditioning,
                  loading: pendingAction == 'climate',
                  onTap: busy ? null : onPrecondition,
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.bolt,
                  label: status.isCharging ? 'En charge' : 'Charge',
                  active: status.isCharging,
                  loading: pendingAction == 'charge',
                  onTap: busy ? null : onChargeToggle,
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.campaign,
                  label: 'Klaxon',
                  loading: pendingAction == 'horn',
                  onTap: busy ? null : onHorn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.goldBright : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: active ? null : Border.all(color: Colors.white.withOpacity(0.06)),
                boxShadow: active
                    ? [BoxShadow(color: AppColors.goldBright.withOpacity(0.45), blurRadius: 12)]
                    : null,
              ),
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: active ? AppColors.background : AppColors.goldBright,
                      ),
                    )
                  : Icon(icon, size: 19, color: active ? AppColors.background : AppColors.goldBright),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.goldBright : AppColors.ash,
              ),
              textAlign: TextAlign.center,
            ),
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
