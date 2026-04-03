import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _phoneController = TextEditingController();
  final List<Map<String, TextEditingController>> _contacts = [
    {
      'name': TextEditingController(),
      'number': TextEditingController(),
    }
  ];
  
  bool _loading = false;
  final ApiService _apiService = ApiService();

  void _addContact() {
    if (_contacts.length < 4) {
      setState(() {
        _contacts.add({
          'name': TextEditingController(),
          'number': TextEditingController(),
        });
      });
    }
  }

  void _removeContact(int index) {
    if (_contacts.length > 1) {
      setState(() {
        _contacts.removeAt(index);
      });
    }
  }

  Future<void> _handleSubmit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your phone number')));
      return;
    }

    final emergencyContacts = _contacts.map((c) => {
      'name': c['name']!.text.trim(),
      'number': c['number']!.text.trim(),
    }).where((c) => c['name']!.isNotEmpty && c['number']!.isNotEmpty).toList();

    if (emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one emergency contact')));
      return;
    }

    setState(() => _loading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final token = userProvider.token;
      if (token == null) throw Exception('Not authenticated');

      await _apiService.updateProfile(token, {
        'phone': phone,
        'emergencyContacts': emergencyContacts,
      });

      // Refresh local profile
      final updatedData = await _apiService.getProfile(token);
      if (!mounted) return;
      userProvider.login(updatedData['user'], token);

      context.go('/main');
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
        title: Text('Complete Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.trustBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.trustBlue, size: 32),
            ),
            const SizedBox(height: 24),
            Text('Travel Profile', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.deepNavy)),
            const SizedBox(height: 8),
            const Text('Finalize your details to activate Shield protection.', style: TextStyle(color: AppTheme.slate, fontSize: 16)),
            const SizedBox(height: 48),
            _buildField('Your Phone Number', _phoneController, Icons.phone_android_rounded),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Emergency Contacts', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepNavy)),
                if (_contacts.length < 4)
                  TextButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: const Text('Add More'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.trustBlue),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._contacts.asMap().entries.map((entry) {
              final index = entry.key;
              final contact = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Contact #${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.slate)),
                        if (_contacts.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.errorRed, size: 20),
                            onPressed: () => _removeContact(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField('Contact Name', contact['name']!, Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    _buildField('Contact Phone', contact['number']!, Icons.contact_phone_outlined),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _handleSubmit,
              child: _loading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Complete Setup'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.deepNavy)),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppTheme.trustBlue.withOpacity(0.7)),
            hintText: 'Enter ${label.toLowerCase()}',
          ),
        ),
      ],
    );
  }
}
