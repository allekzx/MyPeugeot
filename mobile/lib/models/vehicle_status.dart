class VehicleStatus {
  final String vin;
  final int batteryLevelPercent;
  final int rangeKm;
  final bool isLocked;
  final bool isCharging;
  final DateTime updatedAt;

  const VehicleStatus({
    required this.vin,
    required this.batteryLevelPercent,
    required this.rangeKm,
    required this.isLocked,
    required this.isCharging,
    required this.updatedAt,
  });

  /// Parsing de la réponse `GET /get_vehicleinfo/<vin>` de psa_car_controller
  /// (objet `Status` de l'API PSA connected_car v4, confirmé sur une e-208
  /// réelle). Le batterie/autonomie vient de l'entrée `energy` de type
  /// "Electric". La réponse ne contient pas le VIN : on le passe séparément
  /// (c'est nous qui l'avons demandé dans l'URL).
  ///
  /// `doors_state` est revenu `null` sur le véhicule de test : le
  /// verrouillage n'est donc pas fiable via ce endpoint pour l'instant et
  /// reste à `true` par défaut (voir _parseLocked).
  factory VehicleStatus.fromJson(String vin, Map<String, dynamic> json) {
    final energyList = (json['energy'] as List<dynamic>?) ?? const [];
    Map<String, dynamic>? electric;
    for (final entry in energyList) {
      final map = entry as Map<String, dynamic>;
      if (map['type'] == 'Electric') {
        electric = map;
        break;
      }
    }
    electric ??= energyList.isNotEmpty ? energyList.first as Map<String, dynamic> : null;
    final charging = electric?['charging'] as Map<String, dynamic>?;

    return VehicleStatus(
      vin: vin,
      batteryLevelPercent: (electric?['level'] as num?)?.round() ?? 0,
      rangeKm: (electric?['autonomy'] as num?)?.round() ?? 0,
      isLocked: _parseLocked(json['doors_state']),
      isCharging: (charging?['status'] as String?)?.toLowerCase() == 'inprogress',
      updatedAt: DateTime.tryParse((electric?['updated_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  static bool _parseLocked(dynamic doorsState) {
    if (doorsState is Map<String, dynamic>) {
      final locked = doorsState['locked'];
      if (locked is bool) return locked;
    }
    return true;
  }
}
