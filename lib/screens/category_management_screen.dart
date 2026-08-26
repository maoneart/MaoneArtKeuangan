import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'pengeluaran';
    String selectedColor = '#F43F5E';
    String selectedIcon = 'bi-bookmark';

    final colors = [
      '#10B981', '#06B6D4', '#3B82F6', '#8B5CF6',
      '#F43F5E', '#F59E0B', '#EAB308', '#EC4899',
      '#14B8A6', '#6366F1', '#A855F7', '#64748B',
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 16),
                  Text('TAMBAH KATEGORI BARU', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),

                  // Tipe Kategori
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pengeluaran'),
                          selected: selectedType == 'pengeluaran',
                          selectedColor: AppTheme.accentRose.withValues(alpha: 0.3),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = 'pengeluaran');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pemasukan'),
                          selected: selectedType == 'pemasukan',
                          selectedColor: AppTheme.accentEmerald.withValues(alpha: 0.3),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = 'pemasukan');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Nama Kategori
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nama Kategori (misal: Langganan Netflix)...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pilih Warna
                  Text('PILIH WARNA', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colors.map((c) {
                      final hex = c.replaceAll('#', '');
                      final color = Color(int.parse('FF$hex', radix: 16));
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2.5),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Pilih Ikon
                  Text('PILIH IKON', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: icons.map((ic) {
                      final isSelected = selectedIcon == ic;
                      final dummyCat = CategoryModel(name: '', type: selectedType, iconName: ic);
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = ic),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accentEmerald.withValues(alpha: 0.3) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppTheme.accentEmerald : Colors.white12),
                          ),
                          child: Icon(dummyCat.iconData, color: isSelected ? Colors.white : Colors.white60, size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final newCat = CategoryModel(
                        name: name,
                        type: selectedType,
                        colorHex: selectedColor,
                        iconName: selectedIcon,
                      );
                      await ref.read(financialControllerProvider.notifier).addCategory(newCat);
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Simpan Kategori', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
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
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('Kelola Kategori', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, ref),
        backgroundColor: AppTheme.accentEmerald,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Tambah Kategori', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: categoriesAsync.when(
        data: (cats) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final cat = cats[i];
              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(cat.iconData, color: cat.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            cat.isIncome ? 'Kategori Pemasukan (+)' : 'Kategori Pengeluaran (-)',
                            style: GoogleFonts.inter(color: cat.isIncome ? AppTheme.accentEmerald : AppTheme.accentRose, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (cat.id != null && cat.id! > 12)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: AppTheme.bgCard,
                              title: const Text('Hapus Kategori?'),
                              content: Text('Hapus kategori "${cat.name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose), child: const Text('Hapus')),
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
    );
  }
}
