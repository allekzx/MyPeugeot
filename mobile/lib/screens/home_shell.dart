import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
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

  static const _items = [
    NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Accueil'),
    NavItem(icon: Icons.route_outlined, selectedIcon: Icons.route, label: 'Trajets'),
    NavItem(icon: Icons.bolt_outlined, selectedIcon: Icons.bolt, label: 'Charge'),
    NavItem(icon: Icons.notifications_outlined, selectedIcon: Icons.notifications, label: 'Alertes'),
  ];

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
      bottomNavigationBar: AppBottomNav(
        items: _items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
