import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/theme/app_theme.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  final PdfService _pdfService = PdfService();

  ProductDetailScreen({super.key, required this.product});

  void _generateCertificate(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Certificate...')));
      await _pdfService.generateWarrantyCertificate(product);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate Generated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.productName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Card(
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('Serial: ${product.serialNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                         Chip(
                            label: Text(product.isWarrantyValid ? 'Active' : 'Expired'),
                            backgroundColor: product.isWarrantyValid ? Colors.green.shade100 : Colors.red.shade100,
                         ),
                       ],
                     ),
                     const Divider(),
                     _buildRow('Customer', product.customerName),
                     _buildRow('Purchased', product.purchaseDate.toString().split(' ')[0]),
                     _buildRow('Warranty End', product.warrantyEndDate.toString().split(' ')[0]),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 16),
             ElevatedButton.icon(
               onPressed: () => _generateCertificate(context),
               icon: const Icon(Icons.verified_user),
               label: const Text('Download Warranty Certificate'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.secondary,
                 minimumSize: const Size(double.infinity, 48),
               ),
             ),
             const SizedBox(height: 24),
             const Text('Warranty Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             Row(
               children: [
                 Expanded(child: _buildStatCard('Claims', product.warrantyClaimCount.toString(), Colors.orange)),
                 const SizedBox(width: 8),
                 Expanded(child: _buildStatCard('Rejected', product.warrantyRejectedCount.toString(), Colors.red)),
               ],
             ),
             const SizedBox(height: 24),
             const Text('Service History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             if (product.serviceHistory.isEmpty)
                const Text('No service history available.', style: TextStyle(color: Colors.grey)),
             ...product.serviceHistory.map((h) => Card(
               margin: const EdgeInsets.only(bottom: 8),
               child: ListTile(
                 title: Text(h.issueDescription),
                 subtitle: Text('Resolved: ${h.resolvedOn.toString().split(' ')[0]}'),
                 trailing: const Icon(Icons.history),
               ),
             )),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
