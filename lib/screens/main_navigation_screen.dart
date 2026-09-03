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
    final safePadding = MediaQuery.of(context).padding;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final screens = [
      HomeScreen(onNavigateTab: _onTabChanged),
      const TransactionScreen(),
      const AiChatScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    if (isLandscape) {
      // Hitung lebar sidebar agar tidak terpotong oleh notch / punch-hole kamera di samping
      final leftInset = safePadding.left;
      final railContentWidth = 92.0;
      final totalRailWidth = railContentWidth + leftInset;

      return Scaffold(
        backgroundColor: AppTheme.bgApp,
        body: Row(
          children: [
            // Left Navigation Rail for Landscape Mode (High-Contrast Deep Navy Theme)
            Container(
              width: totalRailWidth,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF071228),
                    Color(0xFF0B1B3D),
                    Color(0xFF060F24),
                  ],
                ),
                border: Border(
                  right: BorderSide(
                    color: Color(0x2EFFFFFF),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x50000000),
                    blurRadius: 18,
                    offset: Offset(4, 0),
                  ),
                ],
              ),
              child: SafeArea(
                top: true,
                bottom: true,
                left: true,
                right: false,
                child: SizedBox(
                  width: railContentWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Brand Logo Box
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.royalBlueGradient,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x660056FB),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 6),
                      // Navigation Items List
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              children: [
                                _buildRailItem(0, Icons.home_rounded, 'Beranda'),
                                _buildRailItem(1, Icons.receipt_long_rounded, 'Transaksi'),
                                _buildRailItem(2, Icons.auto_awesome_rounded, 'Chat AI', activeColor: const Color(0xFF8B5CF6)),
                                _buildRailItem(3, Icons.bar_chart_rounded, 'Laporan'),
                                _buildRailItem(4, Icons.settings_rounded, 'Pengaturan'),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Screen Content (Safe from right camera notch/nav insets)
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                left: false,
                right: true,
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
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
    final primaryColor = activeColor ?? const Color(0xFF0056FB);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabChanged(index),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.85),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: -0.2,
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
