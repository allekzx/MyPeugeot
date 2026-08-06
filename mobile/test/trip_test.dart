import 'package:flutter_test/flutter_test.dart';
import 'package:mypeugeot/models/trip.dart';

void main() {
  test('parse un vrai payload GET /vehicles/trips (e-208)', () {
    // Exemple réel renvoyé par psa_car_controller pour une e-208 — un seul
    // trajet couvrant un mois entier, car la voiture ne remonte plus sa
    // position GPS (segmentation cassée côté backend, cf. Trip.looksAggregated).
    final json = {
      "altitude_diff": 0,
      "consumption": 0.46,
      "consumption_by_temp": 30.0,
      "consumption_km": 0.0628072091753139,
      "distance": 732.4000000000015,
      "duration": 40329.2,
      "id": 1,
      "mileage": 43626.5,
      "positions": {
        "lat": [48.8584],
        "long": [2.2945]
      },
      "speed_average": 1.089632325957373,
      "start_at": "Wed, 08 Jul 2026 15:49:03 GMT",
    };

    final trip = Trip.fromJson(json);

    expect(trip.distanceKm, 732.4000000000015);
    expect(trip.consumptionKwh, 0.46);
    expect(trip.durationMinutes, 40329.2);
    expect(trip.date, DateTime.utc(2026, 7, 8, 15, 49, 3));
    expect(trip.looksAggregated, isTrue);
  });

  test('un trajet court n\'est pas considéré comme un agrégat', () {
    final trip = Trip(
      date: DateTime.now(),
      distanceKm: 18.4,
      consumptionKwh: 3.1,
      durationMinutes: 22,
    );
    expect(trip.looksAggregated, isFalse);
  });
}
