import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_label.dart';

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

          final hasAggregatedTrip = trips.any((t) => t.looksAggregated);
          final totalKm = trips.fold<double>(0, (sum, t) => sum + t.distanceKm);
          final totalKwh = trips.fold<double>(0, (sum, t) => sum + t.consumptionKwh);
          final chronological = trips.reversed.toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hasAggregatedTrip)
                Card(
                  color: AppColors.surfaceAlt,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.ashDim),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'La voiture ne transmet plus sa position GPS, donc les trajets ne peuvent pas être '
                            'découpés individuellement — la conso affichée ci-dessous n\'est pas fiable tant que '
                            'ce n\'est pas résolu (vérifie le mode confidentialité de la voiture).',
                            style: TextStyle(fontSize: 12, color: AppColors.ashDim),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hasAggregatedTrip) const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(child: _SummaryStat(label: 'Trajets', value: '${trips.length}')),
                      Expanded(child: _SummaryStat(label: 'Distance', value: '${totalKm.toStringAsFixed(0)} km')),
                      Expanded(child: _SummaryStat(label: 'Conso', value: '${totalKwh.toStringAsFixed(1)} kWh')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Distance par trajet'),
                      const SizedBox(height: 14),
                      _DistanceChart(trips: chronological),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('Historique'),
              const SizedBox(height: 8),
              for (final trip in trips)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      trip.looksAggregated ? Icons.warning_amber_rounded : Icons.route,
                      color: trip.looksAggregated ? AppColors.ashDim : AppColors.goldBright,
                    ),
                    title: Text('${trip.distanceKm.toStringAsFixed(1)} km'),
                    subtitle: Text(
                      trip.looksAggregated
                          ? '${_formatDateFr(trip.date)} · agrégat non fiable'
                          : _formatDateFr(trip.date),
                    ),
                    trailing: Text(
                      '${trip.consumptionKwh.toStringAsFixed(1)} kWh',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: AppColors.paper),
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

class _DistanceChart extends StatelessWidget {
  const _DistanceChart({required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final maxDistance = trips.map((t) => t.distanceKm).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 108,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final trip in trips)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      trip.distanceKm.toStringAsFixed(0),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.ashDim),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      child: Container(
                        height: 8 + (trip.distanceKm / maxDistance) * 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.goldDim, AppColors.goldBright],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _weekdaysFr[trip.date.weekday - 1],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9.5, color: AppColors.ashDim),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
