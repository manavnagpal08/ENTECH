import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../auth/repositories/auth_repository.dart';
import 'package:provider/provider.dart';

// Components
import 'mobile_dashboard.dart';
import 'web_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _filter;

  void _onNavTap(int index, {String? filter}) {
    setState(() {
      _selectedIndex = index;
      if (filter != null) _filter = filter;
      // If navigating away from list screens, maybe clear filter? 
      // For now, let's keep it simple. If we tap a NavRail item, we might want to clear filter.
      // But onNavTap is used by both.
      // Let's say if filter is NOT provided (direct nav tap), we clear it.
      if (filter == null) _filter = null;
    });
  }

  void _logout() {
    context.read<AuthRepository>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: MobileDashboard(
        selectedIndex: _selectedIndex,
        onNavTap: (i) => _onNavTap(i), // Mobile might just pass int for now
        onLogout: _logout,
      ),
      webScaffold: WebDashboard(
        selectedIndex: _selectedIndex,
        selectedFilter: _filter,
        onNavTap: _onNavTap, 
        onLogout: _logout,
      ),
    );
  }
}
