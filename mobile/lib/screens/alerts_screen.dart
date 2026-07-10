import 'package:flutter/material.dart';

import '../services/alerts_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback_snackbar.dart';
import '../widgets/section_label.dart';

/// Alertes mouvement / géofencing, branchées sur le service `alert_watcher`
/// (voir `backend/alert_watcher`) : il tourne en continu côté serveur et
/// notifie via ntfy.sh, donc ça marche même téléphone verrouillé ou app
/// fermée — contrairement à un sondage fait depuis l'app elle-même.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _api = AlertsApiService(useMockData: const bool.fromEnvironment('USE_MOCK_DATA'));

  bool _loading = true;
  String? _loadError;
  AlertSettings? _settings;
  List<AlertZone> _zones = const [];
  bool _savingMovement = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([_api.fetchSettings(), _api.fetchZones()]);
      if (!mounted) return;
      setState(() {
        _settings = results[0] as AlertSettings;
        _zones = results[1] as List<AlertZone>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _toggleMovementAlert(bool value) async {
    setState(() {
      _settings = AlertSettings(movementAlertEnabled: value, ntfyTopic: _settings!.ntfyTopic);
      _savingMovement = true;
    });
    try {
      await _api.updateSettings(movementAlertEnabled: value);
    } catch (e) {
      if (mounted) {
        setState(() => _settings = AlertSettings(movementAlertEnabled: !value, ntfyTopic: _settings!.ntfyTopic));
        showActionFeedback(context, success: false, message: '$e');
      }
    } finally {
      if (mounted) setState(() => _savingMovement = false);
    }
  }

  Future<void> _editNtfyTopic() async {
    final controller = TextEditingController(text: _settings?.ntfyTopic ?? '');
    final topic = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications (ntfy)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Installe l\'app ntfy sur ton téléphone, abonne-toi à un topic unique, '
              'puis renseigne son nom ici.',
              style: TextStyle(fontSize: 12.5, color: AppColors.ashDim),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'ex: mypeugeot-alertes-x7k2p'),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (topic == null || !mounted) return;
    final trimmed = topic.trim();
    try {
      await _api.updateSettings(ntfyTopic: trimmed);
      if (!mounted) return;
      setState(() => _settings = AlertSettings(movementAlertEnabled: _settings!.movementAlertEnabled, ntfyTopic: trimmed));
      showActionFeedback(context, success: true, message: 'Topic de notification enregistré.');
    } catch (e) {
      if (mounted) showActionFeedback(context, success: false, message: '$e');
    }
  }

  Future<void> _addZone() async {
    final nameController = TextEditingController();
    var radius = 300.0;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle zone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Centrée sur la position actuelle de la voiture : gare-toi à l\'endroit voulu avant de l\'ajouter.',
                style: TextStyle(fontSize: 12.5, color: AppColors.ashDim),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Ex: Domicile, Travail…'),
              ),
              const SizedBox(height: 10),
              Text('Rayon : ${radius.round()} m', style: const TextStyle(fontSize: 12.5, color: AppColors.ash)),
              Slider(
                value: radius,
                min: 100,
                max: 2000,
                divisions: 19,
                label: '${radius.round()} m',
                onChanged: (v) => setDialogState(() => radius = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop({'name': nameController.text, 'radius': radius.round()}),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final name = (result['name'] as String).trim();
    if (name.isEmpty) return;
    try {
      final zones = await _api.addZone(name: name, radiusMeters: result['radius'] as int);
      if (!mounted) return;
      setState(() => _zones = zones);
      showActionFeedback(context, success: true, message: 'Zone « $name » ajoutée.');
    } catch (e) {
      if (mounted) showActionFeedback(context, success: false, message: '$e');
    }
  }

  Future<void> _toggleZone(AlertZone zone, bool enabled) async {
    final previous = _zones;
    setState(() {
      _zones = [
        for (final z in _zones)
          if (z.name == zone.name)
            AlertZone(name: z.name, latitude: z.latitude, longitude: z.longitude, radiusMeters: z.radiusMeters, enabled: enabled)
          else
            z,
      ];
    });
    try {
      final zones = await _api.setZoneEnabled(zone.name, enabled);
      if (mounted) setState(() => _zones = zones);
    } catch (e) {
      if (mounted) {
        setState(() => _zones = previous);
        showActionFeedback(context, success: false, message: '$e');
      }
    }
  }

  Future<void> _deleteZone(AlertZone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la zone ?'),
        content: Text('« ${zone.name} » ne sera plus surveillée.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final zones = await _api.deleteZone(zone.name);
      if (mounted) setState(() => _zones = zones);
    } catch (e) {
      if (mounted) showActionFeedback(context, success: false, message: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erreur : $_loadError', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final settings = _settings!;
    final activeCount = _zones.where((z) => z.enabled).length + (settings.movementAlertEnabled ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const IconBadge(Icons.shield_moon_outlined, size: 52, iconSize: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$activeCount alerte${activeCount > 1 ? 's' : ''} active${activeCount > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.paper),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_zones.length} zone${_zones.length > 1 ? 's' : ''} configurée${_zones.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.ashDim),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Surveillance'),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const IconBadge(Icons.warning_amber_rounded),
              title: const Text('Mouvement suspect'),
              subtitle: const Text('Notification si la voiture démarre'),
              value: settings.movementAlertEnabled,
              onChanged: _savingMovement ? null : _toggleMovementAlert,
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Notifications'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const IconBadge(Icons.notifications_active_outlined),
              title: const Text('Topic ntfy'),
              subtitle: Text(
                settings.ntfyTopic.isEmpty
                    ? 'Non configuré — les alertes ne seront pas envoyées'
                    : settings.ntfyTopic,
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.ashDim),
              onTap: _editNtfyTopic,
            ),
          ),
          const SizedBox(height: 20),
          SectionLabel(
            'Zones géofencing',
            trailing: const Text('serveur', style: TextStyle(fontSize: 11, color: AppColors.ashDim)),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final zone in _zones)
                  ListTile(
                    leading: const IconBadge(Icons.location_on_outlined),
                    title: Text(zone.name),
                    subtitle: Text('Rayon ${zone.radiusMeters} m — alerte si la voiture entre/sort de cette zone'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.ashDim),
                          onPressed: () => _deleteZone(zone),
                        ),
                        Switch(value: zone.enabled, onChanged: (v) => _toggleZone(zone, v)),
                      ],
                    ),
                  ),
                ListTile(
                  leading: const IconBadge(Icons.add_circle_outline),
                  title: const Text('Ajouter une zone'),
                  onTap: _addZone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Ces alertes sont surveillées en continu côté serveur (service alert_watcher) et notifiées via ntfy, '
              'donc elles fonctionnent même app fermée. Configure d\'abord le topic ntfy ci-dessus.',
              style: TextStyle(fontSize: 11.5, color: AppColors.ashDim),
            ),
          ),
        ],
      ),
    );
  }
}
