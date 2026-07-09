import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vehicle_status.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback_snackbar.dart';
import '../widgets/section_label.dart';

/// Localisation de la voiture, à partir de `last_position` (déjà inclus dans
/// `GET /get_vehicleinfo/<vin>`, coordonnées GeoJSON confirmées sur un vrai
/// véhicule).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.vin});

  final String vin;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiService(useMockData: const bool.fromEnvironment('USE_MOCK_DATA'));
  late Future<VehicleStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = _api.fetchStatus(widget.vin);
  }

  void _refresh() => setState(() => _statusFuture = _api.fetchStatus(widget.vin, forceRefresh: true));

  Future<void> _openInMaps(double lat, double lon) async {
    final uri = (!kIsWeb && Platform.isIOS)
        ? Uri.parse('https://maps.apple.com/?ll=$lat,$lon&q=$lat,$lon')
        : Uri.parse('geo:$lat,$lon?q=$lat,$lon');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        showActionFeedback(context, success: false, message: 'Aucune application de cartes disponible.');
      }
    } catch (e) {
      if (mounted) showActionFeedback(context, success: false, message: 'Impossible d\'ouvrir Maps : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localisation'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
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
          if (!status.hasPosition) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Position indisponible pour le moment.\nLe véhicule doit avoir émis au moins une position récemment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.ashDim),
                ),
              ),
            );
          }

          final point = LatLng(status.latitude!, status.longitude!);

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(initialCenter: point, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.alexdel.mypeugeot.mypeugeot',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 46,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.goldBright,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                          ),
                          child: const Icon(Icons.directions_car, color: AppColors.background, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const IconBadge(Icons.place_outlined, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.paper,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                status.positionUpdatedAt != null
                                    ? 'Vue le ${_formatDateTime(status.positionUpdatedAt!)}'
                                    : 'Horodatage inconnu',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.ashDim),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openInMaps(point.latitude, point.longitude),
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Itinéraire'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        'à ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
