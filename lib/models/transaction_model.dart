import 'category_model.dart';
import '../utils/currency_formatter.dart';

class TransactionModel {
  final int? id;
  final DateTime date;
  final String type; // 'pemasukan' atau 'pengeluaran'
  final int categoryId;
  final double amount;
  final String? note;
  final CategoryModel? category;

  const TransactionModel({
    this.id,
    required this.date,
    required this.type,
    required this.categoryId,
    required this.amount,
    this.note,
    this.category,
  });

  bool get isIncome => type.toLowerCase() == 'pemasukan';
  bool get isExpense => type.toLowerCase() == 'pengeluaran';

  String get formattedAmount => CurrencyFormatter.formatRupiah(amount);
  String get formattedDate => AppDateFormatter.formatFull(date);
  String get formattedShortDate => AppDateFormatter.formatShort(date);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal': AppDateFormatter.toDbDate(date),
      'tipe': type,
      'id_kategori': categoryId,
      'jumlah': amount,
      'keterangan': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, {CategoryModel? category}) {
    return TransactionModel(
      id: map['id'] as int?,
      date: AppDateFormatter.fromDbDate(map['tanggal']?.toString() ?? ''),
      type: map['tipe'] as String? ?? 'pengeluaran',
      categoryId: map['id_kategori'] as int? ?? 1,
      amount: double.tryParse(map['jumlah']?.toString() ?? '0') ?? 0.0,
      note: map['keterangan'] as String?,
      category: category ?? (map['nama_kategori'] != null ? CategoryModel.fromMap(map) : null),
    );
  }
}
