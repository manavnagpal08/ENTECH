import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'spare_part_history_screen.dart';
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

class SparePartsScreen extends StatefulWidget {
  const SparePartsScreen({super.key});

  @override
  State<SparePartsScreen> createState() => _SparePartsScreenState();
}

class _SparePartsScreenState extends State<SparePartsScreen> {
  String _searchQuery = '';

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
      appBar: AppBar(
        title: const Text('Spare Parts Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Parts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
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
            
            final allDocs = snapshot.data!.docs;
            final filteredDocs = allDocs.where((doc) {
               final data = doc.data() as Map<String, dynamic>;
               final name = (data['partName'] ?? '').toString().toLowerCase();
               final num = (data['partNumber'] ?? '').toString().toLowerCase();
               return name.contains(_searchQuery) || num.contains(_searchQuery);
            }).toList();

            if (filteredDocs.isEmpty) {
               return const Center(child: Text("No parts found."));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Denser grid (3 columns)
                childAspectRatio: 1.0, // Square cards
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final part = SparePart.fromSnapshot(filteredDocs[index]);
                final isLowStock = part.stockQty <= part.lowStockThreshold;

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    onTap: () {
                       // Navigate to History
                       Navigator.push(context, MaterialPageRoute(builder: (_) => SparePartHistoryScreen(part: part)));
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(Icons.settings_input_component, 
                                color: isLowStock ? Colors.red : Colors.blue, 
                                size: 32
                           ),
                           const SizedBox(height: 8),
                           Text(
                             part.partName, 
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                             textAlign: TextAlign.center,
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                           ),
                           const SizedBox(height: 4),
                           Text(
                             '${part.stockQty} Qty', 
                             style: TextStyle(
                               fontWeight: FontWeight.bold, 
                               color: isLowStock ? Colors.red : Colors.green,
                               fontSize: 12,
                             ),
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
