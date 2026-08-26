import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/quick_add_modal.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'pengeluaran';
    String selectedColor = '#DC2626';
    String selectedIcon = 'bi-bookmark';

    final colors = [
      '#059669', '#0284C7', '#0047CC', '#7C3AED',
      '#DC2626', '#D97706', '#EAB308', '#DB2777',
      '#0D9488', '#4F46E5', '#9333EA', '#475569',
    ];

    final icons = [
      'bi-wallet2', 'bi-briefcase', 'bi-piggy-bank', 'bi-gift',
      'bi-cup-hot', 'bi-cart3', 'bi-fuel-pump', 'bi-lightning-charge',
      'bi-controller', 'bi-heart-pulse', 'bi-journal-bookmark', 'bi-bookmark',
      'bi-house', 'bi-car',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final bottomSafe = MediaQuery.of(context).padding.bottom;

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: bottomInset + bottomSafe + 24,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 16),
                      Text(
                        'TAMBAH KATEGORI BARU',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Tipe Kategori
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedType = 'pengeluaran'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == 'pengeluaran' ? AppTheme.redMain : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Pengeluaran (-)',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: selectedType == 'pengeluaran' ? Colors.white : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedType = 'pemasukan'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == 'pemasukan' ? AppTheme.greenMain : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Pemasukan (+)',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: selectedType == 'pemasukan' ? Colors.white : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Nama Kategori
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nama kategori baru...',
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pilih Warna
                      Text('PILIH WARNA', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors.map((hex) {
                          final isSelected = selectedColor == hex;
                          final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = hex),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: AppTheme.bluePrimary, width: 3) : null,
                              ),
                              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Pilih Ikon
                      Text('PILIH IKON', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: icons.map((iconName) {
                          final isSelected = selectedIcon == iconName;
                          final iconData = CategoryModel.mapBootstrapIcon(iconName);
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedIcon = iconName),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.bluePrimary.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: AppTheme.bluePrimary, width: 1.5) : null,
                              ),
                              child: Icon(iconData, color: isSelected ? AppTheme.bluePrimary : AppTheme.textMuted, size: 20),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nama kategori')));
                            return;
                          }
                          final cat = CategoryModel(
                            name: name,
                            type: selectedType,
                            iconName: selectedIcon,
                            colorHex: selectedColor,
                          );
                          await ref.read(financialControllerProvider.notifier).addCategory(cat);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori baru berhasil ditambahkan!')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bluePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Simpan Kategori', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text('Kelola Kategori', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, ref),
        backgroundColor: AppTheme.bluePrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Tambah Kategori', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: SafeArea(
        child: categoriesAsync.when(
          data: (cats) {
            final bottomPadding = MediaQuery.of(context).padding.bottom + 160;
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final cat = cats[i];
                return GlassCard(
                  onTap: () => QuickAddModal.show(context, preSelectedCategory: cat, type: cat.type),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(cat.iconData, color: cat.color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name, style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              cat.isIncome ? 'Kategori Pemasukan (+)' : 'Kategori Pengeluaran (-)',
                              style: GoogleFonts.plusJakartaSans(color: cat.isIncome ? AppTheme.greenMain : AppTheme.redMain, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.bluePrimary, size: 20),
                        tooltip: 'Catat Transaksi Ini',
                        onPressed: () => QuickAddModal.show(context, preSelectedCategory: cat, type: cat.type),
                      ),
                      if (cat.id != null && cat.id! > 12)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted, size: 18),
                          onPressed: () async {
                            final confirm = await showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppTheme.cardBg,
                                title: const Text('Hapus Kategori?'),
                                content: Text('Hapus kategori "${cat.name}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                  ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redMain), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref.read(financialControllerProvider.notifier).deleteCategory(cat.id!);
                            }
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Gagal memuat kategori')),
        ),
      ),
    );
  }
}
