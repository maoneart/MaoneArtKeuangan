import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import 'api_key_tutorial_screen.dart';
import 'onboarding_screen.dart';
import '../services/phpmyadmin_service.dart';
import '../services/gemini_service.dart';
import '../widgets/maoneart_modal.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  bool _obscureKey = true;
  bool _isInitialized = false;

  String _serverStatus = 'idle'; // 'idle', 'checking', 'connected', 'error'
  String _serverStatusMessage = '';
  Map<String, dynamic>? _serverCounts;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initServerUrl();
  }

  void _initServerUrl() async {
    final url = await PhpMyAdminService.getServerUrl();
    _serverUrlController.text = url;
    _checkServer();

    // Auto-load Gemini API Key dari phpMyAdmin jika di HP masih kosong
    final localKey = await GeminiService.getApiKey();
    if (localKey == null || localKey.isEmpty) {
      final remoteKey = await PhpMyAdminService.fetchGeminiApiKey();
      if (remoteKey != null && remoteKey.isNotEmpty && mounted) {
        ref.read(geminiApiKeyProvider.notifier).setKey(remoteKey);
        _apiKeyController.text = remoteKey;
      }
    }
  }

  void _checkServer() async {
    setState(() {
      _serverStatus = 'checking';
      _serverStatusMessage = 'Menghubungi server phpMyAdmin...';
    });
    final res = await PhpMyAdminService.checkStatus();
    if (!mounted) return;
    setState(() {
      if (res['status'] == 'connected') {
        _serverStatus = 'connected';
        _serverStatusMessage = 'Terhubung ke database ${res['database'] ?? 'db_keuangan'}';
        _serverCounts = res['counts'] as Map<String, dynamic>?;
      } else {
        _serverStatus = 'error';
        _serverStatusMessage = res['message'] ?? 'Server Termux offline';
        _serverCounts = null;
      }
    });
  }

  void _saveServerUrl() async {
    final url = _serverUrlController.text.trim();
    if (url.isNotEmpty) {
      await PhpMyAdminService.saveServerUrl(url);
      _checkServer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat server berhasil disimpan!')),
        );
      }
    }
  }

  void _syncData() async {
    setState(() => _isSyncing = true);
    final res = await ref.read(financialControllerProvider.notifier).syncWithPhpMyAdmin();
    if (!mounted) return;
    setState(() => _isSyncing = false);

    if (res['status'] == 'success') {
      final restored = res['restored_to_local'] as Map<String, dynamic>? ?? {};
      final pushed = res['pushed_new'] as Map<String, dynamic>? ?? {};
      MaoneArtModal.showAlertModal(
        context: context,
        title: 'Sinkronisasi Berhasil! 🎉',
        message: 'Data tersinkronisasi dengan database phpMyAdmin (db_keuangan):\n\n'
            '• Data Baru ke Server: ${pushed['transactions'] ?? 0} transaksi, ${pushed['debts'] ?? 0} hutang, ${pushed['savings'] ?? 0} tabungan\n'
            '• Data Dipulihkan ke HP: ${restored['transactions'] ?? 0} transaksi, ${restored['debts'] ?? 0} hutang, ${restored['savings'] ?? 0} tabungan\n\n'
            'Data Anda 100% aman dan tidak akan hilang meski aplikasi di-update atau di-install ulang!',
        accentColor: AppTheme.greenMain,
        icon: Icons.cloud_done_rounded,
        buttonText: 'Mantap',
      );
      _checkServer();
    } else {
      MaoneArtModal.showAlertModal(
        context: context,
        title: 'Gagal Sinkronisasi',
        message: 'Keterangan: ${res['message']}\n\nPastikan web server Apache & MySQL Termux sedang aktif di port 8085.',
        accentColor: AppTheme.redMain,
        icon: Icons.error_outline_rounded,
        buttonText: 'Tutup',
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  void _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      await ref.read(geminiApiKeyProvider.notifier).removeKey();
      PhpMyAdminService.saveGeminiApiKey('').ignore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemini API Key telah dihapus.')),
        );
      }
      return;
    }

    await ref.read(geminiApiKeyProvider.notifier).setKey(key);
    PhpMyAdminService.saveGeminiApiKey(key).ignore();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API Key berhasil disimpan ke HP & phpMyAdmin! ✨'),
          backgroundColor: AppTheme.greenMain,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedKey = ref.watch(geminiApiKeyProvider);
    final hasSavedKey = savedKey.trim().isNotEmpty;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 40;

    // Sinkronisasi otomatis teks controller jika belum diedit
    if (!_isInitialized && savedKey.isNotEmpty) {
      _apiKeyController.text = savedKey;
      _isInitialized = true;
    } else if (savedKey.isNotEmpty && _apiKeyController.text.isEmpty) {
      _apiKeyController.text = savedKey;
    }

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
                        'Versi 1.0.5 (Official Release)',
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

              // ==================== 2. PANDUAN APLIKASI (INTRO SLIDES) ====================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen(isFromSettings: true)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blueLight,
                    foregroundColor: AppTheme.bluePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFBFDBFE))),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.slideshow_rounded, size: 18, color: AppTheme.bluePrimary),
                  label: Text(
                    '📱 Lihat Panduan & Intro Aplikasi (4 Slide)',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.bluePrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==================== 3. GEMINI AI CONFIGURATION ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INTEGRASI GOOGLE GEMINI AI',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasSavedKey ? AppTheme.greenSoft : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasSavedKey ? 'Aktif ✅' : 'Belum Diatur ⚠️',
                      style: GoogleFonts.plusJakartaSans(
                        color: hasSavedKey ? const Color(0xFF047857) : const Color(0xFFD97706),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF0047CC)]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Google Gemini API Key',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kunci ini digunakan untuk fitur "Chat AI" agar Anda bisa curhat pengeluaran, pemasukan, hutang & tabungan dan langsung dicatat otomatis.',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11.5, height: 1.4),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscureKey,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tempel API Key (AIzaSy... / AQ...)',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppTheme.textMuted),
                          onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveApiKey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.bluePrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: Text('Simpan API Key', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        if (hasSavedKey) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              _apiKeyController.clear();
                              _saveApiKey();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.redMain,
                              side: const BorderSide(color: AppTheme.redMain),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tombol Tutorial Cara Buat API Key
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ApiKeyTutorialScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                          backgroundColor: const Color(0xFFEEF2FF),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF4F46E5)),
                        label: Text(
                          '📖 Panduan Cara Membuat API Key (100% Gratis)',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF4F46E5),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppTheme.textMuted, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'API Key tersimpan 100% aman di internal HP Anda (tidak diunggah ke internet).',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ==================== 4. PHPMYADMIN & DATABASE LOKAL ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DATABASE LOKAL PHPMYADMIN (ANTI-HILANG)',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _serverStatus == 'connected'
                          ? AppTheme.greenSoft
                          : (_serverStatus == 'checking' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _serverStatus == 'connected'
                          ? 'Terhubung 🟢'
                          : (_serverStatus == 'checking' ? 'Memeriksa... 🟡' : 'Offline 🔴'),
                      style: GoogleFonts.plusJakartaSans(
                        color: _serverStatus == 'connected'
                            ? const Color(0xFF047857)
                            : (_serverStatus == 'checking' ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.storage_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'phpMyAdmin MySQL (db_keuangan)',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                              ),
                              Text(
                                _serverStatusMessage.isNotEmpty ? _serverStatusMessage : 'http://127.0.0.1:8085/Keuangan',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _serverStatus == 'connected' ? AppTheme.greenMain : AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Data tersimpan permanen di database MariaDB Termux di HP ini. Saat update APK atau install ulang, data Anda tidak akan pernah hilang!',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11.5, height: 1.4),
                    ),
                    if (_serverCounts != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCountPill('Transaksi', _serverCounts!['transaksi'] ?? 0),
                            _buildCountPill('Kategori', _serverCounts!['kategori'] ?? 0),
                            _buildCountPill('Hutang', _serverCounts!['hutang'] ?? 0),
                            _buildCountPill('Tabungan', _serverCounts!['tabungan'] ?? 0),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    TextField(
                      controller: _serverUrlController,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 12.5),
                      decoration: InputDecoration(
                        labelText: 'Alamat Server API phpMyAdmin',
                        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        hintText: 'http://127.0.0.1:8085/Keuangan/api',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_rounded, color: AppTheme.bluePrimary, size: 20),
                          tooltip: 'Simpan URL',
                          onPressed: _saveServerUrl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2-Column Symmetrical Grid Buttons (Standar MaoneArt)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _checkServer,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.bluePrimary,
                                side: const BorderSide(color: AppTheme.bluePrimary, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text('Cek Server', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _isSyncing ? null : _syncData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.greenMain,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _isSyncing
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.sync_rounded, size: 16),
                              label: Text(
                                _isSyncing ? 'Proses...' : 'Sinkronkan Data',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ==================== 5. FITUR UNGGULAN ====================
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
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Smart AI Financial Assistant (Chat Curhat)',
                description: 'Ceritakan transaksi, hutang, atau tabungan secara santai, AI otomatis menganalisis dan mencatatkannya.',
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
                iconColor: const Color(0xFFEC4899),
                title: 'Laporan Visual & Grafik Batang Rapi',
                description: 'Diagram Lingkaran kategori dan Grafik Batang Arus Kas Mingguan dengan tata letak proporsional.',
              ),
              const SizedBox(height: 20),

              // ==================== 5. INFORMASI SISTEM & PENGEMBANG ====================
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
                    _buildInfoRow('Nama Aplikasi', 'MaoneArt Keuangan'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Pengembang / Developer', 'Hermawan'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Tahun Rilis', '2026'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Platform', 'Android (Flutter + MySQL phpMyAdmin & SQLite)'),
                    const Divider(color: AppTheme.borderLight, height: 16),
                    _buildInfoRow('Status Rilis', 'v1.1.0 (AI Date Extraction & phpMyAdmin Sync)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  '© 2026 MaoneArt • Developer: Hermawan',
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

  Widget _buildCountPill(String label, dynamic count) {
    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF15803D)),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF166534), fontSize: 9.5, fontWeight: FontWeight.w500),
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
