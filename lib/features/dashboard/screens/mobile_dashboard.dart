import 'package:flutter/material.dart';
import '../../products/screens/product_list_screen.dart';
import '../../pre_sales/screens/pre_sales_list_screen.dart';
import '../../service_desk/screens/service_ticket_list_screen.dart';
import '../../auth/screens/admin_user_screen.dart';
import '../../service_desk/screens/spare_parts_screen.dart';
import '../screens/reminder_list_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/analytics_card.dart';

class MobileDashboard extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavTap;
  final VoidCallback onLogout;

  const MobileDashboard({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envirotech'),
        backgroundColor: AppColors.surface,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.eco, color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text('Envirotech System', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
              selected: selectedIndex == 0,
              onTap: () {
                onNavTap(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text('Pre-Sales Queries'),
              selected: selectedIndex == 1,
              onTap: () {
                onNavTap(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Products & Warranty'),
              selected: selectedIndex == 2,
              onTap: () {
                onNavTap(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Service Helpdesk'),
              selected: selectedIndex == 3,
              onTap: () {
                onNavTap(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_input_component),
              title: const Text('Spare Parts'),
              selected: selectedIndex == 4,
              onTap: () {
                onNavTap(4);
                Navigator.pop(context);
              },
            ),
             ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Admin Users'),
              selected: selectedIndex == 5,
              onTap: () {
                onNavTap(5);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: onLogout,
            ),
          ],
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (selectedIndex == 0) return _buildOverview(context);
    if (selectedIndex == 1) return const PreSalesListScreen();
    if (selectedIndex == 2) return const ProductListScreen();
    if (selectedIndex == 3) return const ServiceTicketListScreen();
    if (selectedIndex == 4) return const SparePartsScreen();
    if (selectedIndex == 5) return const AdminUserScreen();
    return const SizedBox();
  }

  Widget _buildOverview(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Daily Snapshot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: AnalyticsCard(
            title: 'Pending Follow-ups',
            value: '12',
            icon: Icons.access_time,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen())),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: AnalyticsCard(
            title: 'SLA Due Today',
            value: '4',
            icon: Icons.warning_amber,
            color: Colors.red,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen())),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: AnalyticsCard(
            title: 'Warranty Approvals',
            value: '85',
            icon: Icons.verified,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}
