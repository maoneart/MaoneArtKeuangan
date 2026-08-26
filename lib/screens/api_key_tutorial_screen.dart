import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';

class ApiKeyTutorialScreen extends StatelessWidget {
  const ApiKeyTutorialScreen({super.key});

  static const String _aiStudioUrl = 'https://aistudio.google.com/app/apikey';

  Future<void> _openAiStudio(BuildContext context) async {
    final uri = Uri.parse(_aiStudioUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(const ClipboardData(text: _aiStudioUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link berhasil disalin ke clipboard: https://aistudio.google.com/app/apikey'),
              backgroundColor: AppTheme.bluePrimary,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: _aiStudioUrl));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link disalin ke clipboard: https://aistudio.google.com/app/apikey'),
            backgroundColor: AppTheme.bluePrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          'Cara Membuat API Key',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== HERO BANNER ====================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0047CC), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0047CC).withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.key_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tutorial Google Gemini API Key',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dapatkan Kunci API resmi 100% GRATIS dari Google dalam 1 menit tanpa perlu kartu kredit.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openAiStudio(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.bluePrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(
                        'Buka Google AI Studio',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==================== STEP BY STEP ====================
              Text(
                '5 LANGKAH MUDAH MENDAPATKAN KUNCI',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 1,
                title: 'Buka Google AI Studio di Browser',
                description: 'Kunjungi situs resmi Google AI Studio pada link:\nhttps://aistudio.google.com/app/apikey',
                icon: Icons.public_rounded,
                iconColor: const Color(0xFF3B82F6),
                actionWidget: OutlinedButton.icon(
                  onPressed: () => _openAiStudio(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.bluePrimary,
                    side: const BorderSide(color: AppTheme.bluePrimary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.link_rounded, size: 14),
                  label: const Text('Buka Website Sekarang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 2,
                title: 'Login dengan Akun Google (Gmail)',
                description: 'Masuk menggunakan akun Gmail Anda. Centang persetujuan syarat ketentuan jika baru pertama kali membuka.',
                icon: Icons.account_circle_rounded,
                iconColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 3,
                title: 'Pilih Menu "Get API Key"',
                description: 'Di panel menu sebelah kiri, klik menu "Get API key" (ikon kunci 🔑).',
                icon: Icons.vpn_key_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 4,
                title: 'Klik Tombol "Create API Key"',
                description: 'Klik tombol biru "Create API key" di bagian atas, lalu pilih opsi "Create API key in new project".',
                icon: Icons.add_circle_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 5,
                title: 'Salin Kode Kunci & Tempelkan ke Aplikasi',
                description: 'Google akan memunculkan kode API Key (diawali AIzaSy... atau AQ...). Klik tombol "Copy", lalu kembali ke aplikasi MaoneArt Keuangan dan tempelkan di menu Pengaturan -> Simpan!',
                icon: Icons.content_copy_rounded,
                iconColor: const Color(0xFF06B6D4),
              ),
              const SizedBox(height: 20),

              // ==================== FAQ CARD ====================
              Text(
                'PERTANYAAN UMUM (FAQ)',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFaqItem(
                      question: 'Apakah API Key Gemini ini gratis?',
                      answer: 'Ya, 100% GRATIS dari Google untuk penggunaan pribadi dengan batas hingga 1.500 permintaan per hari (sangat lebih dari cukup untuk mencatat keuangan).',
                    ),
                    const Divider(color: AppTheme.borderLight, height: 20),
                    _buildFaqItem(
                      question: 'Apakah kunci saya aman di aplikasi ini?',
                      answer: 'Sangat aman! Kunci API Anda disimpan 100% di memori internal HP Anda sendiri, tidak pernah diunggah atau dibagikan ke internet maupun GitHub.',
                    ),
                    const Divider(color: AppTheme.borderLight, height: 20),
                    _buildFaqItem(
                      question: 'Kunci saya diawali AQ... apakah bisa?',
                      answer: 'Bisa! Aplikasi MaoneArt Keuangan mendukung semua format kunci resmi Google, baik format klasik AIzaSy... maupun format terbaru AQ....',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    Widget? actionWidget,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$stepNumber',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
                if (actionWidget != null) ...[
                  const SizedBox(height: 8),
                  actionWidget,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppTheme.bluePrimary, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                question,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11.5, height: 1.4),
        ),
      ],
    );
  }
}
