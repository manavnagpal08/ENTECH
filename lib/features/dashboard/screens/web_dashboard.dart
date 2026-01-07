import '../../products/screens/product_list_screen.dart';
import '../../service_desk/screens/service_ticket_list_screen.dart';
import '../../auth/screens/admin_user_screen.dart';
import '../../service_desk/screens/spare_parts_screen.dart';
import '../screens/reminder_list_screen.dart';

// ...
  Widget _buildBody(BuildContext context) {
    if (selectedIndex == 0) return _buildOverview(context);
    if (selectedIndex == 1) return const PreSalesListScreen();
    if (selectedIndex == 2) return const ProductListScreen();
    if (selectedIndex == 3) return const ServiceTicketListScreen();
    return const SizedBox();
  }
// ...

// ... inside the class
  Widget _buildBody(BuildContext context) {
    // Basic Routing based on index
    if (selectedIndex == 0) return _buildOverview(context);
    if (selectedIndex == 1) return const PreSalesListScreen();
    // ...
import '../../../core/theme/app_theme.dart';
import '../widgets/analytics_card.dart';

class WebDashboard extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavTap;
  final VoidCallback onLogout;

  const WebDashboard({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onNavTap,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Icon(Icons.eco, color: AppColors.primary, size: 40),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: onLogout,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.question_answer_outlined),
                selectedIcon: Icon(Icons.question_answer),
                label: Text('Pre-Sales'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Products'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.support_agent_outlined),
                selectedIcon: Icon(Icons.support_agent),
                label: Text('Service Desk'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Basic Routing based on index
    if (selectedIndex == 0) return _buildOverview(context);
    if (selectedIndex == 1) return const Center(child: Text("Pre-Sales Module (Coming Next)"));
    if (selectedIndex == 2) return const Center(child: Text("Products Module (Coming Next)"));
    if (selectedIndex == 3) return const ServiceTicketListScreen();
    if (selectedIndex == 4) return const SparePartsScreen();
    if (selectedIndex == 5) return const AdminUserScreen();
    return const SizedBox();
  }

  Widget _buildOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dashboard Overview", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
              children: [
                AnalyticsCard(
                  title: 'Pending Follow-ups',
                  value: '12',
                  icon: Icons.access_time,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen())),
                ),
                AnalyticsCard(
                  title: 'SLA Due Today',
                  value: '4',
                  icon: Icons.warning_amber,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen())),
                ),
                AnalyticsCard(
                  title: 'Warranty Approvals',
                  value: '85',
                  icon: Icons.verified,
                  color: Colors.green,
                ),
                AnalyticsCard(
                  title: 'Rejection Rate',
                  value: '12%',
                  icon: Icons.thumb_down_off_alt,
                  color: Colors.grey,
                ),
                AnalyticsCard(
                  title: 'Manage Stock',
                  value: 'Parts',
                  icon: Icons.settings_input_component,
                  color: Colors.blue,
                  onTap: () => onNavTap(4),
                ),
                AnalyticsCard(
                  title: 'Admin Users',
                  value: 'Staff',
                  icon: Icons.people,
                  color: Colors.purple,
                  onTap: () => onNavTap(5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
