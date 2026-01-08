import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/models/service_ticket_model.dart';
import '../repositories/post_sales_repository.dart';
import '../screens/spare_parts_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_service.dart';
import '../../../data/models/product_model.dart';

class ServiceTicketDetailScreen extends StatefulWidget {
  final ServiceTicket ticket;

  const ServiceTicketDetailScreen({super.key, required this.ticket});

  @override
  State<ServiceTicketDetailScreen> createState() => _ServiceTicketDetailScreenState();
}

class _ServiceTicketDetailScreenState extends State<ServiceTicketDetailScreen> with SingleTickerProviderStateMixin {
  late ServiceTicket _ticket;
  late TabController _tabController;
  final PostSalesRepository _repo = PostSalesRepository();

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _refresh() async {
    final doc = await FirebaseFirestore.instance.collection(FirestoreCollections.serviceTickets).doc(_ticket.id).get();
    if (doc.exists) {
      if (mounted) setState(() => _ticket = ServiceTicket.fromSnapshot(doc));
    }
  }

  // Helper to get current user name
  String get _currentUserName {
    // In a real app with Auth Provider:
    // final user = Provider.of<AuthProvider>(context, listen: false).user;
    // return user?.displayName ?? 'Unknown User';
    // For now, allow dynamic input or default to 'Service Tech'
    return 'Service Tech'; 
  }

  void _addPart() async {
    // Determine which part to add (Basic selector logic)
    // In real app, open a picker from SpareParts collection
    final partsSnap = await FirebaseFirestore.instance.collection(FirestoreCollections.spareParts).limit(50).get();
    final parts = partsSnap.docs.map((d) => SparePart.fromSnapshot(d)).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        SparePart? selectedPart;
        final qtyCtrl = TextEditingController(text: '1');
        return AlertDialog(
          title: const Text('Add Part Replacement'),
          content: StatefulBuilder(
            builder: (context, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<SparePart>(
                  value: selectedPart,
                  hint: const Text('Select Part'),
                  isExpanded: true,
                  items: parts.map((p) => DropdownMenuItem(value: p, child: Text('${p.partName} (Stock: ${p.stockQty})'))).toList(),
                  onChanged: (v) => setSt(() => selectedPart = v),
                ),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                 if (selectedPart == null) return;
                 try {
                   await _repo.addPartToTicket(_ticket.id, selectedPart!, int.parse(qtyCtrl.text), _currentUserName);
                   if (context.mounted) Navigator.pop(ctx);
                   _refresh();
                 } catch (e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                 }
              },
              child: const Text('Add'),
            )
          ],
        );
      }
    );
  }

  void _closeTicket() {
    final summaryCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Ticket'),
        content: TextField(
          controller: summaryCtrl,
          decoration: const InputDecoration(labelText: 'Final Service Summary (Mandatory)', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (summaryCtrl.text.isEmpty) return;
              await _repo.closeTicket(_ticket, summaryCtrl.text, _currentUserName);
              if (context.mounted) Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('Confirm Close'),
          )
        ],
      )
    );
  }

  void _generatePDF() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
    try {
      ProductModel? product;
      if (_ticket.linkedSerialNumber.isNotEmpty) {
         final pDoc = await FirebaseFirestore.instance.collection(FirestoreCollections.products)
             .where('serialNumber', isEqualTo: _ticket.linkedSerialNumber).get();
         if (pDoc.docs.isNotEmpty) {
           product = ProductModel.fromSnapshot(pDoc.docs.first);
         }
      }
      
      // Fallback if product not found/linked
      if (product == null) {
        product = ProductModel(
          id: 'unknown',
          serialNumber: _ticket.linkedSerialNumber,
          productName: 'Unknown Product',
          modelOrVariant: '-',
          customerName: 'Unknown Customer',
          phoneNumber: '-',
          email: '-',
          purchaseDate: DateTime.now(),
          warrantyStartDate: DateTime.now(),
          warrantyEndDate: DateTime.now(),
        );
      }

      await PdfService().generateServiceTicketReport(_ticket, product);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${_ticket.id.substring(0, 6)}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Parts & Actions'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(),
          _buildPartsAndActions(),
          _buildFeedback(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Status', _ticket.status.toUpperCase(), 
          color: _ticket.status == 'closed' ? Colors.green : Colors.orange),
        const SizedBox(height: 16),
        _buildInfoCard('Warranty', _ticket.warrantyStatus == 'in_warranty' ? 'IN WARRANTY (FREE)' : 'OUT OF WARRANTY (PAID)',
          color: _ticket.warrantyStatus == 'in_warranty' ? Colors.green : Colors.red),
         const SizedBox(height: 16),
        const Text('Issue Description', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(_ticket.issueDescription, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        if (_ticket.status != 'closed')
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(onPressed: _closeTicket, icon: const Icon(Icons.check), label: const Text('Close Ticket'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: _generatePDF, icon: const Icon(Icons.print), label: const Text('Report PDF'))),
            ],
          )
        else 
           OutlinedButton.icon(onPressed: _generatePDF, icon: const Icon(Icons.print), label: const Text('Download Final Report')),
      ],
    );
  }

  Widget _buildPartsAndActions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Replaced Parts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_ticket.status != 'closed') SmallButton(text: '+ Add Part', onPressed: _addPart),
          ],
        ),
        ..._ticket.usedParts.map((p) => ListTile(
          title: Text(p.partName),
          subtitle: Text('Replaced on ${DateFormat('dd MMM').format(p.replacedOn)}'),
          trailing: Text('Qty: ${p.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
        )),
        const Divider(),
        const Text('Action Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ..._ticket.actions.map((a) => ListTile(
          title: Text(a.action),
          subtitle: Text('${a.employeeName} • ${DateFormat('dd MMM HH:mm').format(a.date)}'),
        )),
      ],
    );
  }

  Widget _buildFeedback() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_ticket.status != 'closed')
            const Center(child: Text('Feedback is collected after ticket closure.'))
          else if (_ticket.rating != null)
             Column(
               children: [
                 const Icon(Icons.star, size: 48, color: Colors.amber),
                 Text('${_ticket.rating} / 5', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 Text('"${_ticket.feedbackText}"', style: const TextStyle(fontStyle: FontStyle.italic)),
               ],
             )
          else
            ElevatedButton(
              onPressed: () {
                // Show feedback dialog
                int rating = 5;
                final txtCtrl = TextEditingController();
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Collect Feedback'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Rate 1-5'),
                      TextField(controller: txtCtrl, decoration: const InputDecoration(labelText: 'Comments')),
                    ],
                  ),
                  actions: [
                     ElevatedButton(onPressed: () async {
                       await _repo.submitFeedback(_ticket.id, rating, txtCtrl.text);
                       if (context.mounted) {
                         Navigator.pop(ctx);
                         _refresh();
                       }
                     }, child: const Text('Submit'))
                  ],
                ));
              }, 
              child: const Text('Record Customer Feedback')
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, {Color color = Colors.blue}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class SmallButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const SmallButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(backgroundColor: Colors.blue.shade50),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
