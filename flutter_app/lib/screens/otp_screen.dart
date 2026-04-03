import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isSignUp;
  final String? name;
  final String? phone;
  final String? password;

  const OtpScreen({
    super.key, 
    required this.email, 
    required this.isSignUp,
    this.name,
    this.phone,
    this.password,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  bool _loading = false;
  final ApiService _apiService = ApiService();

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) return;

    setState(() => _loading = true);
    try {
      final data = await _apiService.verifyOTP(
        widget.email, 
        otp,
        name: widget.name,
        phone: widget.phone,
        password: widget.password,
      );
      if (!mounted) return;
      context.read<UserProvider>().login(data['user'], data['token']);
      context.go('/trip-details');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.trustBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded, size: 40, color: AppTheme.trustBlue),
              ),
              const SizedBox(height: 32),
              Text(
                'Verify Email', 
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.deepNavy)
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code sent to\n${widget.email}', 
                textAlign: TextAlign.center, 
                style: const TextStyle(color: AppTheme.slate, fontSize: 16, height: 1.5)
              ),
              const SizedBox(height: 48),
              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) => _buildOtpBox(index)),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                child: _loading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Verify & Continue'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Resend Code', 
                  style: GoogleFonts.outfit(color: AppTheme.trustBlue, fontWeight: FontWeight.w700)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 50,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _controllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.deepNavy),
        decoration: InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.trustBlue, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }
}
