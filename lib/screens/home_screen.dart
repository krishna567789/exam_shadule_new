import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'candidates_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CandidatesScreen(),
    const DashboardScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color navBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color selectedColor = Theme.of(context).primaryColor;
    final Color unselectedColor = isDark ? Colors.white54 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarColor,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade300,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: navBarColor,
          elevation: 0,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          selectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Candidates',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
