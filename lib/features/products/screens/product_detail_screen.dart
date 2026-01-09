import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/models/product_model.dart';
// import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductModel _product;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _refresh();
  }

  Future<void> _refresh() async {
    final doc = await FirebaseFirestore.instance.collection(FirestoreCollections.products).doc(_product.id).get();
    if (doc.exists) {
      setState(() {
        _product = ProductModel.fromSnapshot(doc);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWarrantyActive = _product.isWarrantyValid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_product.productName.toUpperCase()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.print),
            tooltip: 'Print Reports',
            onSelected: (value) async {
              setState(() => _isLoading = true);
              try {
                if (value == 'cert') {
                   await PdfService().generateWarrantyCertificate(_product);
                } else if (value == 'history') {
                   await PdfService().generateFullProductHistory(_product);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: $e"), backgroundColor: Colors.red));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'cert',
                child: Row(children: [Icon(Icons.verified, color: Colors.green), SizedBox(width: 8), Text('Warranty Certificate')]),
              ),
              const PopupMenuItem<String>(
                value: 'history',
                child: Row(children: [Icon(Icons.history, color: Colors.blue), SizedBox(width: 8), Text('Full History Report')]),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANEL: Product Info
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildWarrantyCard(isWarrantyActive),
                const SizedBox(height: 24),
                _buildInfoSection('Product Details', [
                  'Model: ${_product.modelOrVariant}',
                  'Serial Number: ${_product.serialNumber}',
                ]),
                const Divider(),
                _buildInfoSection('Customer Info', [
                  'Name: ${_product.customerName}',
                  'Phone: ${_product.phoneNumber}',
                  'Email: ${_product.email}',
                  'Location: ${_product.location['city']}, ${_product.location['state']}',
                ]),
                const Divider(),
                _buildInfoSection('Warranty Stats', [
                  'Claims Made: ${_product.warrantyClaimCount}',
                  'Claims Rejected: ${_product.warrantyRejectedCount}',
                  'Last Claim: ${_product.lastClaimDate != null ? DateFormat('dd MMM yyyy').format(_product.lastClaimDate!) : 'Never'}',
                ]),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // RIGHT PANEL: Service History
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service History', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _product.serviceHistory.isEmpty 
                    ? const Center(child: Text('No service history found.'))
                    : ListView.builder(
                      itemCount: _product.serviceHistory.length,
                      itemBuilder: (context, index) {
                        final history = _product.serviceHistory[index];
                        final isFree = history.warrantyStatusAtService == 'in_warranty';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Ticket #${history.ticketId.substring(0, 5)}...', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Chip(
                                      label: Text(isFree ? 'WARRANTY CLAIM' : 'PAID SERVICE', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                      backgroundColor: isFree ? Colors.green : Colors.grey,
                                      padding: EdgeInsets.zero,
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(history.issueDescription, style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                const Divider(),
                                Text('Resolved: ${DateFormat('dd MMM yyyy').format(history.resolvedOn)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                if (history.partsReplacedSummary.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Parts: ${history.partsReplacedSummary}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                ],
                                const SizedBox(height: 4),
                                Text('Notes: ${history.notesSummary}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyCard(bool isActive) {
    return Card(
      color: isActive ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(isActive ? Icons.verified : Icons.warning, size: 40, color: isActive ? Colors.green : Colors.red),
            const SizedBox(height: 8),
            Text(isActive ? 'WARRANTY ACTIVE' : 'WARRANTY EXPIRED', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Valid until ${DateFormat('dd MMM yyyy').format(_product.warrantyEndDate)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        ...lines.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(l, style: const TextStyle(fontSize: 15)),
        )),
      ],
    );
  }
}
