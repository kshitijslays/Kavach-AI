import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/home_page.dart';
import '../screens/safe_route_map_screen.dart';
import '../screens/profile_screen.dart';
import '../core/theme.dart';

class MainTabNavigator extends StatefulWidget {
  const MainTabNavigator({super.key});

  @override
  State<MainTabNavigator> createState() => _MainTabNavigatorState();
}

class _MainTabNavigatorState extends State<MainTabNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const SafeRouteMapScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepNavy.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.trustBlue,
            unselectedItemColor: AppTheme.slate.withOpacity(0.5),
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 26), 
                activeIcon: Icon(Icons.home_rounded, size: 28), 
                label: 'Home'
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined, size: 26), 
                activeIcon: Icon(Icons.map_rounded, size: 28), 
                label: 'Safe Route'
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 26), 
                activeIcon: Icon(Icons.person_rounded, size: 28), 
                label: 'Profile'
              ),
            ],
          ),
        ),
      ),
    );
  }
}
