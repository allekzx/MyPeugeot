import 'package:flutter/material.dart';

import 'alerts_screen.dart';
import 'charge_schedule_screen.dart';
import 'dashboard_screen.dart';
import 'trips_screen.dart';

/// Coquille de navigation principale (bottom nav) une fois "connecté".
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const vin = 'FAKEVIN0000000001';

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(vin: HomeShell.vin),
      const TripsScreen(vin: HomeShell.vin),
      const ChargeScheduleScreen(),
      const AlertsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Trajets'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Charge'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alertes'),
        ],
      ),
    );
  }
}
