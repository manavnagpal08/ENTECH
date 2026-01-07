import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../data/models/service_ticket_model.dart';
import '../../data/models/product_model.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/logic_engines.dart';

class ServiceTicketDetailScreen extends StatefulWidget {
  final ServiceTicket ticket;

  const ServiceTicketDetailScreen({super.key, required this.ticket});

  @override
  State<ServiceTicketDetailScreen> createState() => _ServiceTicketDetailScreenState();
}

class _ServiceTicketDetailScreenState extends State<ServiceTicketDetailScreen> {
  final PdfService _pdfService = PdfService();
  final _summaryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  ProductModel? _linkedProduct;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  void _loadProduct() async {
    // In a real app we'd query by serial number, assuming unique
    final snapshot = await FirebaseFirestore.instance
        .collection(FirestoreCollections.products)
        .where('serialNumber', isEqualTo: widget.ticket.linkedSerialNumber)
        .limit(1)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _linkedProduct = ProductModel.fromSnapshot(snapshot.docs.first);
        });
      }
    }
  }

  void _closeTicket() async {
    if (_summaryCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary required to close')));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // 1. Generate Merged Notes
      final mergedNotes = NotesMerger.generateSummary(
        threadNotes: [], // Fetch real notes if implemented
        serviceNotes: '${_summaryCtrl.text}\n${_notesCtrl.text}',
      );

      // 2. Update Ticket Status
      await FirebaseFirestore.instance.collection(FirestoreCollections.serviceTickets).doc(widget.ticket.id).update({
        'status': 'closed',
        'finalServiceSummary': _summaryCtrl.text,
        'mergedNotesSummary': mergedNotes,
      });

      // 3. Update Product History & Counters
      if (_linkedProduct != null) {
        final historyItem = ServiceHistoryItem(
          ticketId: widget.ticket.id,
          issueDescription: widget.ticket.issueDescription,
          resolvedOn: DateTime.now(),
          partsReplacedSummary: widget.ticket.usedParts.map((p) => '${p.qty}x ${p.partName}').join(', '),
          notesSummary: mergedNotes,
        );
        
        // Use arrayUnion for robust history append
        // Increment warrantyClaimCount if free service (assuming in_warranty)
        final isWarrantyClaim = widget.ticket.warrantyStatus == 'in_warranty';

        await FirebaseFirestore.instance.collection(FirestoreCollections.products).doc(_linkedProduct!.id).update({
          'serviceHistory': FieldValue.arrayUnion([historyItem.toMap()]),
          'warrantyClaimCount': FieldValue.increment(isWarrantyClaim ? 1 : 0),
          'lastClaimDate': FieldValue.serverTimestamp(),
        });
      }

      // 4. Generate & Save PDF (Mocking the save simply by generating it to open/share)
      if (_linkedProduct != null) {
         // Re-fetch ticket with updated data for PDF
         final updatedTicket = ServiceTicket(
            id: widget.ticket.id,
            linkedSerialNumber: widget.ticket.linkedSerialNumber,
            issueDescription: widget.ticket.issueDescription,
            issueReceivedDate: widget.ticket.issueReceivedDate,
            status: 'closed',
            assignedEmployeeId: widget.ticket.assignedEmployeeId,
            assignedEmployeeName: widget.ticket.assignedEmployeeName,
            finalServiceSummary: _summaryCtrl.text,
            mergedNotesSummary: mergedNotes,
            warrantyStatus: widget.ticket.warrantyStatus,
            usedParts: widget.ticket.usedParts,
         );
         await _pdfService.generateServiceTicketReport(updatedTicket, _linkedProduct!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket Closed & Report Generated')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.ticket.status == 'closed';

    return Scaffold(
      appBar: AppBar(title: Text('Ticket #${widget.ticket.id.substring(0, 6)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            const Text('Issue Details', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.ticket.issueDescription),
            const SizedBox(height: 16),
            if (_linkedProduct != null) ...[
               const Text('Linked Product', style: TextStyle(fontWeight: FontWeight.bold)),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: Text(_linkedProduct!.productName),
                 subtitle: Text('SN: ${_linkedProduct!.serialNumber}'),
                 trailing: Chip(label: Text(widget.ticket.warrantyStatus)),
               ),
            ],
            const Divider(),
            const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
            // Add Part Button would go here
            if (widget.ticket.usedParts.isNotEmpty)
               ...widget.ticket.usedParts.map((p) => ListTile(
                 title: Text(p.partName),
                 trailing: Text('Qty: ${p.qty}'),
                 leading: const Icon(Icons.settings_input_component),
               )),
             
            const SizedBox(height: 24),
            if (!isClosed) ...[
              const Text('Close Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              TextField(
                controller: _summaryCtrl,
                decoration: const InputDecoration(labelText: 'Final Service Summary', hintText: 'Describe the fix...'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Internal Notes', hintText: 'Tech notes...'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _closeTicket,
                  icon: const Icon(Icons.check_circle),
                  label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Close Ticket & Generate Report'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ] else 
              Alert(
                message: 'This ticket is closed.\nSummary: ${widget.ticket.finalServiceSummary}',
                type: 'info',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: widget.ticket.status == 'closed' ? Colors.grey.shade100 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Status: ${widget.ticket.status.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                 Text('Received: ${DateFormat('dd MMM yyyy').format(widget.ticket.issueReceivedDate)}'),
               ],
            ),
          ],
        ),
      ),
    );
  }
}

class Alert extends StatelessWidget {
  final String message;
  final String type;
  const Alert({super.key, required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: type == 'info' ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: type == 'info' ? Colors.blue.shade200 : Colors.orange.shade200),
      ),
      child: Text(message),
    );
  }
}
