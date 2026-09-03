import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import 'api_key_tutorial_screen.dart';
import 'onboarding_screen.dart';
import 'about_screen.dart';
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

  // ==================== MODAL 1: PENGATURAN GEMINI API ====================
  void _showGeminiSettingsModal(BuildContext context, bool hasSavedKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSavedKey = ref.watch(geminiApiKeyProvider);
            final isKeyActive = currentSavedKey.trim().isNotEmpty;
            final bottomInsets = MediaQuery.of(context).viewInsets.bottom;
            final bottomPadding = MediaQuery.of(context).padding.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInsets),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomPadding),
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF0047CC)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengaturan Google Gemini AI',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                              ),
                              Text(
                                isKeyActive ? 'Status: Kunci AI Aktif ✅' : 'Status: Belum Terhubung ⚠️',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: isKeyActive ? AppTheme.greenMain : const Color(0xFFD97706),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Kunci Gemini API digunakan untuk fitur "Chat AI" agar asisten dapat menganalisis dan mencatat curhat keuangan Anda secara otomatis.',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12, height: 1.45),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscureKey,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'Tempel API Key (AIzaSy... / AQ...)',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppTheme.textMuted),
                          onPressed: () => setModalState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Symmetrical 2-Column Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(modalCtx);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ApiKeyTutorialScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6366F1),
                                side: const BorderSide(color: Color(0xFFC7D2FE)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.help_outline_rounded, size: 16),
                              label: Text('Panduan Key', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _saveApiKey();
                                Navigator.pop(modalCtx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.bluePrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.save_rounded, size: 16),
                              label: Text('Simpan Key', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isKeyActive) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: TextButton.icon(
                          onPressed: () {
                            _apiKeyController.clear();
                            _saveApiKey();
                            Navigator.pop(modalCtx);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.redMain, size: 16),
                          label: Text(
                            'Hapus API Key dari Perangkat & Database',
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.redMain, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== MODAL 2: PENGATURAN PHPMYADMIN ====================
  void _showPhpMyAdminSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInsets = MediaQuery.of(context).viewInsets.bottom;
            final bottomPadding = MediaQuery.of(context).padding.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInsets),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomPadding),
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storage_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Database phpMyAdmin (Termux)',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                  ),
                                  Text(
                                    _serverStatus == 'connected' ? 'Status: Terhubung 🟢' : 'Status: Offline 🔴',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: _serverStatus == 'connected' ? AppTheme.greenMain : AppTheme.redMain,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_serverCounts != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 12),
                        ],

                        Text(
                          'Alamat Endpoint REST API phpMyAdmin lokal:',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11.5),
                        ),
                        const SizedBox(height: 6),

                        TextField(
                          controller: _serverUrlController,
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'http://127.0.0.1:8085/Keuangan/api',
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
                        const SizedBox(height: 16),

                        // Symmetrical 2-Column Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _checkServer();
                                    setModalState(() {});
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.bluePrimary,
                                    side: const BorderSide(color: AppTheme.bluePrimary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: Text('Uji Koneksi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: _isSyncing
                                      ? null
                                      : () {
                                          Navigator.pop(modalCtx);
                                          _syncData();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.greenMain,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== MODAL 3: RESET / KOSONGKAN DATA ====================
  void _showResetDataModal(BuildContext context) async {
    final confirmed = await MaoneArtModal.showConfirmModal(
      context: context,
      title: 'Kosongkan Seluruh Data?',
      message: 'Seluruh data catatan transaksi, hutang piutang, dan tabungan akan di-reset dari nol (0).\n\nKategori dan pengaturan API Key akan tetap tersimpan.',
      confirmText: 'Ya, Kosongkan',
      cancelText: 'Batal',
      accentColor: AppTheme.redMain,
      icon: Icons.delete_sweep_rounded,
      isDanger: true,
    );

    if (confirmed == true) {
      await ref.read(financialControllerProvider.notifier).resetAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buku kas dan data transaksi telah direset ke 0! 🧹'),
            backgroundColor: AppTheme.redMain,
          ),
        );
      }
    }
  }

  // ==================== MAIN SCREEN BUILD ====================
  @override
  Widget build(BuildContext context) {
    final savedKey = ref.watch(geminiApiKeyProvider);
    final hasSavedKey = savedKey.trim().isNotEmpty;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bottomPadding = MediaQuery.of(context).padding.bottom + (isLandscape ? 50 : 160);

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
          'Pengaturan',
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
              // ==================== 1. HERO BRANDING & QUICK STATUS ====================
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.bluePrimary.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet_rounded, size: 30, color: AppTheme.bluePrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MaoneArt Keuangan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Developer: Hermawan • v1.1.8',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppTheme.borderLight, height: 1),
                    const SizedBox(height: 12),

                    // Quick Live Status Badges
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: hasSavedKey ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: hasSavedKey ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 14, color: hasSavedKey ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    hasSavedKey ? 'AI: Aktif ✅' : 'AI: Belum ⚠️',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: hasSavedKey ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _serverStatus == 'connected' ? const Color(0xFFF0FDF4) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _serverStatus == 'connected' ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.storage_rounded, size: 14, color: _serverStatus == 'connected' ? const Color(0xFF16A34A) : AppTheme.redMain),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _serverStatus == 'connected' ? 'Server: Aktif 🟢' : 'Server: Off 🔴',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: _serverStatus == 'connected' ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ==================== SECTION 1: KECERDASAN BUATAN & AI ====================
              _buildSectionTitle('KECERDASAN BUATAN & AI'),
              _buildMenuCard(
                icon: Icons.auto_awesome_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF0047CC)]),
                title: 'Google Gemini AI',
                subtitle: 'Atur API Key, koneksi AI & curhat transaksi',
                badgeText: hasSavedKey ? 'Aktif' : 'Belum Diatur',
                badgeColor: hasSavedKey ? AppTheme.greenSoft : const Color(0xFFFEF3C7),
                badgeTextColor: hasSavedKey ? const Color(0xFF047857) : const Color(0xFFD97706),
                onTap: () => _showGeminiSettingsModal(context, hasSavedKey),
              ),
              const SizedBox(height: 8),
              _buildMenuCard(
                icon: Icons.menu_book_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)]),
                title: 'Panduan Gemini API Key',
                subtitle: 'Tutorial langkah demi langkah buat key gratis',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ApiKeyTutorialScreen()),
                ),
              ),
              const SizedBox(height: 18),

              // ==================== SECTION 2: DATABASE & SINKRONISASI ====================
              _buildSectionTitle('DATABASE & SINKRONISASI'),
              _buildMenuCard(
                icon: Icons.storage_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                title: 'Database phpMyAdmin (MySQL)',
                subtitle: 'Alamat server Termux, uji koneksi & sinkronisasi',
                badgeText: _serverStatus == 'connected' ? 'Terhubung' : 'Offline',
                badgeColor: _serverStatus == 'connected' ? AppTheme.greenSoft : const Color(0xFFFEE2E2),
                badgeTextColor: _serverStatus == 'connected' ? const Color(0xFF047857) : const Color(0xFFDC2626),
                onTap: () => _showPhpMyAdminSettingsModal(context),
              ),
              const SizedBox(height: 18),

              // ==================== SECTION 3: PANDUAN & KELOLA DATA ====================
              _buildSectionTitle('PANDUAN & MANAJEMEN DATA'),
              _buildMenuCard(
                icon: Icons.slideshow_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                title: 'Panduan & Intro Aplikasi',
                subtitle: '4 Slide interaktif penjelasan fitur & tips buku kas',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen(isFromSettings: true)),
                ),
              ),
              const SizedBox(height: 8),
              _buildMenuCard(
                icon: Icons.delete_sweep_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
                title: 'Reset / Kosongkan Data Transaksi',
                subtitle: 'Bersihkan seluruh catatan kas untuk mulai dari 0',
                isDestructive: true,
                onTap: () => _showResetDataModal(context),
              ),
              const SizedBox(height: 18),

              // ==================== SECTION 4: TENTANG ====================
              _buildSectionTitle('INFORMASI APLIKASI'),
              _buildMenuCard(
                icon: Icons.info_outline_rounded,
                iconGradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                title: 'Tentang MaoneArt Keuangan',
                subtitle: 'Pengembang (Hermawan), fitur lengkap & info rilis',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              const SizedBox(height: 24),

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

  Widget _buildMenuCard({
    required IconData icon,
    required LinearGradient iconGradient,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: isDestructive ? AppTheme.redMain : AppTheme.textDark,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor ?? AppTheme.blueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.plusJakartaSans(
                                color: badgeTextColor ?? AppTheme.bluePrimary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
        ),
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
