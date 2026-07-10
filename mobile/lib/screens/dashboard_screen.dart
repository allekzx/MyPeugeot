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
  VehicleStatus? _lastKnownStatus;
  bool _refreshing = false;

  static const _confirmAttempts = 6;
  static const _confirmDelay = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _statusFuture = _api.fetchStatus(widget.vin);
    _statusFuture.then((s) {
      if (mounted) _lastKnownStatus = s;
    }).catchError((_) {});
  }

  /// Rafraîchit le statut. `get_vehicleinfo?from_cache=0` ne relit que le
  /// dernier statut connu de PSA — qui ne change que quand la voiture
  /// communique elle-même (contact, charge…) — donc un simple GET peut
  /// sembler "ne rien faire" alors que la voiture n'a juste rien transmis de
  /// neuf. On réveille donc la voiture d'abord, puis on re-sonde le statut
  /// pendant quelques secondes en attendant une donnée plus récente que la
  /// précédente (`updated_at` plus tardif).
  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final baseline = _lastKnownStatus?.updatedAt;

    try {
      await _api.wakeUp(widget.vin);
    } catch (_) {
      // Le réveil peut être refusé/rate-limité par PSA : on tente quand même
      // de relire le statut serveur ci-dessous.
    }

    VehicleStatus? latest;
    for (var attempt = 0; attempt < _confirmAttempts; attempt++) {
      try {
        latest = await _api.fetchStatus(widget.vin, forceRefresh: true);
        if (!mounted) return;
        setState(() {
          _statusFuture = Future.value(latest);
          _lastKnownStatus = latest;
        });
        if (baseline == null || latest.updatedAt.isAfter(baseline)) break;
      } catch (e) {
        if (!mounted) return;
        setState(() => _statusFuture = Future.error(e));
        latest = null;
        break;
      }
      if (attempt < _confirmAttempts - 1) await Future.delayed(_confirmDelay);
    }

    if (!mounted) return;
    setState(() => _refreshing = false);
    if (latest != null && baseline != null && !latest.updatedAt.isAfter(baseline)) {
      showActionFeedback(
        context,
        success: true,
        message: 'Statut relu : la voiture n\'a transmis aucune nouvelle donnée pour l\'instant.',
      );
    }
  }

  /// Envoie une action véhicule. Si [confirmedWhen] est fourni, le spinner
  /// reste actif au-delà de la simple réponse HTTP 200 : on re-sonde le
  /// statut réel du véhicule pendant quelques secondes avant d'annoncer un
  /// succès, car PSA répond parfois 200 sans que la voiture exécute
  /// réellement la commande (github.com/flobz/psa_car_controller/issues/1162).
  Future<void> _runAction(
    String id,
    String successMessage,
    Future<void> Function() action, {
    bool Function(VehicleStatus)? confirmedWhen,
  }) async {
    setState(() => _pendingAction = id);
    try {
      await action();
      if (confirmedWhen == null) {
        _refresh();
        if (mounted) showActionFeedback(context, success: true, message: successMessage);
      } else {
        final confirmed = await _waitForConfirmation(confirmedWhen);
        if (mounted) {
          showActionFeedback(
            context,
            success: confirmed,
            message: confirmed
                ? successMessage
                : 'Commande envoyée mais pas encore confirmée par la voiture. Vérifiez dans quelques instants.',
          );
        }
      }
    } catch (e) {
      if (mounted) showActionFeedback(context, success: false, message: '$e');
    } finally {
      if (mounted) setState(() => _pendingAction = null);
    }
  }

  /// Re-sonde `get_vehicleinfo` (sans cache) jusqu'à ce que [confirmedWhen]
  /// soit vrai, ou abandonne après [_confirmAttempts] tentatives.
  Future<bool> _waitForConfirmation(bool Function(VehicleStatus) confirmedWhen) async {
    for (var attempt = 0; attempt < _confirmAttempts; attempt++) {
      await Future.delayed(_confirmDelay);
      try {
        final status = await _api.fetchStatus(widget.vin, forceRefresh: true);
        if (!mounted) return false;
        setState(() {
          _statusFuture = Future.value(status);
          _lastKnownStatus = status;
        });
        if (confirmedWhen(status)) return true;
      } catch (_) {
        // Erreur transitoire pendant le sondage : on retente au tour suivant.
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma e-208'),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldBright),
                  )
                : const Icon(Icons.refresh),
            onPressed: _refreshing ? null : _refresh,
          ),
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
                    // `doors_state` revient toujours `null` sur ce véhicule (cf.
                    // VehicleStatus._parseLocked) : on ne peut pas vérifier l'état
                    // réel, donc on ne prétend pas confirmer — juste envoyer.
                    status.isLocked ? 'Déverrouillage envoyé (non vérifiable).' : 'Verrouillage envoyé (non vérifiable).',
                    () => status.isLocked ? _api.unlockDoors(widget.vin) : _api.lockDoors(widget.vin),
                  ),
                  onPrecondition: () => _runAction(
                    'climate',
                    'Climatisation activée.',
                    () => _api.preconditionCabin(widget.vin),
                    confirmedWhen: (s) => s.isPreconditioning == true,
                  ),
                  onChargeToggle: () {
                    final targetCharging = !status.isCharging;
                    _runAction(
                      'charge',
                      targetCharging ? 'Charge démarrée.' : 'Charge arrêtée.',
                      () => targetCharging ? _api.startCharge(widget.vin) : _api.stopCharge(widget.vin),
                      confirmedWhen: (s) => s.isCharging == targetCharging,
                    );
                  },
                  // Le klaxon est une action instantanée : rien à confirmer dans le statut.
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
