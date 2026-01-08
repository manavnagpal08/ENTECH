import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/models/presales_query_model.dart';
import '../../../core/constants/app_constants.dart';
import 'pre_sales_form_screen.dart';

class PreSalesDetailScreen extends StatefulWidget {
  final PreSalesQuery query;

  const PreSalesDetailScreen({super.key, required this.query});

  @override
  State<PreSalesDetailScreen> createState() => _PreSalesDetailScreenState();
}

class _PreSalesDetailScreenState extends State<PreSalesDetailScreen> {
  late PreSalesQuery _query;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query = widget.query;
  }

  Future<void> _refresh() async {
    final doc = await FirebaseFirestore.instance.collection(FirestoreCollections.preSalesQueries).doc(_query.id).get();
    if (doc.exists) {
      setState(() {
        _query = PreSalesQuery.fromSnapshot(doc);
      });
    }
  }

  void _addNote() async {
    if (_noteCtrl.text.isEmpty) return;
    
    final note = Note(
      text: _noteCtrl.text,
      addedBy: 'Manager', // Mocked as no auth
      date: DateTime.now(),
    );

    final updatedNotes = List<Note>.from(_query.notesThread)..add(note);

    await FirebaseFirestore.instance.collection(FirestoreCollections.preSalesQueries).doc(_query.id).update({
      'notesThread': updatedNotes.map((n) => n.toMap()).toList(),
      'latestUpdateOn': FieldValue.serverTimestamp(),
      'latestUpdatedBy': 'Manager',
    });

    _noteCtrl.clear();
    _refresh();
  }

  void _approveProposal() async {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Proposal internally?'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Approval Notes / Instructions'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection(FirestoreCollections.preSalesQueries).doc(_query.id).update({
                'approvalStatus': 'approved',
                'proposalApprovalDate': FieldValue.serverTimestamp(),
                'proposalApprovedBy': 'Manager',
                'proposalApprovalNotes': reasonCtrl.text,
                'latestUpdateOn': FieldValue.serverTimestamp(),
                'latestUpdatedBy': 'Manager',
              });
              _refresh();
            },
            child: const Text('Approve'),
          )
        ],
      )
    );
  }

  void _sendProposal() async {
     // Mark as Sent
     await FirebaseFirestore.instance.collection(FirestoreCollections.preSalesQueries).doc(_query.id).update({
        'proposalStatus': 'proposal_sent',
        'proposalSentDate': FieldValue.serverTimestamp(),
        'latestUpdateOn': FieldValue.serverTimestamp(),
        'latestUpdatedBy': 'Sales Rep',
     });
     _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_query.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
               await Navigator.push(context, MaterialPageRoute(builder: (_) => PreSalesFormScreen(query: _query)));
               _refresh();
            },
          )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Details
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildInfoSection('Contact Info', [
                  'Phone: ${_query.phoneNumber}',
                  'Email: ${_query.email}',
                  'Location: ${_query.location['city']}, ${_query.location['state']}',
                  'Address: ${_query.location['address'] ?? '-'}',
                ]),
                const Divider(height: 48),
                _buildInfoSection('Product Enquiry', [
                  _query.productQueryDescription,
                ]),
                const SizedBox(height: 24),
                _buildInfoSection('SLA Commitment', [
                  'Reply in: ${_query.replyCommitmentDays} Days',
                  'Message: "${_query.replyCommitmentMessage}"', 
                ]),
                const SizedBox(height: 24),
                if (_query.approvalStatus == 'approved')
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.green.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Text('✅ Internal Approval Complete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                         Text('By: ${_query.proposalApprovedBy} on ${DateFormat('dd MMM').format(_query.proposalApprovalDate!)}'),
                         const SizedBox(height: 8),
                         Text('Note: "${_query.proposalApprovalNotes}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right: Timeline/Notes
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Activity & Notes', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _query.notesThread.length,
                      itemBuilder: (ctx, i) {
                        final note = _query.notesThread[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(note.text),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(note.addedBy, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text(DateFormat('dd MMM HH:mm').format(note.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _noteCtrl, decoration: const InputDecoration(hintText: 'Add a note...'))),
                      IconButton(onPressed: _addNote, icon: const Icon(Icons.send))
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Current Status', style: TextStyle(color: Colors.grey)),
                  Text(_query.proposalStatus.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Approval Status', style: TextStyle(color: Colors.grey)),
                  Text(_query.approvalStatus.toUpperCase(), style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: _query.approvalStatus == 'approved' ? Colors.green : Colors.orange,
                  )),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_query.approvalStatus == 'pending')
                  Expanded(child: ElevatedButton(onPressed: _approveProposal, child: const Text('Approve Internally')))
                else if (_query.proposalStatus != 'proposal_sent')
                  Expanded(child: ElevatedButton(onPressed: _sendProposal, child: const Text('Mark Proposal Sent'))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        ...lines.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(l, style: const TextStyle(fontSize: 14)),
        )),
      ],
    );
  }
}
