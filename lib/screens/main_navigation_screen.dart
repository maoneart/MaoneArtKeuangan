import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'transaction_screen.dart';
import 'savings_screen.dart';
import 'debts_screen.dart';
import 'reports_screen.dart';

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
    final screens = [
      HomeScreen(onNavigateTab: _onTabChanged),
      const TransactionScreen(),
      const SavingsScreen(),
      const DebtsScreen(),
      const ReportsScreen(),
    ];

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
                icon: Icon(Icons.savings_rounded),
                activeIcon: Icon(Icons.savings_rounded, color: AppTheme.bluePrimary),
                label: 'Tabungan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.handshake_rounded),
                activeIcon: Icon(Icons.handshake_rounded, color: AppTheme.bluePrimary),
                label: 'Hutang',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                activeIcon: Icon(Icons.bar_chart_rounded, color: AppTheme.bluePrimary),
                label: 'Laporan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
