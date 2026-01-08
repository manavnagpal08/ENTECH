import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/presales_query_model.dart';
import '../../../core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class PreSalesFormScreen extends StatefulWidget {
  final PreSalesQuery? query;

  const PreSalesFormScreen({super.key, this.query});

  @override
  State<PreSalesFormScreen> createState() => _PreSalesFormScreenState();
}

class _PreSalesFormScreenState extends State<PreSalesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _customerNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _productCtrl;
  late TextEditingController _sourceCtrl;
  late TextEditingController _slaCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _customerNameCtrl = TextEditingController(text: widget.query?.customerName ?? '');
    _phoneCtrl = TextEditingController(text: widget.query?.phoneNumber ?? '');
    _emailCtrl = TextEditingController(text: widget.query?.email ?? '');
    _productCtrl = TextEditingController(text: widget.query?.productQueryDescription ?? '');
    _sourceCtrl = TextEditingController(text: widget.query?.querySource ?? 'Manual');
    _slaCtrl = TextEditingController(text: (widget.query?.replyCommitmentDays ?? 2).toString());
    
    _companyCtrl = TextEditingController(text: widget.query?.company ?? '');
    // Handle location map safely
    final loc = widget.query?.location ?? {};
    _cityCtrl = TextEditingController(text: loc['city'] ?? '');
    _stateCtrl = TextEditingController(text: loc['state'] ?? '');
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final id = widget.query?.id ?? _uuid.v4();
    final newQuery = PreSalesQuery(
      id: id,
      querySource: _sourceCtrl.text,
      customerName: _customerNameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      email: _emailCtrl.text,
      company: _companyCtrl.text.isNotEmpty ? _companyCtrl.text : null,
      location: {
        'city': _cityCtrl.text,
        'state': _stateCtrl.text,
      },
      productQueryDescription: _productCtrl.text,
      queryReceivedDate: widget.query?.queryReceivedDate ?? DateTime.now(),
      replyCommitmentDays: int.tryParse(_slaCtrl.text) ?? 2,
      latestUpdateOn: DateTime.now(),
      latestUpdatedBy: 'Employee (Manual Entry)',
      notesThread: widget.query?.notesThread ?? [],
    );

    try {
      await FirebaseFirestore.instance.collection(FirestoreCollections.preSalesQueries).doc(id).set(newQuery.toMap());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.query == null ? 'New Inquiry' : 'Edit Inquiry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer Details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customerNameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
               TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(labelText: 'Company Name (Optional)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Inquiry Details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
               TextFormField(
                controller: _sourceCtrl,
                decoration: const InputDecoration(labelText: 'Source (Web, Phone, etc.)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productCtrl,
                decoration: const InputDecoration(labelText: 'Product Interest / Query'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Inquiry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
