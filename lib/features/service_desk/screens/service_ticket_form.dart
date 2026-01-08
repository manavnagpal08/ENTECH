import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/service_ticket_model.dart';
import '../../../../data/models/product_model.dart';
import 'package:uuid/uuid.dart';

class ServiceTicketForm extends StatefulWidget {
  const ServiceTicketForm({super.key});

  @override
  State<ServiceTicketForm> createState() => _ServiceTicketFormState();
}

class _ServiceTicketFormState extends State<ServiceTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _serialCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _isProductFound = false;
  ProductModel? _selectedProduct;

  Future<void> _searchProduct() async {
    final serial = _serialCtrl.text.trim();
    if (serial.isEmpty) return;

    setState(() => _isLoading = true);
    final snap = await FirebaseFirestore.instance.collection(FirestoreCollections.products)
        .where('serialNumber', isEqualTo: serial).get();
    
    if (snap.docs.isNotEmpty) {
      final p = ProductModel.fromSnapshot(snap.docs.first);
      setState(() {
        _selectedProduct = p;
        _isProductFound = true;
        _customerCtrl.text = p.customerName;
        _phoneCtrl.text = p.phoneNumber;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product not found! Register it first.")));
      setState(() {
        _selectedProduct = null;
        _isProductFound = false;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please search and verify a product first.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final id = const Uuid().v4();
      final newTicket = ServiceTicket(
        id: id,
        linkedSerialNumber: _selectedProduct!.serialNumber,
        issueDescription: "${_descCtrl.text}\n\nContact: ${_customerCtrl.text} (${_phoneCtrl.text})",
        issueReceivedDate: DateTime.now(),
        status: 'open',
        assignedEmployeeId: 'unassigned',
        assignedEmployeeName: 'Unassigned',
        actions: [],
        usedParts: [],
        serviceSLAReplyDays: 2,
        warrantyStatus: (_selectedProduct?.isWarrantyValid ?? false) ? 'in_warranty' : 'out_of_warranty',
      );

      await FirebaseFirestore.instance.collection(FirestoreCollections.serviceTickets).doc(id).set(newTicket.toMap());
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ticket Created Successfully")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Service Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("1. Identify Product", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                   Expanded(
                     child: TextFormField(
                       controller: _serialCtrl,
                       decoration: const InputDecoration(
                         labelText: "Enter Serial Number",
                         border: OutlineInputBorder(),
                         hintText: "e.g. SN-2026-001"
                       ),
                     ),
                   ),
                   const SizedBox(width: 16),
                   ElevatedButton(
                     onPressed: _searchProduct, 
                     child: _isLoading && !_isProductFound ? const CircularProgressIndicator() : const Text("Verify")
                   )
                ],
              ),
              if (_isProductFound) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.withOpacity(0.1),
                  child: Column(
                    children: [
                      Text("Product Verified: ${_selectedProduct!.productName}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      Text("Warranty: ${_selectedProduct!.warrantyType.toUpperCase()}"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text("2. Issue Details", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerCtrl,
                  decoration: const InputDecoration(labelText: "Contact Person"),
                ),
                 TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: "Contact Phone"),
                ),
                 const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Issue Description", 
                    border: OutlineInputBorder(),
                    hintText: "Describe the fault..."
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, 
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitTicket,
                    child: _isLoading ? const CircularProgressIndicator() : const Text("CREATE TICKET"),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
