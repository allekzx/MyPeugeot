import 'package:flutter_test/flutter_test.dart';
import 'package:mypeugeot/models/vehicle_status.dart';

void main() {
  test('parse un vrai payload get_vehicleinfo (e-208)', () {
    // Exemple réel renvoyé par psa_car_controller pour une e-208.
    final json = {
      "embedded": null,
      "links": {},
      "battery": {"current": null, "voltage": 91.5},
      "doors_state": null,
      "energy": [
        {
          "updated_at": "2026-07-08 15:49:03+00:00",
          "created_at": "2026-07-08 15:49:03+00:00",
          "autonomy": 240.0,
          "battery": {
            "capacity": null,
            "health": {"capacity": null, "resistance": 100.0}
          },
          "charging": {
            "charging_mode": "No",
            "charging_rate": 0,
            "next_delayed_time": "PT3H45M",
            "plugged": false,
            "remaining_time": null,
            "status": "Disconnected"
          },
          "consumption": null,
          "level": 74.0,
          "residual": null,
          "type": "Electric"
        }
      ],
      "environment": {},
      "ignition": {"type": "Stop"},
      "kinetic": {},
      "last_position": {
        "type": "Feature",
        "geometry": {
          "coordinates": [2.2945, 48.8584, 1093.0],
          "type": "Point"
        },
        "properties": {
          "heading": 341.0,
          "signal_quality": 9.0,
          "type": "Acquire",
          "updated_at": "2026-06-08 16:50:01+00:00"
        }
      },
      "preconditionning": {
        "air_conditioning": {"status": "Disabled"}
      },
      "privacy": {"state": "None"},
      "safety": null,
      "service": {"type": "Electric", "updated_at": null},
      "timed_odometer": {"updated_at": "2026-07-08 15:49:03+00:00", "mileage": 42894.1},
    };

    final status = VehicleStatus.fromJson('FAKEVIN0000000001', json);

    expect(status.vin, 'FAKEVIN0000000001');
    expect(status.batteryLevelPercent, 74);
    expect(status.rangeKm, 240);
    expect(status.isCharging, isFalse);
    expect(status.isLocked, isTrue); // doors_state absent -> valeur par défaut
    expect(status.updatedAt, DateTime.parse('2026-07-08 15:49:03+00:00'));
    expect(status.hasPosition, isTrue);
    expect(status.longitude, 2.2945);
    expect(status.latitude, 48.8584);
    expect(status.positionUpdatedAt, DateTime.parse('2026-06-08 16:50:01+00:00'));
  });
}
