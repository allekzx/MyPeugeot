import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_label.dart';

/// Programmation de charge : seuil cible + heures creuses, reliée à
/// `GET /charge_control` (route confirmée côté backend).
class ChargeScheduleScreen extends StatefulWidget {
  const ChargeScheduleScreen({super.key, required this.vin, this.currentLevelPercent = 74});

  final String vin;
  final int currentLevelPercent;

  @override
  State<ChargeScheduleScreen> createState() => _ChargeScheduleScreenState();
}

class _ChargeScheduleScreenState extends State<ChargeScheduleScreen> {
  final _api = ApiService(useMockData: const bool.fromEnvironment('USE_MOCK_DATA'));
  double _targetPercent = 80;
  bool _offPeakEnabled = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);
  bool _saving = false;

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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final time = _offPeakEnabled ? _startTime : TimeOfDay.now();
      await _api.updateChargeControl(
        widget.vin,
        hour: time.hour,
        minute: time.minute,
        percentage: _targetPercent.round(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programmation de charge enregistrée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), duration: const Duration(seconds: 8)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charge programmée')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ChargeRing(current: widget.currentLevelPercent, target: _targetPercent.round()),
          const SizedBox(height: 4),
          Slider(
            value: _targetPercent,
            min: 50,
            max: 100,
            divisions: 10,
            label: '${_targetPercent.round()} %',
            onChanged: (v) => setState(() => _targetPercent = v),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Programmation'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const IconBadge(Icons.nightlight_round),
                  title: const Text('Charger aux heures creuses'),
                  subtitle: const Text('Décale le démarrage de la charge sur la plage définie'),
                  value: _offPeakEnabled,
                  onChanged: (v) => setState(() => _offPeakEnabled = v),
                ),
                if (_offPeakEnabled) ...[
                  ListTile(
                    leading: const IconBadge(Icons.bedtime_outlined),
                    title: const Text('Début'),
                    trailing: Text(_startTime.format(context), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.paper)),
                    onTap: () => _pickTime(true),
                  ),
                  ListTile(
                    leading: const IconBadge(Icons.wb_sunny_outlined),
                    title: const Text('Fin'),
                    trailing: Text(_endTime.format(context), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.paper)),
                    onTap: () => _pickTime(false),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _ChargeRing extends StatelessWidget {
  const _ChargeRing({required this.current, required this.target});

  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: CircularProgressIndicator(
              value: current / 100,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.goldDim),
            ),
          ),
          SizedBox(
            height: 150,
            width: 150,
            child: CircularProgressIndicator(
              value: target / 100,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(AppColors.goldBright),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$current → $target%',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.paper),
              ),
              const SizedBox(height: 4),
              const Text('cible de charge', style: TextStyle(fontSize: 11, color: AppColors.ashDim)),
            ],
          ),
        ],
      ),
    );
  }
}
