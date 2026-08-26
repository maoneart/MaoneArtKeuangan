import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/glass_card.dart';
import '../widgets/quick_add_modal.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currentMonth = ref.watch(selectedMonthProvider);
    final currentFilter = ref.watch(transactionTypeFilterProvider);

    final parts = currentMonth.split('-');
    final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final periodLabel = AppDateFormatter.formatMonthYear(monthDate);

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          'Daftar Transaksi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
        actions: [
          // Filter Periode Bulan
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: monthDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                final newMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
                ref.read(selectedMonthProvider.notifier).state = newMonth;
              }
            },
            icon: const Icon(Icons.calendar_month_rounded, color: AppTheme.bluePrimary, size: 16),
            label: Text(
              periodLabel,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickAddModal.show(context),
        backgroundColor: AppTheme.bluePrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Catat Transaksi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Box & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => ref.read(transactionSearchQueryProvider.notifier).state = val,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi atau kategori...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(transactionSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.bluePrimary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Tipe Chips: Semua, Pemasukan, Pengeluaran
                  Row(
                    children: [
                      _buildFilterChip('Semua', 'semua', currentFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pemasukan (+)', 'pemasukan', currentFilter, activeColor: AppTheme.greenMain),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pengeluaran (-)', 'pengeluaran', currentFilter, activeColor: AppTheme.redMain),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Transaksi List
            Expanded(
              child: transactionsAsync.when(
                data: (txs) {
                  if (txs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, color: AppTheme.textLight, size: 56),
                          const SizedBox(height: 12),
                          Text('Tidak ada transaksi ditemukan', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  final bottomPadding = MediaQuery.of(context).padding.bottom + 160;
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final tx = txs[i];
                      return Dismissible(
                        key: Key('tx_${tx.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(color: AppTheme.redMain, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: AppTheme.cardBg,
                              title: const Text('Hapus Transaksi?'),
                              content: Text('Hapus catatan ${tx.category?.name ?? 'transaksi'} senilai ${tx.formattedAmount}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redMain),
                                  child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          ref.read(financialControllerProvider.notifier).deleteTransaction(tx.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaksi berhasil dihapus')),
                          );
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (tx.category?.color ?? AppTheme.bluePrimary).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  tx.category?.iconData ?? Icons.receipt_rounded,
                                  color: tx.category?.color ?? AppTheme.bluePrimary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.note != null && tx.note!.isNotEmpty ? tx.note! : (tx.category?.name ?? (tx.isIncome ? 'Pemasukan' : 'Pengeluaran')),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx.formattedFullDate} • ${tx.category?.name ?? "Umum"}',
                                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx.isIncome ? '+' : '-'} ${tx.formattedAmount}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: tx.isIncome ? AppTheme.greenMain : AppTheme.redMain,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Gagal memuat daftar transaksi')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, {Color? activeColor}) {
    final isSelected = current == value;
    final color = activeColor ?? AppTheme.bluePrimary;

    return GestureDetector(
      onTap: () => ref.read(transactionTypeFilterProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : AppTheme.borderLight, width: isSelected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? color : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
