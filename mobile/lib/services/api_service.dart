import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip.dart';
import '../models/vehicle_status.dart';

/// Client HTTP vers le backend `psa_car_controller` auto-hébergé.
///
/// Routes confirmées depuis le code source de `psa_car_controller`
/// (`psa_car_controller/web/view/api.py`, GET uniquement, paramètres dans
/// l'URL) :
///   - GET /get_vehicleinfo/<vin>?from_cache=0|1
///   - GET /lock_door/<vin>/<0|1>
///   - GET /charge_now/<vin>/<0|1>
///   - GET /preconditioning/<vin>/<0|1>
///   - GET /vehicles/trips (pas de vin dans l'URL, à confirmer si filtré côté
///     serveur ou s'il faut filtrer côté client)
///
/// [useMockData] permet de développer l'UI sans backend joignable.
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

  Future<VehicleStatus> fetchStatus(String vin, {bool forceRefresh = false}) async {
    if (useMockData) {
      return _mockStatus(vin);
    }
    final fromCache = forceRefresh ? 0 : 1;
    final response = await http.get(Uri.parse('$baseUrl/get_vehicleinfo/$vin?from_cache=$fromCache'));
    if (response.statusCode != 200) {
      throw ApiException('Échec de récupération du statut (${response.statusCode})');
    }
    return VehicleStatus.fromJson(vin, jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> lockDoors(String vin) => _get('/lock_door/$vin/1');

  Future<void> unlockDoors(String vin) => _get('/lock_door/$vin/0');

  Future<void> startCharge(String vin) => _get('/charge_now/$vin/1');

  Future<void> stopCharge(String vin) => _get('/charge_now/$vin/0');

  Future<void> preconditionCabin(String vin) => _get('/preconditioning/$vin/1');

  Future<void> honk(String vin) => _get('/horn/$vin/1');

  Future<void> updateChargeControl(
    String vin, {
    required int hour,
    required int minute,
    required int percentage,
  }) =>
      _get('/charge_control?vin=$vin&hour=$hour&minute=$minute&percentage=$percentage');

  Future<List<Trip>> fetchTrips(String vin) async {
    if (useMockData) {
      return _mockTrips();
    }
    // TODO: /vehicles/trips ne prend pas de vin dans les routes trouvées ;
    // à vérifier si un filtrage par véhicule est nécessaire côté client une
    // fois qu'on a un exemple réel de réponse.
    final response = await http.get(Uri.parse('$baseUrl/vehicles/trips'));
    if (response.statusCode != 200) {
      throw ApiException('Échec de récupération des trajets (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final list = decoded is List ? decoded : (decoded as Map<String, dynamic>)['trips'] as List<dynamic>? ?? [];
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET générique pour les actions véhicule. `psa_car_controller` répond
  /// parfois 200 avec un message d'erreur/rate-limit *dans* le corps JSON
  /// plutôt qu'avec un code HTTP d'erreur — on inspecte donc aussi le corps
  /// pour ne pas afficher un faux succès quand la voiture a en fait refusé
  /// la commande (cf. commandes PSA connues pour être peu fiables :
  /// github.com/flobz/psa_car_controller/issues/1162).
  Future<void> _get(String path) async {
    if (useMockData) {
      return;
    }
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode != 200) {
      throw ApiException('Action "$path" échouée (${response.statusCode}) : ${response.body}');
    }
    final lower = response.body.toLowerCase();
    final looksLikeError = lower.contains('"error"') ||
        lower.contains('ratelimit') ||
        lower.contains('rate limit') ||
        lower.contains('exception') ||
        lower.contains('"success":false') ||
        lower.contains('failed');
    if (looksLikeError) {
      throw ApiException('Le véhicule a refusé la commande : ${response.body}');
    }
  }

  VehicleStatus _mockStatus(String vin) {
    return VehicleStatus(
      vin: vin,
      batteryLevelPercent: 74,
      rangeKm: 240,
      isLocked: true,
      isCharging: false,
      updatedAt: DateTime.now(),
      odometerKm: 42894,
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
