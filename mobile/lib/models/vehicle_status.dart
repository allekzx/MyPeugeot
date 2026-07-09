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

  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    return VehicleStatus(
      vin: json['vin'] as String,
      batteryLevelPercent: json['batteryLevelPercent'] as int,
      rangeKm: json['rangeKm'] as int,
      isLocked: json['isLocked'] as bool,
      isCharging: json['isCharging'] as bool,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
