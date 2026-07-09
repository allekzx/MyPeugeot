import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

const _weekdaysFr = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _monthsFr = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _formatDateFr(DateTime date) {
  final weekday = _weekdaysFr[date.weekday - 1];
  final month = _monthsFr[date.month - 1];
  return '$weekday ${date.day} $month';
}

/// Historique des trajets + conso/coûts, relié à `GET /vehicles/trips`.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key, required this.vin});

  final String vin;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _api = ApiService(useMockData: const bool.fromEnvironment('USE_MOCK_DATA'));
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _api.fetchTrips(widget.vin);
  }

  void _refresh() => setState(() => _tripsFuture = _api.fetchTrips(widget.vin));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trajets'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return const Center(child: Text('Aucun trajet pour le moment.'));
          }

          final totalCost = trips.fold<double>(0, (sum, t) => sum + t.costEuros);
          final totalKwh = trips.fold<double>(0, (sum, t) => sum + t.consumptionKwh);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(child: _SummaryStat(label: 'Trajets', value: '${trips.length}')),
                      Expanded(child: _SummaryStat(label: 'Conso', value: '${totalKwh.toStringAsFixed(1)} kWh')),
                      Expanded(child: _SummaryStat(label: 'Coût estimé', value: '${totalCost.toStringAsFixed(2)} €')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final trip in trips)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route, size: 18, color: AppColors.goldBright),
                    ),
                    title: Text('${trip.distanceKm.toStringAsFixed(1)} km'),
                    subtitle: Text(_formatDateFr(trip.date)),
                    trailing: Text(
                      '${trip.costEuros.toStringAsFixed(2)} €\n${trip.consumptionKwh.toStringAsFixed(1)} kWh',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.paper),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.ashDim)),
      ],
    );
  }
}
