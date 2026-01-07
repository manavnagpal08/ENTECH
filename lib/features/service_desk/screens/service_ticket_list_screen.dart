import 'service_ticket_detail_screen.dart';

//...
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceTicketDetailScreen(ticket: ticket)));
                },
//...
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../data/models/service_ticket_model.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        title: const Text('Service Helpdesk'),
        bottom: TabBar(
          controller: _tabController,
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
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceTicketForm()));
        },
        label: const Text("New Ticket"),
        icon: const Icon(Icons.add_task),
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
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No tickets found"));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final ticket = ServiceTicket.fromSnapshot(snapshot.data!.docs[index]);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: ticket.isSLABreached ? Colors.red : Colors.green,
                  child: const Icon(Icons.confirmation_number, color: Colors.white, size: 18),
                ),
                title: Text(ticket.issueDescription, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('#${ticket.id.substring(0,6)} • ${DateFormat('dd MMM').format(ticket.issueReceivedDate)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to Detail
                },
              ),
            );
          },
        );
      },
    );
  }
}
