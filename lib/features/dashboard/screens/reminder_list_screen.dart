import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import '../../amc/screens/amc_list_screen.dart';
import '../../service_desk/screens/service_ticket_list_screen.dart';
import '../../pre_sales/screens/pre_sales_list_screen.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Daily Tasks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(FirestoreCollections.reminderLogs)
            .where('completionStatus', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("All caught up! No tasks."));

          final docs = snapshot.data!.docs;
          docs.sort((a, b) {
            final dateA = (a.data() as Map<String, dynamic>)['reminderDate'] as Timestamp;
            final dateB = (b.data() as Map<String, dynamic>)['reminderDate'] as Timestamp;
            return dateB.compareTo(dateA); // Descending
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final isEscalated = data['escalationStatus'] == 'escalated';
              final type = data['reminderType'] ?? 'General';
              final date = (data['reminderDate'] as Timestamp).toDate();
              final notes = data['escalationNotes'] ?? '';

              return Card(
                elevation: isEscalated ? 4 : 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  side: isEscalated ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
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
                                  isEscalated ? Icons.priority_high : Icons.notifications_active,
                                  color: isEscalated ? Colors.red : Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            if (isEscalated)
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
                              label: const Text("View Details"),
                            ),
                            const SizedBox(width: 8),
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
                            ),
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
      ),
    );
  }
}
