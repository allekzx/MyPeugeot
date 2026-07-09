import 'package:flutter/material.dart';

class BatteryGauge extends StatelessWidget {
  const BatteryGauge({
    super.key,
    required this.percent,
    required this.rangeKm,
  });

  final int percent;
  final int rangeKm;

  @override
  Widget build(BuildContext context) {
    final color = percent > 50
        ? Colors.green
        : percent > 20
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 16,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$percent %  ·  ~$rangeKm km',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
