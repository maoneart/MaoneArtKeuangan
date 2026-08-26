import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 40;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          'Pengaturan & Tentang',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== 1. BRANDING HERO CARD ====================
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
                            color: AppTheme.bluePrimary.withValues(alpha: 0.15),
                            blurRadius: 16,
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
                          errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet_rounded, size: 36, color: AppTheme.bluePrimary),
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.blueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Versi 1.0.0 (Official Release)',
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
              const SizedBox(height: 16),

              // ==================== 2. FITUR UNGGULAN ====================
              Text(
                'FITUR UNGGULAN APLIKASI',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              _buildFeatureItem(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppTheme.greenMain,
                title: 'Pencatatan Arus Kas & Saldo Real-Time',
                description: 'Pencatatan Pemasukan & Pengeluaran dengan format ribuan otomatis dan saldo kas yang akurat.',
              ),
              const SizedBox(height: 8),

              _buildFeatureItem(
                icon: Icons.handshake_rounded,
                iconColor: AppTheme.redMain,
                title: 'Debt & Credit Manager (Hutang Piutang)',
                description: 'Pelunasan hutang memotong saldo kas, penerimaan piutang menambah kas, lengkap dengan riwayat cicilan.',
              ),
              const SizedBox(height: 8),

              _buildFeatureItem(
                icon: Icons.savings_rounded,
                iconColor: AppTheme.bluePrimary,
                title: 'Savings & Target Goals (Tabungan Impian)',
                description: 'Kalkulasi saldo awal dan setoran berkala otomatis memotong kas riil dengan validasi saldo.',
              ),
              const SizedBox(height: 8),

              _buildFeatureItem(
                icon: Icons.category_rounded,
                iconColor: const Color(0xFF0D9488),
                title: '40+ Ikon Kategori Sangat Lengkap',
                description: 'Tersedia Sedekah, Tahlil, Pajak, SPP, Servis Kendaraan, Zakat, hingga Tagihan Rumah.',
              ),
              const SizedBox(height: 8),

              _buildFeatureItem(
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Laporan Visual & Grafik Batang Rapi',
                description: 'Diagram Lingkaran kategori dan Grafik Batang Arus Kas Mingguan dengan tata letak proporsional.',
              ),
              const SizedBox(height: 8),

              _buildFeatureItem(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF059669),
                title: '100% Offline & Privasi Terjaga',
                description: 'Data disimpan lokal di database SQLite HP Anda tanpa internet dan tanpa server pihak ketiga.',
              ),
              const SizedBox(height: 20),

              // ==================== 3. INFORMASI SISTEM & PENGEMBANG ====================
              Text(
                'INFORMASI PENGEMBANG',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Pengembang', 'MaoneArt'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Tahun Rilis', '2026'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Platform', 'Android (Flutter + SQLite)'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Status Rilis', 'v1.0.0 (Final Official)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  '© 2026 MaoneArt • All Rights Reserved',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textLight,
                    fontSize: 11,
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

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
