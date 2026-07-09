import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vehicle_status.dart';

/// Client HTTP vers le backend `psa_car_controller` auto-hébergé.
///
/// [useMockData] permet de développer l'UI avant d'avoir un backend
/// joignable. Les routes ci-dessous sont indicatives : à confirmer contre
/// `api_spec.md` de la version de psa_car_controller déployée (voir
/// backend/README.md) et à ajuster ici.
class ApiService {
  ApiService({
    String? baseUrl,
    this.useMockData = false,
  }) : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:5000',
            );

  final String baseUrl;
  final bool useMockData;

  Future<VehicleStatus> fetchStatus(String vin) async {
    if (useMockData) {
      return _mockStatus(vin);
    }
    final response = await http.get(Uri.parse('$baseUrl/api/vehicles/$vin/status'));
    if (response.statusCode != 200) {
      throw ApiException('Échec de récupération du statut (${response.statusCode})');
    }
    return VehicleStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> lockDoors(String vin) => _postAction(vin, 'lock');

  Future<void> unlockDoors(String vin) => _postAction(vin, 'unlock');

  Future<void> startCharge(String vin) => _postAction(vin, 'charge/start');

  Future<void> stopCharge(String vin) => _postAction(vin, 'charge/stop');

  Future<void> preconditionCabin(String vin) => _postAction(vin, 'preconditioning/start');

  Future<void> _postAction(String vin, String action) async {
    if (useMockData) {
      return;
    }
    final response = await http.post(Uri.parse('$baseUrl/api/vehicles/$vin/$action'));
    if (response.statusCode != 200) {
      throw ApiException('Action "$action" échouée (${response.statusCode})');
    }
  }

  VehicleStatus _mockStatus(String vin) {
    return VehicleStatus(
      vin: vin,
      batteryLevelPercent: 72,
      rangeKm: 210,
      isLocked: true,
      isCharging: false,
      updatedAt: DateTime.now(),
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
