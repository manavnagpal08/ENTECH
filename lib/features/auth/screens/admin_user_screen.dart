import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import 'package:uuid/uuid.dart';

class AdminUserScreen extends StatelessWidget {
  const AdminUserScreen({super.key});

  void _addUser(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'employee');
    const uuid = Uuid();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (admin/employee)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty) return;
              
              final id = uuid.v4();
              final newUser = UserModel(
                uid: id,
                email: emailCtrl.text,
                name: nameCtrl.text,
                role: roleCtrl.text,
              );

              await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(id).set(newUser.toMap());
              
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addUser(context),
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(FirestoreCollections.users).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final user = UserModel.fromMap(snapshot.data!.docs[index].data() as Map<String, dynamic>);
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(user.name.isNotEmpty ? user.name[0] : '?')),
                  title: Text(user.name),
                  subtitle: Text('${user.email} • ${user.role.toUpperCase()}'),
                  trailing: Switch(
                    value: user.isActive,
                    onChanged: (val) {
                      FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(user.uid).update({'isActive': val});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
