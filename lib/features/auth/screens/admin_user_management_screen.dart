import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/auth_repository.dart';
import '../../../core/theme/app_theme.dart';

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
  final _formKey = GlobalKey<FormState>();

  void _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthRepository>().createEmployee(
            _emailCtrl.text.trim(),
            _passCtrl.text.trim(),
            _nameCtrl.text.trim(),
            _selectedRole,
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Created Successfully')));
        _emailCtrl.clear();
        _passCtrl.clear();
        _nameCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
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
          ],
        ),
      ),
    );
  }
}
