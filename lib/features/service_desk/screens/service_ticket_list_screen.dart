import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/service_ticket_model.dart';
import 'package:intl/intl.dart';
import 'service_ticket_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_ticket_form.dart';
import '../../../core/theme/app_theme.dart';

class ServiceTicketListScreen extends StatefulWidget {
  const ServiceTicketListScreen({super.key});

  @override
  State<ServiceTicketListScreen> createState() => _ServiceTicketListScreenState();
}

class _ServiceTicketListScreenState extends State<ServiceTicketListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Helpdesk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(['open']),
          _buildList(['in_progress']),
          _buildList(['closed', 'resolved']),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceTicketForm()));
        },
        label: const Text("New Ticket"),
        icon: const Icon(Icons.add_task),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildList(List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(FirestoreCollections.serviceTickets)
          .where('status', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text("No tickets found", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ticket = ServiceTicket.fromSnapshot(snapshot.data!.docs[index]);
            return _buildTicketCard(ticket);
          },
        );
      },
    );
  }

  Widget _buildTicketCard(ServiceTicket ticket) {
    // Determine color based on status/SLA
    Color statusColor = Colors.blue;
    if (ticket.status == 'closed') statusColor = Colors.grey;
    else if (ticket.isSLABreached) statusColor = Colors.red;
    else if (ticket.status == 'in_progress') statusColor = Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceTicketDetailScreen(ticket: ticket))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Strip
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${ticket.id.substring(0, 8)}',
                          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        if (ticket.isSLABreached && ticket.status != 'closed')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('SLA BREACH', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.issueDescription.split('\n').first, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Linked SN: ${ticket.linkedSerialNumber} • ${DateFormat('dd MMM').format(ticket.issueReceivedDate)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              
              // Icon
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
