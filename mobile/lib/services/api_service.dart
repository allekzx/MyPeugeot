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
///   - GET /lights/<vin>/<duration_secondes>
///   - GET /charge_control?vin=&hour=&minute=&percentage= (seuil d'arrêt %, côté serveur)
///   - GET /charge_hour?vin=&hour=&minute= (heure de démarrage, native véhicule)
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

  /// Sans timeout, une requête qui ne reçoit jamais de réponse (coupure
  /// réseau/Tailscale ponctuelle) laisse le bouton concerné bloqué en
  /// chargement indéfiniment — vécu en pratique avec le klaxon. Le serveur
  /// répond normalement en quelques secondes ; 25s laisse une marge large
  /// avant d'abandonner proprement.
  static const _requestTimeout = Duration(seconds: 25);

  Future<VehicleStatus> fetchStatus(String vin, {bool forceRefresh = false}) async {
    if (useMockData) {
      return _mockStatus(vin);
    }
    final fromCache = forceRefresh ? 0 : 1;
    final response = await http
        .get(Uri.parse('$baseUrl/get_vehicleinfo/$vin?from_cache=$fromCache'))
        .timeout(_requestTimeout, onTimeout: () => throw ApiException('Le serveur ne répond pas (délai dépassé).'));
    if (response.statusCode != 200) {
      throw ApiException('Échec de récupération du statut (${response.statusCode})');
    }
    return VehicleStatus.fromJson(vin, jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Demande à la voiture de se "réveiller" et de pousser un statut à jour
  /// vers PSA. Sans ça, `get_vehicleinfo?from_cache=0` ne fait que relire le
  /// dernier statut connu côté serveur PSA — qui ne bouge que quand la
  /// voiture communique elle-même (contact, charge, etc.) — donc un simple
  /// rafraîchissement peut sembler "ne rien faire".
  Future<void> wakeUp(String vin) => _get('/wakeup/$vin');

  Future<void> lockDoors(String vin) => _get('/lock_door/$vin/1');

  Future<void> unlockDoors(String vin) => _get('/lock_door/$vin/0');

  Future<void> startCharge(String vin) => _get('/charge_now/$vin/1');

  Future<void> stopCharge(String vin) => _get('/charge_now/$vin/0');

  Future<void> preconditionCabin(String vin) => _get('/preconditioning/$vin/1');

  Future<void> stopPreconditionCabin(String vin) => _get('/preconditioning/$vin/0');

  Future<void> honk(String vin) => _get('/horn/$vin/1');

  Future<void> flashLights(String vin, {int durationSeconds = 5}) =>
      _get('/lights/$vin/$durationSeconds');

  Future<void> updateChargeControl(
    String vin, {
    required int hour,
    required int minute,
    required int percentage,
  }) =>
      _get('/charge_control?vin=$vin&hour=$hour&minute=$minute&percentage=$percentage');

  /// Programme l'heure de démarrage de charge directement dans la voiture
  /// (native PSA, via `remote_client.change_charge_hour`) — contrairement à
  /// `updateChargeControl` qui pilote un seuil d'arrêt en % *côté serveur*
  /// (psa_car_controller doit tourner et surveiller pour l'appliquer), le
  /// démarrage programmé ici est géré nativement par le véhicule, donc plus
  /// fiable (visible dans le payload réel sous `next_delayed_time`).
  Future<void> updateChargeHour(String vin, {required int hour, required int minute}) =>
      _get('/charge_hour?vin=$vin&hour=$hour&minute=$minute');

  Future<List<Trip>> fetchTrips(String vin) async {
    if (useMockData) {
      return _mockTrips();
    }
    // /vehicles/trips ne prend pas de vin dans l'URL (confirmé : le backend
    // ne gère qu'un seul véhicule à la fois côté serveur). Réponse réelle
    // confirmée : liste JSON directe (voir Trip.fromJson).
    final response = await http
        .get(Uri.parse('$baseUrl/vehicles/trips'))
        .timeout(_requestTimeout, onTimeout: () => throw ApiException('Le serveur ne répond pas (délai dépassé).'));
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
    final response = await http
        .get(Uri.parse('$baseUrl$path'))
        .timeout(_requestTimeout, onTimeout: () => throw ApiException('Le serveur ne répond pas (délai dépassé).'));
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
      isPreconditioning: false,
      updatedAt: DateTime.now(),
      odometerKm: 42894,
      latitude: 48.8584,
      longitude: 2.2945,
      positionUpdatedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    );
  }

  List<Trip> _mockTrips() {
    final now = DateTime.now();
    return [
      Trip(date: now.subtract(const Duration(days: 1)), distanceKm: 18.4, consumptionKwh: 3.1, durationMinutes: 22),
      Trip(date: now.subtract(const Duration(days: 2)), distanceKm: 42.0, consumptionKwh: 7.6, durationMinutes: 48),
      Trip(date: now.subtract(const Duration(days: 4)), distanceKm: 9.2, consumptionKwh: 1.8, durationMinutes: 14),
      Trip(date: now.subtract(const Duration(days: 6)), distanceKm: 63.5, consumptionKwh: 11.2, durationMinutes: 55),
    ];
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
