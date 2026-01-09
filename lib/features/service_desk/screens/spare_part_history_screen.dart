import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'spare_parts_screen.dart'; // import for SparePart model if needed

class SparePartHistoryScreen extends StatelessWidget {
  final SparePart part;

  const SparePartHistoryScreen({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${part.partName} History')),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.settings_input_component, size: 30, color: Colors.blue),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part.partName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('P/N: ${part.partNumber}', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('Current Stock: ${part.stockQty}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // NOTE: This requires 'usedParts' in service_tickets to contain maps with 'partId' or similar. 
              // Since usedParts is an array of objects, we can't easily query deeply without composite indexes or client-side filter.
              // For now, we'll fetch recent tickets and filter client-side for robustness.
              stream: FirebaseFirestore.instance.collection(FirestoreCollections.serviceTickets)
                  .orderBy('issueReceivedDate', descending: true)
                  .limit(100) // Limit to last 100 tickets for performance
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // Client-side filtering
                final usageDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final usedParts = data['usedParts'] as List<dynamic>? ?? [];
                  // Check if any part in the list matches our part name (since name is often used as ID in simple setups)
                  // or match strictly on ID if available. Using Name for now as it's reliable in legacy data.
                  return usedParts.any((p) => p['partName'] == part.partName);
                }).toList();

                if (usageDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text("No usage history found."),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: usageDocs.length,
                  itemBuilder: (context, index) {
                     final ticketData = usageDocs[index].data() as Map<String, dynamic>;
                     final ticketId = usageDocs[index].id;
                     final date = (ticketData['issueReceivedDate'] as Timestamp).toDate();
                     final parts = ticketData['usedParts'] as List<dynamic>;
                     final thisPart = parts.firstWhere((p) => p['partName'] == part.partName);
                     final qtyUsed = thisPart['qty'] ?? 1;

                     return Card(
                       margin: const EdgeInsets.only(bottom: 12),
                       child: ListTile(
                         leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.build, color: Colors.white, size: 18)),
                         title: Text("Used in Ticket #$ticketId"),
                         subtitle: Text("Date: ${date.toString().split(' ')[0]}\nUsed: $qtyUsed Units"),
                         trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                       ),
                     );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
