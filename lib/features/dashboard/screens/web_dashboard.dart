import 'package:flutter/material.dart';
import '../../products/screens/product_list_screen.dart';
import '../../service_desk/screens/service_ticket_list_screen.dart';
import '../../auth/screens/admin_user_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../service_desk/screens/spare_parts_screen.dart';
import '../screens/reminder_list_screen.dart';
import '../../pre_sales/screens/pre_sales_list_screen.dart';
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
              NavigationRailDestination(
                  icon: Icon(Icons.settings_input_component_outlined),
                  selectedIcon: Icon(Icons.settings_input_component),
                  label: Text('Spare Parts'),
               ),
               NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Admin'),
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
    if (selectedIndex == 0) return _buildOverview(context);
    if (selectedIndex == 1) return const PreSalesListScreen();
    if (selectedIndex == 2) return const ProductListScreen();
    if (selectedIndex == 3) return const ServiceTicketListScreen();
    if (selectedIndex == 4) return const SparePartsScreen();
    if (selectedIndex == 5) return const AdminUserManagementScreen();
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
            child: FutureBuilder<Map<String, int>>(
              future: _fetchDashboardStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data!;
                return GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    AnalyticsCard(
                      title: 'Total Enquiries',
                      value: data['total'].toString(),
                      icon: Icons.contact_mail,
                      color: Colors.blue,
                      onTap: () => onNavTap(1),
                    ),
                    AnalyticsCard(
                      title: 'Proposals Sent',
                      value: data['sent'].toString(),
                      icon: Icons.send,
                      color: Colors.orange,
                      onTap: () => onNavTap(1),
                    ),
                    AnalyticsCard(
                      title: 'SLA Due Today',
                      value: data['sla_today'].toString(),
                      icon: Icons.timer,
                      color: Colors.redAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen())),
                    ),
                    AnalyticsCard(
                      title: 'Pending Approvals',
                      value: data['approvals'].toString(),
                      icon: Icons.verified_user,
                      color: Colors.purple,
                      onTap: () => onNavTap(1), 
                    ),
                    AnalyticsCard(
                      title: 'Active Warranty',
                      value: data['active_warranty'].toString(),
                      icon: Icons.verified,
                      color: Colors.green,
                      // onTap: () => onNavTap(2), // Products
                    ),
                    AnalyticsCard(
                      title: 'Expired Warranty',
                      value: data['expired_warranty'].toString(),
                      icon: Icons.cancel,
                      color: Colors.red.shade300,
                    ),
                    AnalyticsCard(
                      title: 'Open Tickets',
                      value: data['open_tickets'].toString(),
                      icon: Icons.support_agent,
                      color: Colors.blueAccent,
                      onTap: () => onNavTap(3), // Service Desk
                    ),
                    AnalyticsCard(
                      title: 'SLA Breaches',
                      value: data['sla_breaches'].toString(),
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Future<Map<String, int>> _fetchDashboardStats() async {
    final firestore = FirebaseFirestore.instance;
    // Note: In a real large-scale app, we would use aggregation queries or counter shards.
    // For this size, getting query snapshots is acceptable.
    
    // 1. Total Enquiries
    final totalSnap = await firestore.collection(FirestoreCollections.preSalesQueries).count().get();
    
    // 2. Proposals Sent
    final sentSnap = await firestore.collection(FirestoreCollections.preSalesQueries)
        .where('proposalStatus', isEqualTo: 'proposal_sent').count().get();

    // 3. Pending Internal Approvals
    final approvalSnap = await firestore.collection(FirestoreCollections.preSalesQueries)
        .where('approvalStatus', isEqualTo: 'pending').count().get();

    // 4. SLA Due Today
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final reminderSnap = await firestore.collection(FirestoreCollections.reminderLogs)
        .where('reminderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('reminderType', isEqualTo: 'Pre-Sales Reply Deadline Today')
        .count().get();

    // 5. Active Warranties (Client-side filter for now, ideally backend count)
    // Querying all products is heavy, but for < 1000 items it's okay.
    // Better: maintain a counter in a 'stats' document.
    final pSnap = await firestore.collection(FirestoreCollections.products).get();
    int activeWarranty = 0;
    int expiredWarranty = 0;
    final now = DateTime.now();
    for(var doc in pSnap.docs) {
       final end = (doc['warrantyEndDate'] as Timestamp).toDate();
       if (end.isAfter(now)) {
         activeWarranty++;
       } else {
         expiredWarranty++;
       }
    }

    // 6. Open Tickets & SLA Breaches
    final openTicketsSnap = await firestore.collection(FirestoreCollections.serviceTickets)
       .where('status', whereIn: ['open', 'in_progress']).get();
    
    int openTicketsCount = openTicketsSnap.docs.length;
    int slaBreaches = 0;

    for (var doc in openTicketsSnap.docs) {
      final data = doc.data();
      final receivedDate = (data['issueReceivedDate'] as Timestamp).toDate();
      final slaDays = data['serviceSLAReplyDays'] as int? ?? 2; // Default 2 days
      
      final deadline = receivedDate.add(Duration(days: slaDays));
      if (DateTime.now().isAfter(deadline)) {
        slaBreaches++;
      }
    }

    return {
      'total': totalSnap.count ?? 0,
      'sent': sentSnap.count ?? 0,
      'approvals': approvalSnap.count ?? 0,
      'sla_today': reminderSnap.count ?? 0,
      'active_warranty': activeWarranty,
      'expired_warranty': expiredWarranty,
      'open_tickets': openTicketsCount,
      'sla_breaches': slaBreaches,
    };
  }
}
