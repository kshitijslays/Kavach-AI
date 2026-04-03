import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSOSButton(context, size),
              _buildSectionTitle('Active Security Profile'),
              _buildSafetyStatus(),
              _buildSectionTitle('Quick Actions'),
              _buildQuickActions(),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Morning,', style: GoogleFonts.outfit(color: AppTheme.slate, fontSize: 16, fontWeight: FontWeight.w500)),
              Text('Shield is Active', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.deepNavy, letterSpacing: -0.5)),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.trustBlue.withOpacity(0.2), width: 2),
            ),
            padding: const EdgeInsets.all(4),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.trustBlue,
              child: Icon(Icons.person_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, Size size) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        width: size.width * 0.7,
        height: size.width * 0.7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.errorRed.withOpacity(0.05),
        ),
        child: Center(
          child: Container(
            width: size.width * 0.55,
            height: size.width * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.errorRed.withOpacity(0.1),
            ),
            child: Center(
              child: Container(
                width: size.width * 0.42,
                height: size.width * 0.42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.errorRed, Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorRed.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      'SOS',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title, 
        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.deepNavy)
      ),
    );
  }

  Widget _buildSafetyStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppTheme.successGreen, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safe Environment', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.deepNavy, fontSize: 16)),
                const Text('Nahargarh Road, Jaipur', style: TextStyle(color: AppTheme.slate, fontSize: 14), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.slate),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(Icons.local_police_rounded, 'Police', AppTheme.trustBlue),
        _buildActionCard(Icons.medical_services_rounded, 'Medical', AppTheme.errorRed),
        _buildActionCard(Icons.location_on_rounded, 'Safe Zone', AppTheme.successGreen),
        _buildActionCard(Icons.share_location_rounded, 'Live Track', Colors.orange),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title, 
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.deepNavy)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
