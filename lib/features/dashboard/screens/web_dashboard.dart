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
import '../../settings/screens/support_screen.dart';

class WebDashboard extends StatelessWidget {
  final int selectedIndex;
  final String? selectedFilter;
  final Function(int, {String? filter}) onNavTap;
  final VoidCallback onLogout;

  const WebDashboard({
    super.key,
    required this.selectedIndex,
    this.selectedFilter,
    required this.onNavTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => onNavTap(i), // Clear filter on generic nav
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            elevation: 5,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Icon(Icons.eco, color: AppColors.primary, size: 40),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: onLogout,
              ),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Overview')),
              NavigationRailDestination(icon: Icon(Icons.question_answer_outlined), selectedIcon: Icon(Icons.question_answer), label: Text('Pre-Sales')),
              NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake), label: Text('AMC')),
              NavigationRailDestination(icon: Icon(Icons.notifications_active_outlined), selectedIcon: Icon(Icons.notifications_active), label: Text('Reminders')),
              NavigationRailDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: Text('Service Desk')),
              NavigationRailDestination(icon: Icon(Icons.settings_input_component_outlined), selectedIcon: Icon(Icons.settings_input_component), label: Text('Spare Parts')),
              NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Admin')),
              NavigationRailDestination(icon: Icon(Icons.headset_mic_outlined), selectedIcon: Icon(Icons.headset_mic), label: Text('Support')),
            ],
          ),
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
    if (selectedIndex == 1) return PreSalesListScreen(initialStatus: selectedFilter);
    if (selectedIndex == 2) return const ProductListScreen();
    if (selectedIndex == 3) return const AmcListScreen();
    if (selectedIndex == 4) return const ReminderListScreen();
    if (selectedIndex == 5) return ServiceTicketListScreen(initialFilter: selectedFilter);
    if (selectedIndex == 6) return const SparePartsScreen();
    if (selectedIndex == 7) return const AdminUserManagementScreen();
    if (selectedIndex == 8) return const SupportScreen();
    return const SizedBox();
  }

  Widget _buildOverview(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome back, Verified Admin", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      Text("Here's what's happening today.", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                    ],
                  ),
                  _buildNotificationBadge(data['sla_today'] ?? 0),
                ],
              ),
              const SizedBox(height: 32),

              Text("Key Performance Indicators", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // KPI Grid
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPremiumCard('Enquiries', data['total'].toString(), Icons.contact_mail, Colors.blue, 1, context), // PreSales
                  _buildPremiumCard('Proposals Sent', data['sent'].toString(), Icons.send, Colors.orange, 1, context, filter: 'proposal_sent'),
                  _buildPremiumCard('Pending Approvals', data['approvals'].toString(), Icons.verified_user, Colors.purple, 1, context, filter: 'pending'), // Approvals usually pending status
                  _buildPremiumCard('SLA Due Today', data['sla_today'].toString(), Icons.timer_outlined, Colors.redAccent, 4, context), // Reminders
                  _buildPremiumCard('Active Warranty', data['active_warranty'].toString(), Icons.verified, Colors.green, 2, context), // Products
                  _buildPremiumCard('Open Tickets', data['open_tickets'].toString(), Icons.support_agent, Colors.blueAccent, 5, context, filter: 'Open'),
                  _buildPremiumCard('SLA Breaches', data['sla_breaches'].toString(), Icons.warning_amber_rounded, Colors.red, 5, context, filter: 'IsBreach'), 
                  _buildPremiumCard('Total Sold', data['total_products'].toString(), Icons.shopping_bag_outlined, Colors.teal, 2, context),
                ],
              ),
              
              const SizedBox(height: 32),
              // Secondary Stats Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.indigo.shade50, Colors.white]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('Warranty Claim Rate', "${data['warranty_claim_percent']}%", Colors.orange),
                    Container(height: 40, width: 1, color: Colors.grey.shade300),
                    _buildMiniStat('Expired Warranties', data['expired_warranty'].toString(), Colors.grey),
                    Container(height: 40, width: 1, color: Colors.grey.shade300),
                    _buildMiniStat('System Health', '98%', Colors.green),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumCard(String title, String value, IconData icon, Color color, int navIndex, BuildContext context, {String? filter}) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => onNavTap(navIndex, filter: filter),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withOpacity(0.05)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNotificationBadge(int count) {
    return IconButton(
      onPressed: () => onNavTap(4),
      icon: Badge(
        label: Text(count.toString()),
        isLabelVisible: count > 0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: const Icon(Icons.notifications_outlined, size: 28, color: Colors.black87),
        ),
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
      
      final now = DateTime.now();
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
         if (!d.data().containsKey('slaDueDate')) return false;
         final due = (d['slaDueDate'] as Timestamp?)?.toDate();
         final status = d['status'] ?? '';
         if (due == null || status == 'Closed') return false;
         return due.isBefore(now);
      }).length;
      
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
