import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [  
          IconButton(
            icon: const Icon(Icons.edit_note_rounded), 
            onPressed: () => _showEditContactsDialog(context, userProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.trustBlue.withOpacity(0.2), width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 54,
                    backgroundColor: AppTheme.trustBlue,
                    child: Icon(Icons.person_rounded, size: 54, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user?['name'] ?? 'Incomplete Profile', 
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.deepNavy)
          ),
          Text(
            user?['email'] ?? 'Update your profile to stay protected', 
            style: const TextStyle(color: AppTheme.slate, fontSize: 15)
          ),
          const SizedBox(height: 48),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildTile(Icons.person_outline_rounded, 'Personal Information'),
                _buildEmergencyContactsTile(user),
                _buildTile(Icons.history_rounded, 'Safety Records'),
                _buildTile(Icons.settings_suggest_rounded, 'App Settings'),
                const Divider(height: 32, thickness: 1),
                _buildTile(
                  Icons.logout_rounded, 
                  'Sign Out', 
                  color: AppTheme.errorRed, 
                  onTap: () {
                    userProvider.logout();
                    context.go('/');
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.trustBlue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? AppTheme.trustBlue, size: 20),
        ),
        title: Text(
          title, 
          style: GoogleFonts.outfit(
            color: color ?? AppTheme.deepNavy, 
            fontWeight: FontWeight.w600,
            fontSize: 16,
          )
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: (color ?? AppTheme.slate).withOpacity(0.5)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEmergencyContactsTile(Map<String, dynamic>? user) {
    final contacts = (user != null && user['emergencyContacts'] != null)
        ? user['emergencyContacts'] as List<dynamic>
        : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.trustBlue,
          collapsedIconColor: AppTheme.slate.withOpacity(0.5),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.trustBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emergency_outlined, color: AppTheme.trustBlue, size: 20),
          ),
          title: Text(
            'Emergency Contacts', 
            style: GoogleFonts.outfit(
              color: AppTheme.deepNavy, 
              fontWeight: FontWeight.w600,
              fontSize: 16,
            )
          ),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          children: contacts.isEmpty 
              ? [
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('No emergency contacts added.', style: TextStyle(color: AppTheme.slate)),
                  )
                ]
              : contacts.map((contact) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.slate.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.contact_phone_rounded, color: AppTheme.trustBlue, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name']?.toString() ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.deepNavy,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                contact['number']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }

  void _showEditContactsDialog(BuildContext context, UserProvider provider) {
    final List<dynamic> contacts = List.from(provider.user?['emergencyContacts'] ?? []);
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Manage Contacts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (contacts.length < 5) ...[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Contact Name', hintText: 'e.g. Mom'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: numberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', hintText: 'e.g. +919876543210'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (nameController.text.isNotEmpty && numberController.text.isNotEmpty) {
                          setDialogState(() {
                            contacts.add({
                              'name': nameController.text.trim(),
                              'number': numberController.text.trim(),
                            });
                            nameController.clear();
                            numberController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Contact'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                    ),
                    const Divider(height: 32),
                  ],
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          title: Text(contact['name'] ?? ''),
                          subtitle: Text(contact['number'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                            onPressed: () => setDialogState(() => contacts.removeAt(index)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await provider.updateEmergencyContacts(contacts);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
