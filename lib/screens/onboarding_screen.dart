import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isFromSettings;
  const OnboardingScreen({super.key, this.isFromSettings = false});

  static const String prefKey = 'has_seen_onboarding_v1';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefKey, true);

    if (!mounted) return;

    if (widget.isFromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onFinish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.bluePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.bluePrimary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MaoneArt Keuangan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _onFinish,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        'Lewati',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // PageView Slider
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildSlide1AiAssistant(),
                  _buildSlide2PencatatanKas(),
                  _buildSlide3KeunggulanOffline(),
                  _buildSlide4TentangPengembang(),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, bottomSafe),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.bluePrimary : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bluePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: AppTheme.bluePrimary.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _totalPages - 1 ? 'Mulai Sekarang' : 'Lanjut',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentPage == _totalPages - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SLIDE 1: SMART AI ASSISTANT ====================
  Widget _buildSlide1AiAssistant() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF0047CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'FITUR CERDAS GEMINI AI',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF7C3AED),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Curhat Keuangan\n& Catat Otomatis',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cukup ceritakan pengeluaran, pemasukan, hutang, atau tabungan Anda secara santai. AI akan otomatis merangkum dan mencatatkannya dalam 1 klik!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Demo Box Curhat
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.bluePrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Contoh Curhat Anda:',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '💬 "Tadi makan siang nasi padang 25rb, beli bensin 30rb, terus dapet transferan sampingan 500rb"',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF334155), fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.greenMain),
                    const SizedBox(width: 6),
                    Text(
                      'AI langsung mendeteksi & siap disimpan ke SQLite!',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.greenMain, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 2: PENCATATAN KAS & HUTANG TABUNGAN ====================
  Widget _buildSlide2PencatatanKas() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0047CC), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0047CC).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.blueLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'MANAJEMEN KEUANGAN LENGKAP',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.bluePrimary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kelola Arus Kas, Hutang\n& Tabungan Impian',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Catat pemasukan dan pengeluaran dengan 40+ ikon kategori lengkap, kelola hutang piutang dengan riwayat cicilan, serta wujudkan target tabungan impian Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // 3 Feature Mini Cards
          Row(
            children: [
              Expanded(
                child: _buildMiniBadge(Icons.receipt_long_rounded, AppTheme.bluePrimary, 'Arus Kas\nReal-Time'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniBadge(Icons.handshake_rounded, const Color(0xFFD97706), 'Hutang &\nPiutang'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniBadge(Icons.savings_rounded, AppTheme.greenMain, 'Tabungan\nImpian'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 3: KEUNGGULAN OFFLINE & PRIVASI ====================
  Widget _buildSlide3KeunggulanOffline() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.greenSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'KEAMANAN & PRIVASI 100%',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.greenMain,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '100% Offline, Cepat\n& Privasi Terjaga',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Semua data keuangan Anda tersimpan secara eksklusif di memori internal ponsel Anda menggunakan database SQLite lokal tanpa server pihak ketiga.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildAdvantageItem(Icons.wifi_off_rounded, 'Bekerja Penuh Tanpa Internet (Offline SQLite)'),
                const Divider(color: AppTheme.borderLight, height: 16),
                _buildAdvantageItem(Icons.block_rounded, 'Tanpa Iklan yang Mengganggu Kenyamanan'),
                const Divider(color: AppTheme.borderLight, height: 16),
                _buildAdvantageItem(Icons.picture_as_pdf_rounded, 'Ekspor Laporan ke Format PDF & Excel/CSV'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 4: TENTANG PENGEMBANG & VERSI ====================
  Widget _buildSlide4TentangPengembang() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.bluePrimary.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet_rounded, size: 40, color: AppTheme.bluePrimary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'MaoneArt Keuangan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.blueLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Versi 1.0.5 (Official Release)',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.bluePrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 18),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Nama Aplikasi', 'MaoneArt Keuangan'),
                const Divider(color: AppTheme.borderLight, height: 16),
                _buildInfoRow('Pengembang / Developer', 'Hermawan'),
                const Divider(color: AppTheme.borderLight, height: 16),
                _buildInfoRow('Versi Resmi', 'v1.0.5'),
                const Divider(color: AppTheme.borderLight, height: 16),
                _buildInfoRow('Teknologi', 'Flutter, SQLite & Gemini AI'),
                const Divider(color: AppTheme.borderLight, height: 16),
                _buildInfoRow('Lisensi', '100% Gratis untuk Penggunaan Pribadi'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Siap mengelola keuangan Anda lebih cerdas & rapi?',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, Color color, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: AppTheme.textDark,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantageItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.greenSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.greenMain, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
