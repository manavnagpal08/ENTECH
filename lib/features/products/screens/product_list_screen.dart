import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'product_detail_screen.dart';
import '../../../data/models/product_model.dart';
// import '../../../core/utils/logic_engines.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add Product
        },
        label: const Text("Register Product"),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(FirestoreCollections.products).orderBy('purchaseDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final product = ProductModel.fromSnapshot(snapshot.data!.docs[index]);
              final isWarrantyValid = product.isWarrantyValid;
              
              return Card(
                child: ListTile(
                  leading: Icon(Icons.devices, color: isWarrantyValid ? Colors.green : Colors.grey),
                  title: Text(product.productName),
                  subtitle: Text('S/N: ${product.serialNumber} • ${product.customerName}'),
                  trailing: Chip(
                    label: Text(isWarrantyValid ? 'In Warranty' : 'Expired'),
                    backgroundColor: isWarrantyValid ? Colors.green.shade100 : Colors.red.shade100,
                    labelStyle: TextStyle(color: isWarrantyValid ? Colors.green.shade900 : Colors.red.shade900),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
