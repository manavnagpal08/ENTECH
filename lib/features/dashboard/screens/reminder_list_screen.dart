import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Daily Tasks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(FirestoreCollections.reminderLogs)
            .where('completionStatus', isEqualTo: 'pending') // Only show pending
            .orderBy('reminderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("All caught up! No tasks."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final id = snapshot.data!.docs[index].id;
              final isEscalated = data['escalationStatus'] == 'escalated';
              final type = data['reminderType'] ?? 'General';
              final date = (data['reminderDate'] as Timestamp).toDate();

              return Card(
                elevation: isEscalated ? 4 : 1,
                shape: RoundedRectangleBorder(
                  side: isEscalated ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    isEscalated ? Icons.priority_high : Icons.notifications_active,
                    color: isEscalated ? Colors.red : Colors.blue,
                  ),
                  title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Due: ${DateFormat('dd MMM hh:mm a').format(date)}\n${data['escalationNotes'] ?? ''}'),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () {
                      FirebaseFirestore.instance.collection(FirestoreCollections.reminderLogs).doc(id).update({
                        'completionStatus': 'done',
                        'completedOn': FieldValue.serverTimestamp(),
                      });
                    },
                    child: const Text('Mark Done'),
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
