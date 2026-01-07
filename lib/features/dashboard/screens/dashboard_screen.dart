import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
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

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _logout() {
    context.read<AuthRepository>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: MobileDashboard(
        selectedIndex: _selectedIndex,
        onNavTap: _onNavTap,
        onLogout: _logout,
      ),
      webScaffold: WebDashboard(
        selectedIndex: _selectedIndex,
        onNavTap: _onNavTap,
        onLogout: _logout,
      ),
    );
  }
}
