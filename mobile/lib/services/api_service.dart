import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip.dart';
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

  Future<List<Trip>> fetchTrips(String vin) async {
    if (useMockData) {
      return _mockTrips();
    }
    final response = await http.get(Uri.parse('$baseUrl/api/vehicles/$vin/trips'));
    if (response.statusCode != 200) {
      throw ApiException('Échec de récupération des trajets (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

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

  List<Trip> _mockTrips() {
    final now = DateTime.now();
    return [
      Trip(date: now.subtract(const Duration(days: 1)), distanceKm: 18.4, consumptionKwh: 3.1, costEuros: 0.65),
      Trip(date: now.subtract(const Duration(days: 2)), distanceKm: 42.0, consumptionKwh: 7.6, costEuros: 1.60),
      Trip(date: now.subtract(const Duration(days: 4)), distanceKm: 9.2, consumptionKwh: 1.8, costEuros: 0.38),
      Trip(date: now.subtract(const Duration(days: 6)), distanceKm: 63.5, consumptionKwh: 11.2, costEuros: 2.35),
    ];
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
