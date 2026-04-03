import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _sosController;
  late Animation<double> _sosAnimation;
  bool isActivated = true;

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _sosAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _sosController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sosController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final Uri url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch dialer for $number');
    }
  }

  void _triggerSOS() {
    debugPrint('🚨 [UI] SOS Button Pressed, invoking background trigger...');
    FlutterBackgroundService().invoke('forceTriggerSOS');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Emergency Alert Triggered!', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.trustBlue.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSOSButton(size)),
                SliverToBoxAdapter(child: _buildSectionTitle('Safety Status')),
                SliverToBoxAdapter(child: _buildStatusCard()),
                SliverToBoxAdapter(child: _buildSectionTitle('Quick Assistance')),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _buildActionCard(Icons.local_police_rounded, 'Police', AppTheme.trustBlue, () => _makeCall('112')),
                      _buildActionCard(Icons.medical_services_rounded, 'Ambulance', AppTheme.errorRed, () => _makeCall('108')),
                      _buildActionCard(Icons.location_on_rounded, 'Safe Zone', AppTheme.successGreen, () {
                        // Switch to Safe Route Tab (Index 1 in MainTabNavigator)
                        // This usually requires a provider or a parent state update.
                        // Assuming SafeRoute is index 1.
                      }),
                      _buildActionCard(Icons.shield_rounded, 'Protection', Colors.orange, () {}),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 30, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello Explorer,', 
                style: GoogleFonts.outfit(color: AppTheme.slate, fontSize: 16, fontWeight: FontWeight.w400)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Kavach is ', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.deepNavy)),
                  Text('Active', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.trustBlue)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.trustBlue.withOpacity(0.1), width: 2),
            ),
            child: const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: AppTheme.deepNavy, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(Size size) {
    return Container(
      height: size.width * 0.85,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated Rings
          ScaleTransition(
            scale: _sosAnimation,
            child: Container(
              width: size.width * 0.45,
              height: size.width * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorRed.withOpacity(0.15),
              ),
            ),
          ),
          ScaleTransition(
            scale: _sosAnimation.drive(Tween<double>(begin: 1.0, end: 1.4)),
            child: Container(
              width: size.width * 0.35,
              height: size.width * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.errorRed.withOpacity(0.2), width: 1.5),
              ),
            ),
          ),
          
          // Outer Soft Glow
          Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.errorRed.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Actual Button
          GestureDetector(
            onLongPress: _triggerSOS,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Long press to trigger SOS', style: GoogleFonts.outfit()),
                  backgroundColor: AppTheme.deepNavy,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              width: size.width * 0.42,
              height: size.width * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.errorRed, Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorRed.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency_rounded, color: Colors.white, size: 50),
                  const SizedBox(height: 8),
                  Text('SOS', 
                    style: GoogleFonts.outfit(
                      fontSize: 34, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white, 
                      letterSpacing: 2
                    )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 24, 16),
      child: Text(title, 
        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.deepNavy)),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gpp_good_rounded, color: AppTheme.successGreen, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shield Status: Secure', 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.deepNavy, fontSize: 17)),
                const SizedBox(height: 2),
                Text('Real-time monitoring active.', 
                  style: GoogleFonts.outfit(color: AppTheme.slate, fontSize: 13, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
             decoration: BoxDecoration(
               color: AppTheme.background,
               borderRadius: BorderRadius.circular(10),
             ),
             child: const Icon(Icons.chevron_right_rounded, color: AppTheme.slate, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(title, 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.deepNavy)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
