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

  /// Parsing best-effort de la réponse `GET /get_vehicleinfo/<vin>` de
  /// psa_car_controller (objet `Status` de l'API PSA connected_car v4,
  /// sérialisé en JSON). Le niveau de batterie/autonomie vient de l'entrée
  /// `energy` de type "Electric" (cf. `car.status.get_energy('Electric')`
  /// dans psa_client.py). Le statut de verrouillage (`doors_state`) n'a pas
  /// pu être confirmé avec un exemple réel : à ajuster une fois qu'on a une
  /// vraie réponse du backend (voir TODO ci-dessous).
  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as Map<String, dynamic>?) ?? json;
    final energyList = (status['energy'] as List<dynamic>?) ?? const [];
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
      vin: (json['vin'] ?? json['id'] ?? '') as String,
      batteryLevelPercent: (electric?['level'] as num?)?.toInt() ?? 0,
      rangeKm: (electric?['autonomy'] as num?)?.toInt() ?? 0,
      // TODO: confirmer le champ réel de verrouillage (doors_state) contre
      // une vraie réponse du backend. Verrouillé par défaut en attendant.
      isLocked: _parseLocked(status['doors_state']),
      isCharging: (charging?['status'] as String?)?.toLowerCase() == 'inprogress',
      updatedAt: DateTime.tryParse(
            (electric?['updated_at'] ?? electric?['updatedAt'] ?? json['updatedAt'] ?? '') as String? ?? '',
          ) ??
          DateTime.now(),
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
