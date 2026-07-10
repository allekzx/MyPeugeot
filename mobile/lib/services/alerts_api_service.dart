import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class AlertZone {
  AlertZone({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.enabled,
  });

  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool enabled;

  factory AlertZone.fromJson(Map<String, dynamic> json) => AlertZone(
        name: json['name'] as String,
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lon'] as num).toDouble(),
        radiusMeters: (json['radius_m'] as num).round(),
        enabled: json['enabled'] as bool? ?? true,
      );
}

class AlertSettings {
  AlertSettings({required this.movementAlertEnabled, required this.ntfyTopic});

  final bool movementAlertEnabled;
  final String ntfyTopic;

  factory AlertSettings.fromJson(Map<String, dynamic> json) => AlertSettings(
        movementAlertEnabled: json['movement_alert_enabled'] as bool? ?? true,
        ntfyTopic: json['ntfy_topic'] as String? ?? '',
      );
}

/// Client HTTP vers le service `alert_watcher` (voir `backend/alert_watcher`),
/// séparé de `psa_car_controller` : il tourne en continu côté serveur pour
/// détecter le démarrage et les entrées/sorties de zone même app fermée, et
/// notifie via ntfy.sh.
class AlertsApiService {
  AlertsApiService({String? baseUrl, this.useMockData = false})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'ALERTS_BASE_URL',
              defaultValue: 'http://localhost:5050',
            );

  final String baseUrl;
  final bool useMockData;

  AlertSettings _mockSettings = AlertSettings(movementAlertEnabled: true, ntfyTopic: '');
  final List<AlertZone> _mockZones = [
    AlertZone(name: 'Domicile', latitude: 48.8584, longitude: 2.2945, radiusMeters: 300, enabled: true),
  ];

  Future<AlertSettings> fetchSettings() async {
    if (useMockData) return _mockSettings;
    final response = await http.get(Uri.parse('$baseUrl/settings'));
    if (response.statusCode != 200) {
      throw ApiException('Échec de récupération des réglages (${response.statusCode})');
    }
    return AlertSettings.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateSettings({bool? movementAlertEnabled, String? ntfyTopic}) async {
    if (useMockData) {
      _mockSettings = AlertSettings(
        movementAlertEnabled: movementAlertEnabled ?? _mockSettings.movementAlertEnabled,
        ntfyTopic: ntfyTopic ?? _mockSettings.ntfyTopic,
      );
      return;
    }
    final body = <String, dynamic>{
      if (movementAlertEnabled != null) 'movement_alert_enabled': movementAlertEnabled,
      if (ntfyTopic != null) 'ntfy_topic': ntfyTopic,
    };
    final response = await http.put(
      Uri.parse('$baseUrl/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw ApiException('Échec de mise à jour des réglages (${response.statusCode}) : ${response.body}');
    }
  }

  Future<List<AlertZone>> fetchZones() async {
    if (useMockData) return List.unmodifiable(_mockZones);
    final response = await http.get(Uri.parse('$baseUrl/zones'));
    if (response.statusCode != 200) {
      throw ApiException('Échec de récupération des zones (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => AlertZone.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Crée une zone centrée sur la dernière position connue de la voiture
  /// (l'app ne propose pas de sélecteur de carte : on se gare à l'endroit
  /// voulu puis on ajoute la zone).
  Future<List<AlertZone>> addZone({required String name, required int radiusMeters}) async {
    if (useMockData) {
      if (_mockZones.any((z) => z.name == name)) {
        throw ApiException('Une zone porte déjà ce nom.');
      }
      _mockZones.add(AlertZone(
        name: name,
        latitude: 48.8584,
        longitude: 2.2945,
        radiusMeters: radiusMeters,
        enabled: true,
      ));
      return List.unmodifiable(_mockZones);
    }
    final response = await http.post(
      Uri.parse('$baseUrl/zones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'radius_m': radiusMeters}),
    );
    if (response.statusCode != 201) {
      throw ApiException(_zoneErrorMessage(response));
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => AlertZone.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AlertZone>> setZoneEnabled(String name, bool enabled) async {
    if (useMockData) {
      final index = _mockZones.indexWhere((z) => z.name == name);
      if (index != -1) {
        final z = _mockZones[index];
        _mockZones[index] = AlertZone(
          name: z.name,
          latitude: z.latitude,
          longitude: z.longitude,
          radiusMeters: z.radiusMeters,
          enabled: enabled,
        );
      }
      return List.unmodifiable(_mockZones);
    }
    final response = await http.put(
      Uri.parse('$baseUrl/zones/${Uri.encodeComponent(name)}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'enabled': enabled}),
    );
    if (response.statusCode != 200) {
      throw ApiException('Échec de mise à jour de la zone (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => AlertZone.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AlertZone>> deleteZone(String name) async {
    if (useMockData) {
      _mockZones.removeWhere((z) => z.name == name);
      return List.unmodifiable(_mockZones);
    }
    final response = await http.delete(Uri.parse('$baseUrl/zones/${Uri.encodeComponent(name)}'));
    if (response.statusCode != 200) {
      throw ApiException('Échec de suppression de la zone (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => AlertZone.fromJson(e as Map<String, dynamic>)).toList();
  }

  String _zoneErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // corps non-JSON, on retombe sur le message générique ci-dessous.
    }
    return 'Échec de création de la zone (${response.statusCode})';
  }
}
