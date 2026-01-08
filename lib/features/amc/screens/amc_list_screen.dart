import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/models/amc_model.dart';
import '../../../../core/constants/app_constants.dart';

class AmcListScreen extends StatelessWidget {
  const AmcListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AMC Management'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _createAmc(context))
      ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('amc_contracts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.handshake_outlined, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text("No Active Contracts"),
                   const SizedBox(height: 16),
                   ElevatedButton(onPressed: () => _createAmc(context), child: const Text("Create AMC"))
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final amc = AmcContract.fromSnapshot(snapshot.data!.docs[index]);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: amc.isExpired ? Colors.red.shade100 : Colors.green.shade100,
                    child: Icon(Icons.security, color: amc.isExpired ? Colors.red : Colors.green),
                  ),
                  title: Text(amc.customerName),
                  subtitle: Text('${amc.linkedProductName} (${amc.linkedSerialNumber})\nValid: ${DateFormat('MMM yyyy').format(amc.startDate)} - ${DateFormat('MMM yyyy').format(amc.endDate)}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Text('${amc.visitsCompleted}/${amc.totalVisits} Visits', style: const TextStyle(fontWeight: FontWeight.bold)),
                       const SizedBox(height: 4),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                         decoration: BoxDecoration(color: amc.status == 'active' ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(4)),
                         child: Text(amc.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                       )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _createAmc(BuildContext context) {
    // Simple placeholder for creating AMC
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AMC Creation Form coming soon! Use Firebase Console for now.')));
  }
}
