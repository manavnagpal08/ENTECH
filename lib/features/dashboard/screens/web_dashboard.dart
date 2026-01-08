import 'package:flutter/material.dart';
import '../../products/screens/product_list_screen.dart';
import '../../service_desk/screens/service_ticket_list_screen.dart';
import '../../auth/screens/admin_user_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../service_desk/screens/spare_parts_screen.dart';
import '../../amc/screens/amc_list_screen.dart';
import '../screens/reminder_list_screen.dart';
import '../../pre_sales/screens/pre_sales_list_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/analytics_card.dart';
import '../../settings/screens/support_screen.dart';

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
                icon: Icon(Icons.handshake_outlined),
                selectedIcon: Icon(Icons.handshake),
                label: Text('AMC'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.notifications_active_outlined),
                selectedIcon: Icon(Icons.notifications_active),
                label: Text('Reminders'),
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
               NavigationRailDestination(
                  icon: Icon(Icons.headset_mic_outlined),
                  selectedIcon: Icon(Icons.headset_mic),
                  label: Text('Support'),
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
    if (selectedIndex == 3) return const AmcListScreen();
    if (selectedIndex == 4) return const ReminderListScreen();
    if (selectedIndex == 5) return const ServiceTicketListScreen();
    if (selectedIndex == 6) return const SparePartsScreen();
    if (selectedIndex == 7) return const AdminUserManagementScreen();
    if (selectedIndex == 8) return const SupportScreen();
    return const SizedBox();
  }

  Widget _buildOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Dashboard Overview", style: Theme.of(context).textTheme.headlineMedium),
              FutureBuilder<Map<String, int>>(
                future: _fetchDashboardStats(), 
                builder: (context, snapshot) {
                  final count = (snapshot.data?['sla_today'] ?? 0) + (snapshot.data?['sla_breaches'] ?? 0);
                  return IconButton(
                    onPressed: () => onNavTap(4), // Go to Reminders
                    icon: Badge(
                      label: Text(count.toString()),
                      isLabelVisible: count > 0,
                      child: const Icon(Icons.notifications, size: 32),
                    ),
                  );
                }
              ),
            ],
          ),
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
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen()));
                      },
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
                      onTap: () => onNavTap(2), // Products
                    ),
                    AnalyticsCard(
                      title: 'Expired Warranty',
                      value: data['expired_warranty'].toString(),
                      icon: Icons.cancel,
                      color: Colors.red.shade300,
                      onTap: () => onNavTap(2),
                    ),
                    AnalyticsCard(
                      title: 'Open Tickets',
                      value: data['open_tickets'].toString(),
                      icon: Icons.support_agent,
                      color: Colors.blueAccent,
                      onTap: () => onNavTap(5), // Service Desk (Index 5)
                    ),
                    AnalyticsCard(
                      title: 'SLA Breaches',
                      value: data['sla_breaches'].toString(),
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                    AnalyticsCard(
                      title: 'Total Products Sold',
                      value: data['total_products'].toString(),
                      icon: Icons.shopping_bag,
                      color: Colors.teal,
                      onTap: () => onNavTap(2),
                    ),
                    AnalyticsCard(
                      title: 'Warranty Claim Rate',
                      value: '${data['warranty_claim_percent']}%',
                      icon: Icons.percent,
                      color: Colors.orangeAccent,
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
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Pre-Sales Stats
      final queriesSnap = await firestore.collection(FirestoreCollections.preSalesQueries).get();
      final queries = queriesSnap.docs;
      final total = queries.length;
      final sent = queries.where((d) => d['proposalStatus'] == 'proposal_sent').length;
      final approvals = queries.where((d) => d['approvalStatus'] == 'pending').length;
      // Simple date check for SLA
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final slaToday = queries.where((d) {
         final received = (d['queryReceivedDate'] as Timestamp?)?.toDate(); 
         final days = d['replyCommitmentDays'] as int? ?? 2;
         if (received == null) return false;
         final due = received.add(Duration(days: days));
         
         return due.year == now.year && due.month == now.month && due.day == now.day;
      }).length;


      // 2. Product Warranty Stats
      final productsSnap = await firestore.collection(FirestoreCollections.products).get();
      final products = productsSnap.docs;
      final totalProducts = products.length;
      final activeWarranty = products.where((d) {
         if (!d.data().containsKey('warrantyEndDate')) return false;
         final end = (d['warrantyEndDate'] as Timestamp?)?.toDate();
         if (end == null) return false;
         return end.isAfter(DateTime.now());
      }).length;
      final expiredWarranty = totalProducts - activeWarranty;

      // 3. Service Ticket Stats
      final ticketsSnap = await firestore.collection(FirestoreCollections.serviceTickets).get();
      final tickets = ticketsSnap.docs;
      final openTickets = tickets.where((d) => (d['status'] ?? '') == 'Open').length;
      final slaBreaches = tickets.where((d) {
         // robust check
         if (!d.data().containsKey('slaDueDate')) return false;
         final due = (d['slaDueDate'] as Timestamp?)?.toDate();
         final status = d['status'] ?? '';
         if (due == null || status == 'Closed') return false;
         return due.isBefore(now);
      }).length;
      
      // 4. Claim Rate
      // Calculate based on products with history entries containing 'warranty_claim'
      // For now, simpler metric: (Total Tickets / Total Products) * 100 if > 0
      int claimPercent = 0;
      if (totalProducts > 0) {
        claimPercent = ((tickets.length / totalProducts) * 100).round();
      }

      return {
        'total': total,
        'sent': sent,
        'approvals': approvals,
        'sla_today': slaToday,
        'active_warranty': activeWarranty,
        'expired_warranty': expiredWarranty,
        'open_tickets': openTickets,
        'sla_breaches': slaBreaches,
        'total_products': totalProducts,
        'warranty_claim_percent': claimPercent,
      };
    } catch (e) {
      debugPrint('Dashboard Error: $e');
      return {
        'total': 0, 'sent': 0, 'approvals': 0, 'sla_today': 0,
        'active_warranty': 0, 'expired_warranty': 0, 'open_tickets': 0,
        'sla_breaches': 0, 'total_products': 0, 'warranty_claim_percent': 0
      };
    }
  }
}
