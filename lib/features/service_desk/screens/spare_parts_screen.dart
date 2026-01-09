import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
// import '../../../core/theme/app_theme.dart';

class SparePart {
  final String id;
  final String partName;
  final String partNumber;
  final int stockQty;
  final int lowStockThreshold;

  SparePart({
    required this.id,
    required this.partName,
    required this.partNumber,
    required this.stockQty,
    this.lowStockThreshold = 5,
  });

  Map<String, dynamic> toMap() => {
    'partName': partName,
    'partNumber': partNumber,
    'stockQty': stockQty,
    'lowStockThreshold': lowStockThreshold,
  };

  factory SparePart.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SparePart(
      id: doc.id,
      partName: data['partName'] ?? '',
      partNumber: data['partNumber'] ?? '',
      stockQty: data['stockQty'] ?? 0,
      lowStockThreshold: data['lowStockThreshold'] ?? 5,
    );
  }
}

class SparePartsScreen extends StatelessWidget {
  const SparePartsScreen({super.key});

  void _addEditPart(BuildContext context, {SparePart? part}) {
    final nameCtrl = TextEditingController(text: part?.partName);
    final numCtrl = TextEditingController(text: part?.partNumber);
    final qtyCtrl = TextEditingController(text: part?.stockQty.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(part == null ? 'Add Spare Part' : 'Update Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Part Name')),
            const SizedBox(height: 10),
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Part Number')),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Stock Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              
              final data = {
                'partName': nameCtrl.text,
                'partNumber': numCtrl.text,
                'stockQty': qty,
                'lowStockThreshold': 5, // Default
              };

              final collection = FirebaseFirestore.instance.collection(FirestoreCollections.spareParts);
              
              if (part == null) {
                await collection.add(data);
              } else {
                await collection.doc(part.id).update(data);
              }
              
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spare Parts Inventory')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEditPart(context),
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, colors: [Colors.grey.shade50, Colors.white])),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(FirestoreCollections.spareParts).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns for better space usage, or use responsive layout if needed
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final part = SparePart.fromSnapshot(snapshot.data!.docs[index]);
                final isLowStock = part.stockQty <= part.lowStockThreshold;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isLowStock ? Colors.red.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.settings_input_component, color: isLowStock ? Colors.red : Colors.blue, size: 24),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _addEditPart(context, part: part),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(part.partName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('P/N: ${part.partNumber}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${part.stockQty} Units', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isLowStock ? Colors.red : Colors.grey.shade800,
                              )),
                              if (isLowStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('LOW STOCK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
