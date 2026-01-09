import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import '../../amc/screens/amc_list_screen.dart';
import '../../service_desk/screens/service_ticket_list_screen.dart';
import '../../pre_sales/screens/pre_sales_list_screen.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1, // Start on 'Today'
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Daily Tasks'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Yesterday'),
              Tab(text: 'Today'),
              Tab(text: 'Tomorrow'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReminderList(filterType: 'yesterday'),
            _ReminderList(filterType: 'today'),
            _ReminderList(filterType: 'tomorrow'),
          ],
        ),
      ),
    );
  }
}

class _ReminderList extends StatelessWidget {
  final String filterType;

  const _ReminderList({required this.filterType});

  void _handleNavigation(BuildContext context, String type) {
    if (type.toLowerCase().contains('amc')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AmcListScreen()));
    } else if (type.toLowerCase().contains('ticket') || type.toLowerCase().contains('service')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceTicketListScreen()));
    } else if (type.toLowerCase().contains('query') || type.toLowerCase().contains('sales')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PreSalesListScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No details available for this task.')));
    }
  }

  bool _matchesFilter(DateTime reminderDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminder = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);

    if (filterType == 'yesterday') {
      return reminder.isBefore(today); // Shows all past due as yesterday/overdue
    } else if (filterType == 'today') {
      return reminder.year == today.year && reminder.month == today.month && reminder.day == today.day;
    } else if (filterType == 'tomorrow') {
      return reminder.isAfter(today); // Shows all future
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Fetch ALL reminders to filtering completed/pending in tabs
      stream: FirebaseFirestore.instance.collection(FirestoreCollections.reminderLogs)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("All caught up! No tasks."));

        // Client-side Filter & Sort
        final docs = snapshot.data!.docs.where((doc) {
           final data = doc.data() as Map<String, dynamic>;
           final date = (data['reminderDate'] as Timestamp).toDate().toLocal();
           return _matchesFilter(date);
        }).toList();

        // Sort by date ASCENDING (Earliest due first)
        docs.sort((a, b) {
           final dateA = (a.data() as Map<String, dynamic>)['reminderDate'] as Timestamp;
           final dateB = (b.data() as Map<String, dynamic>)['reminderDate'] as Timestamp;
           return dateA.compareTo(dateB); 
        });

        if (docs.isEmpty) {
          return Center(child: Text("No tasks for $filterType."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final isEscalated = data['escalationStatus'] == 'escalated';
            final isDone = data['completionStatus'] == 'done';
            final type = data['reminderType'] ?? 'General';
            final date = (data['reminderDate'] as Timestamp).toDate();
            final notes = data['escalationNotes'] ?? '';

            return Card(
              elevation: isDone ? 0 : (isEscalated ? 4 : 1),
              color: isDone ? Colors.grey.shade100 : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                side: !isDone && isEscalated ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _handleNavigation(context, type),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDone ? Icons.check_circle : (isEscalated ? Icons.priority_high : Icons.notifications_active),
                                color: isDone ? Colors.green : (isEscalated ? Colors.red : Colors.blue),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type, 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone ? Colors.grey : Colors.black,
                                )
                              ),
                            ],
                          ),
                          if (isEscalated && !isDone)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text("OVERDUE", style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Due: ${DateFormat('EEE, dd MMM • hh:mm a').format(date)}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      if (notes.toString().isNotEmpty) ...[
                         const SizedBox(height: 8),
                         Text(notes, style: const TextStyle(fontSize: 14)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _handleNavigation(context, type), 
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text("Details"),
                          ),
                          const SizedBox(width: 8),
                          if (!isDone) 
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, 
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () {
                                FirebaseFirestore.instance.collection(FirestoreCollections.reminderLogs).doc(id).update({
                                  'completionStatus': 'done', 
                                  'completedOn': FieldValue.serverTimestamp(),
                                });
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Mark Done'),
                            )
                          else
                             const Chip(label: Text("Completed"), backgroundColor: Colors.greenAccent)
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
