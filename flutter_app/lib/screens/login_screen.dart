import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  final ApiService _apiService = ApiService();

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await _apiService.login(email, password);
      if (!mounted) return;
      
      context.read<UserProvider>().login(data['user'], data['token']);
      
      final user = data['user'];
      final hasFullProfile = user['name'] != null && 
                           user['phone'] != null && 
                           (user['emergencyContacts'] as List?)?.isNotEmpty == true;

      if (hasFullProfile) {
        context.go('/main');
      } else {
        context.go('/trip-details');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.trustBlue.withOpacity(0.1), AppTheme.trustBlue.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.trustBlue.withOpacity(0.1)),
                ),
                child: const Icon(Icons.shield_rounded, size: 48, color: AppTheme.trustBlue),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome Back',
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.deepNavy),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue your secure journey',
                style: TextStyle(color: AppTheme.slate, fontSize: 16),
              ),
              const SizedBox(height: 48),
              _buildField('Email Address', _emailController, Icons.alternate_email_rounded, false),
              const SizedBox(height: 24),
              _buildField('Password', _passwordController, Icons.lock_outline_rounded, true),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                child: _loading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sign In'),
                        const SizedBox(width: 12),
                        Icon(Icons.login_rounded, size: 20, color: Colors.white.withOpacity(0.9)),
                      ],
                    ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: GoogleFonts.outfit(color: AppTheme.slate, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
                ],
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: Colors.grey[200]!),
                  foregroundColor: AppTheme.deepNavy,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                      height: 24,
                    ),
                    const SizedBox(width: 12),
                    Text('Continue with Google', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.deepNavy)),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: 'Enter your ${label.toLowerCase()}',
            prefixIcon: Icon(icon, size: 20, color: AppTheme.trustBlue.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }
}
