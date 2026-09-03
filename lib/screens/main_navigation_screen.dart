import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'transaction_screen.dart';
import 'ai_chat_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final screens = [
      HomeScreen(onNavigateTab: _onTabChanged),
      const TransactionScreen(),
      const AiChatScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    if (isLandscape) {
      return Scaffold(
        backgroundColor: AppTheme.bgApp,
        body: Row(
          children: [
            // Left Navigation Rail for Landscape Mode
            Container(
              width: 82,
              decoration: const BoxDecoration(
                color: AppTheme.cardBg,
                border: Border(right: BorderSide(color: AppTheme.borderLight, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 10,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppTheme.royalBlueGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x380047CC), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildRailItem(0, Icons.home_rounded, 'Beranda'),
                      _buildRailItem(1, Icons.receipt_long_rounded, 'Transaksi'),
                      _buildRailItem(2, Icons.auto_awesome_rounded, 'Chat AI', activeColor: const Color(0xFF8B5CF6)),
                      _buildRailItem(3, Icons.bar_chart_rounded, 'Laporan'),
                      _buildRailItem(4, Icons.settings_rounded, 'Pengaturan'),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            // Screen Content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

    // Portrait Mode Bottom Navigation Bar
    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabChanged,
            backgroundColor: AppTheme.cardBg,
            selectedItemColor: AppTheme.bluePrimary,
            unselectedItemColor: AppTheme.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded, color: AppTheme.bluePrimary),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                activeIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.bluePrimary),
                label: 'Transaksi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_rounded),
                activeIcon: Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
                label: 'Chat AI',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                activeIcon: Icon(Icons.bar_chart_rounded, color: AppTheme.bluePrimary),
                label: 'Laporan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                activeIcon: Icon(Icons.settings_rounded, color: AppTheme.bluePrimary),
                label: 'Pengaturan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRailItem(int index, IconData icon, String label, {Color? activeColor}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? (activeColor ?? AppTheme.bluePrimary) : AppTheme.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabChanged(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? (activeColor ?? AppTheme.bluePrimary).withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
