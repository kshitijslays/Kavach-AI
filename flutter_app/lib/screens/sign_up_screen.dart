import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  final ApiService _apiService = ApiService();

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _apiService.sendOTP(email, isSignUp: true);
      if (!mounted) return;
      context.push('/otp', extra: {
        'email': email,
        'isSignUp': true,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
      });
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('registered') || errorMessage.contains('409')) {
          _showAlreadyRegisteredDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Account Exists', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('An account with this email already exists. Would you like to sign in instead?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 45)),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shield', style: GoogleFonts.outfit(color: AppTheme.trustBlue, fontWeight: FontWeight.w900, letterSpacing: 2))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Create Account', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.deepNavy)),
              const SizedBox(height: 8),
              const Text('Join Shield to stay safe during your travels', style: TextStyle(color: AppTheme.slate, fontSize: 16)),
              const SizedBox(height: 48),
              _buildField('Full Name', _nameController, Icons.person_outline_rounded),
              const SizedBox(height: 24),
              _buildField('Email Address', _emailController, Icons.alternate_email_rounded),
              const SizedBox(height: 24),
              _buildField('Phone Number', _phoneController, Icons.phone_android_rounded),
              const SizedBox(height: 24),
              _buildField('Secure Password', _passwordController, Icons.lock_outline_rounded, obscure: true),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _loading ? null : _handleSignUp,
                child: _loading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Create Account'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.deepNavy, fontSize: 14)),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppTheme.trustBlue.withOpacity(0.7)),
            hintText: 'Enter your ${label.toLowerCase()}',
          ),
        ),
      ],
    );
  }
}
