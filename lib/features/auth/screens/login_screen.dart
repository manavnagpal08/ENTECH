import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../repositories/auth_repository.dart';
import '../../dashboard/screens/dashboard_screen.dart'; // Import Dashboard for manual navigation

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isObscured = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final repo = context.read<AuthRepository>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    try {
      await repo.login(email, password);
      // MANUAL NAVIGATION FOR TRIAL (Bypassing AuthWrapper)
      if (mounted) {
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => const DashboardScreen()),
         );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login Failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Industrial SaaS Look: Clean, Professional, Trustworthy
    return Scaffold(
      backgroundColor: AppColors.background, // Light Grey-Blue
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               // DEPLOYMENT ID TEXT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(20)),
                child: const Text("Deployment No: TRIAL-V3-2026", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
              const SizedBox(height: 24),
              // Logo & Brand
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Image.asset(AppAssets.logo, height: 60, width: 60),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Enterprise Management System',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Login Card
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Trial Access',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                       const SizedBox(height: 8),
                      const Text(
                        'Enter Department Name & Pass: 123456',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Email Field which acts as Department/Username
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Department / Username',
                          hintText: 'e.g. Admin, Sales, Service',
                          prefixIcon: const Icon(Icons.business, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscured,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                            onPressed: () => setState(() => _isObscured = !_isObscured),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v!.isEmpty ? 'Password is required' : null,
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                             : const Text('Access Trial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
           
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Footer
              Text(
                '© 2026 Envirotech Systems. Trial Mode.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
