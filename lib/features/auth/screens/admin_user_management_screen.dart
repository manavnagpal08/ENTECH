import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _selectedRole = 'employee';
  bool _isLoading = false;
  bool _isUploading = false; 
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickAndUploadLogo() async {
     // 1. Pick File
     final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
     if (result == null) return;
     
     setState(() => _isUploading = true);
     try {
       // 2. Upload to Storage
       final fileBytes = result.files.first.bytes!;
       final fileName = 'global_logo_${DateTime.now().millisecondsSinceEpoch}.png';
       final ref = FirebaseStorage.instance.ref().child('uploads/logo/$fileName');
       
       await ref.putData(fileBytes, SettableMetadata(contentType: 'image/png'));
       final downloadUrl = await ref.getDownloadURL();
       
       // 3. Save to Firestore
       await FirebaseFirestore.instance.collection('settings').doc('global').set({
         'logoUrl': downloadUrl,
         'updatedAt': FieldValue.serverTimestamp(),
       }, SetOptions(merge: true));

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo Uploaded Successfully!')));
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Failed: $e'), backgroundColor: Colors.red));
       }
     } finally {
       if (mounted) setState(() => _isUploading = false);
     }
  }

  void _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    // ... existing logic ...
    setState(() => _isLoading = true);
    // ... logic ...
    try {
      await context.read<AuthRepository>().createEmployee(
            _emailCtrl.text.trim(),
            _passCtrl.text.trim(),
            _nameCtrl.text.trim(),
            _selectedRole,
          );
      // ... 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Created Successfully')));
        _emailCtrl.clear();
        _passCtrl.clear();
        _nameCtrl.clear();
      }
    } catch (e) {
        // ...
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Access')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Employee Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Use this form to generate new login credentials for staff.'),
            const SizedBox(height: 24),
            
            Form(
              key: _formKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                        obscureText: true,
                        validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge)),
                        items: const [
                          DropdownMenuItem(value: 'employee', child: Text('Employee (Standard)')),
                          DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                        ],
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _createUser,
                          icon: const Icon(Icons.person_add),
                          label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'System Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text("PDF Logo Configuration", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("To use a custom logo in PDF reports, verify the asset is in 'assets/images/logo.png'. To upload a dynamic logo, please contact the developer (9896817707).", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      // Placeholder for future file upload
                      Row(
                        children: [
                           const Icon(Icons.image, color: Colors.grey),
                           const SizedBox(width: 12),
                           Expanded(child: Text(_isUploading ? "Uploading..." : "Current Logo Source: Local Asset (Primary) or Custom", style: const TextStyle(fontWeight: FontWeight.w500))),
                           ElevatedButton.icon(
                             onPressed: _isUploading ? null : _pickAndUploadLogo, 
                             icon: const Icon(Icons.cloud_upload),
                             label: const Text("Upload New Logo")
                           )
                        ],
                      )
                   ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
