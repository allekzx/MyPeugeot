class Trip {
  final DateTime date;
  final double distanceKm;
  final double consumptionKwh;
  final double costEuros;

  const Trip({
    required this.date,
    required this.distanceKm,
    required this.consumptionKwh,
    required this.costEuros,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      date: DateTime.parse(json['date'] as String),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      consumptionKwh: (json['consumptionKwh'] as num).toDouble(),
      costEuros: (json['costEuros'] as num).toDouble(),
    );
  }
}
