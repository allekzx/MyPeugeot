import 'dart:io';

class Trip {
  final DateTime date;
  final double distanceKm;
  final double consumptionKwh;
  final double durationMinutes;

  const Trip({
    required this.date,
    required this.distanceKm,
    required this.consumptionKwh,
    required this.durationMinutes,
  });

  /// Parsing du vrai payload `GET /vehicles/trips` de psa_car_controller
  /// (confirmé sur une e-208 réelle) : `start_at` au format RFC 1123
  /// ("Wed, 08 Jul 2026 15:49:03 GMT"), `distance` en km, `consumption` en
  /// kWh, `duration` en minutes. Pas de coût dans la réponse — PSA ne le
  /// fournit pas, donc on ne l'invente pas côté app.
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      date: HttpDate.parse(json['start_at'] as String),
      distanceKm: (json['distance'] as num).toDouble(),
      consumptionKwh: (json['consumption'] as num).toDouble(),
      durationMinutes: (json['duration'] as num).toDouble(),
    );
  }

  /// `psa_car_controller` a besoin des changements de position GPS pour
  /// découper les trajets individuels. Si le véhicule ne remonte plus sa
  /// position (mode confidentialité activé, ou module GPS en panne), tout
  /// l'historique de conduite est regroupé en un seul "trajet" de plusieurs
  /// jours — un trajet de plus de 3h est presque certainement ce cas, pas un
  /// vrai trajet unique, et sa conso calculée n'a pas de sens.
  bool get looksAggregated => durationMinutes > 180;
}
