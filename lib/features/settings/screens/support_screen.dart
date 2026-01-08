import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text("Support Center", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Need help? Contact our support team.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              
              _buildContactItem(Icons.person, "Manav Nagpal"),
              _buildContactItem(Icons.phone, "9896817707", isLink: true),
              _buildContactItem(Icons.email, "manav.nagpal005@gmail.com", isLink: true),
              
              const SizedBox(height: 48),
              
              // Branding
              Column(
                children: [
                  const Text("Powered By", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                       Icon(Icons.flash_on, size: 16, color: Colors.orange), // Placeholder for logo
                       SizedBox(width: 4),
                       Text("FLIP CLIP", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w500,
              color: isLink ? Colors.blue.shade700 : Colors.black87,
              decoration: isLink ? TextDecoration.underline : null,
            )),
          ),
        ],
      ),
    );
  }
}
