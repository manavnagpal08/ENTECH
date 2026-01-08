import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/product_model.dart';
import '../../../core/constants/app_constants.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product; // If null, we are adding new

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _serialCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '12');

  DateTime _purchaseDate = DateTime.now();
  String _warrantyType = 'standard';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      // Edit Mode
      final p = widget.product!;
      _serialCtrl.text = p.serialNumber;
      _nameCtrl.text = p.productName;
      _modelCtrl.text = p.modelOrVariant;
      _customerNameCtrl.text = p.customerName;
      _phoneCtrl.text = p.phoneNumber;
      _emailCtrl.text = p.email;
      _cityCtrl.text = p.location['city'] ?? '';
      _stateCtrl.text = p.location['state'] ?? '';
      _durationCtrl.text = p.warrantyDurationMonths.toString();
      _purchaseDate = p.purchaseDate;
      _warrantyType = p.warrantyType;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final duration = int.tryParse(_durationCtrl.text) ?? 12;
      final warrantyEnd = _purchaseDate.add(Duration(days: duration * 30)); // Approx

      final newProduct = ProductModel(
        id: widget.product?.id ?? _serialCtrl.text.trim(), // Use Serial as ID or update existing
        serialNumber: _serialCtrl.text.trim(),
        productName: _nameCtrl.text.trim(),
        modelOrVariant: _modelCtrl.text.trim(),
        customerName: _customerNameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        purchaseDate: _purchaseDate,
        warrantyType: _warrantyType,
        warrantyDurationMonths: duration,
        warrantyStartDate: _purchaseDate,
        warrantyEndDate: warrantyEnd,
        location: {
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
        },
        latestUpdatedBy: 'Admin', // Mock
        latestUpdatedOn: DateTime.now(),
        // Preserve existing fields if edit
        warrantyClaimCount: widget.product?.warrantyClaimCount ?? 0,
        warrantyRejectedCount: widget.product?.warrantyRejectedCount ?? 0,
        serviceHistory: widget.product?.serviceHistory ?? [],
      );

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.products)
          .doc(newProduct.id)
          .set(newProduct.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product Saved Successfully!'))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Register New Product' : 'Edit Product'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Product Details'),
                  _buildTextField('Serial Number', _serialCtrl, required: true, enabled: widget.product == null),
                  Row(children: [
                    Expanded(child: _buildTextField('Product Name', _nameCtrl, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Model/Variant', _modelCtrl, required: true)),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('Customer Information'),
                  _buildTextField('Customer Name', _customerNameCtrl, required: true),
                  Row(children: [
                    Expanded(child: _buildTextField('Phone Number', _phoneCtrl, required: true, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Email', _emailCtrl, keyboardType: TextInputType.emailAddress)),
                  ]),
                   Row(children: [
                    Expanded(child: _buildTextField('City', _cityCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('State', _stateCtrl)),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Warranty Config'),
                  Row(
                    children: [
                       const Text('Purchase Date: '),
                       TextButton(
                         onPressed: () async {
                           final date = await showDatePicker(
                             context: context, 
                             initialDate: _purchaseDate, 
                             firstDate: DateTime(2020), 
                             lastDate: DateTime.now()
                           );
                           if (date != null) setState(() => _purchaseDate = date);
                         },
                         child: Text(_purchaseDate.toString().split(' ')[0]),
                       )
                    ],
                  ),
                  _buildTextField('Duration (Months)', _durationCtrl, keyboardType: TextInputType.number),
                  DropdownButtonFormField<String>(
                    value: _warrantyType,
                    decoration: const InputDecoration(labelText: 'Warranty Type'),
                    items: const [
                      DropdownMenuItem(value: 'standard', child: Text('Standard Warranty')),
                      DropdownMenuItem(value: 'extended', child: Text('Extended Warranty')),
                      DropdownMenuItem(value: 'no_warranty', child: Text('No Warranty')),
                    ], 
                    onChanged: (val) => setState(() => _warrantyType = val!),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProduct, 
                      child: const Text('SAVE REGISTRY')
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {
    bool required = false, TextInputType? keyboardType, bool enabled = true
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }
}
