import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import 'api_key_tutorial_screen.dart';
import 'onboarding_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bottomPadding = MediaQuery.of(context).padding.bottom + (isLandscape ? 30 : 50);

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          'Tentang Aplikasi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== 1. HERO BRANDING CARD ====================
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.bluePrimary.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet_rounded, size: 38, color: AppTheme.bluePrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'MaoneArt Keuangan',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.blueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Versi 1.1.9 (Official Release)',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.bluePrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aplikasi Manajemen Keuangan Pribadi, Arus Kas Harian, Hutang Piutang, dan Tabungan Impian Cerdas berbasis Flutter & SQLite 100% Offline.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ==================== 2. INFORMASI PENGEMBANG & SISTEM ====================
              _buildSectionTitle('INFORMASI PENGEMBANG & SISTEM'),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Nama Aplikasi', 'MaoneArt Keuangan'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Pengembang / Developer', 'Hermawan'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Tahun Rilis', '2026'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Platform', 'Android (Flutter + MySQL & SQLite)'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Database Engine', 'MariaDB Termux (db_keuangan) & SQLite'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ==================== 3. FITUR UTAMA & KEUNGGULAN ====================
              _buildSectionTitle('FITUR UNGGULAN APLIKASI'),
              _buildFeatureItem(
                icon: Icons.auto_awesome_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF0047CC)]),
                title: 'Smart AI Financial Assistant (Chat AI)',
                description: 'Curhat keuangan Anda secara santai, AI otomatis mendeteksi rincian nominal dan tanggal transaksi untuk dicatat.',
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                icon: Icons.account_balance_wallet_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                title: 'Pencatatan Arus Kas & Saldo Real-Time',
                description: 'Pencatatan Pemasukan & Pengeluaran dengan pemisah ribuan otomatis serta kalkulasi saldo kas yang akurat.',
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                icon: Icons.handshake_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                title: 'Debt & Credit Manager (Hutang Piutang)',
                description: 'Pelunasan hutang memotong kas riil, penerimaan piutang menambah kas, lengkap dengan riwayat pembayaran.',
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                icon: Icons.savings_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0284C7)]),
                title: 'Savings & Target Goals (Tabungan Impian)',
                description: 'Target tabungan dan setoran berkala otomatis memotong kas dengan validasi kecukupan saldo.',
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                icon: Icons.category_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)]),
                title: '40+ Ikon Kategori Sangat Lengkap',
                description: 'Kategori terbagi rapi mulai dari Gaji, Sedekah, Zakat, Tagihan, SPP, Servis Kendaraan, hingga Belanja Masak.',
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                icon: Icons.pie_chart_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFBE185D)]),
                title: 'Laporan Visual & Grafik Batang',
                description: 'Diagram Lingkaran komposisi pengeluaran dan Grafik Batang Arus Kas Mingguan yang proporsional.',
              ),
              const SizedBox(height: 18),

              // ==================== 4. KEAMANAN & PRIVASI ====================
              _buildSectionTitle('KEAMANAN & ARSITEKTUR DATA'),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSecurityBullet(
                      icon: Icons.shield_rounded,
                      title: '100% Data Offline & Privat',
                      desc: 'Catatan keuangan Anda tersimpan di memori lokal HP (SQLite & MariaDB Termux). Tanpa server eksternal, bebas lacak.',
                    ),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildSecurityBullet(
                      icon: Icons.storage_rounded,
                      title: 'Sinkronisasi Anti-Hilang phpMyAdmin',
                      desc: 'Saat aplikasi di-update atau di-install ulang, seluruh data dapat dipulihkan secara instan dari database Termux.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ==================== 5. PANDUAN CEPAT ====================
              _buildSectionTitle('PANDUAN & BANTUAN'),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen(isFromSettings: true)),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.bluePrimary,
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          backgroundColor: AppTheme.blueLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.slideshow_rounded, size: 16),
                        label: Text(
                          'Panduan Intro',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ApiKeyTutorialScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                          backgroundColor: const Color(0xFFEEF2FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 16),
                        label: Text(
                          'Panduan API Key',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Text(
                  '© 2026 MaoneArt • Developer: Hermawan',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
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

  Widget _buildFeatureItem({
    required IconData icon,
    required LinearGradient iconGradient,
    required String title,
    required String description,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconGradient.colors.first.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBullet({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.greenMain, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
