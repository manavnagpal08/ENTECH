import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/models/amc_model.dart';
import '../../../core/theme/app_theme.dart';

class AmcCreateScreen extends StatefulWidget {
  const AmcCreateScreen({super.key});

  @override
  State<AmcCreateScreen> createState() => _AmcCreateScreenState();
}

class _AmcCreateScreenState extends State<AmcCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // Product Name
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  int _durationYears = 1;
  int _visitsPerYear = 4;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New AMC Contract')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Contract Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildTextField('Linked Serial No.', _serialCtrl, icon: Icons.qr_code)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildTextField('Product Name', _nameCtrl, icon: Icons.inventory)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Customer Name', _customerCtrl, icon: Icons.person),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', _phoneCtrl, icon: Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              
              const Text("Terms & Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDate: _startDate);
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.date_range)),
                        child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _durationYears,
                      decoration: const InputDecoration(labelText: 'Duration (Years)', border: OutlineInputBorder()),
                      items: [1, 2, 3, 5].map((e) => DropdownMenuItem(value: e, child: Text('$e Year(s)'))).toList(),
                      onChanged: (v) => setState(() => _durationYears = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
               Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _visitsPerYear,
                      decoration: const InputDecoration(labelText: 'Visits Per Year', border: OutlineInputBorder()),
                      items: [1, 2, 3, 4, 6, 12].map((e) => DropdownMenuItem(value: e, child: Text('$e Visits'))).toList(),
                      onChanged: (v) => setState(() => _visitsPerYear = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Amount (₹)', _amountCtrl, icon: Icons.currency_rupee, keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Contract'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {IconData? icon, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final endDate = DateTime(_startDate.year + _durationYears, _startDate.month, _startDate.day);
      final id = 'AMC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      final contract = AmcContract(
        id: id,
        linkedSerialNumber: _serialCtrl.text,
        linkedProductName: _nameCtrl.text,
        customerName: _customerCtrl.text,
        phoneNumber: _phoneCtrl.text,
        startDate: _startDate,
        endDate: endDate,
        totalVisits: _visitsPerYear * _durationYears,
        contractAmount: double.tryParse(_amountCtrl.text) ?? 0,
      );

      await FirebaseFirestore.instance.collection('amc_contracts').doc(id).set(contract.toMap());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract Created Successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
