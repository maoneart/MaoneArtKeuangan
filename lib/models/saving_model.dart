import '../utils/currency_formatter.dart';

class SavingDepositModel {
  final int? id;
  final int savingId;
  final DateTime depositDate;
  final double amount;
  final String? note;

  const SavingDepositModel({
    this.id,
    required this.savingId,
    required this.depositDate,
    required this.amount,
    this.note,
  });

  String get formattedAmount => CurrencyFormatter.formatRupiah(amount);
  String get formattedDate => AppDateFormatter.formatFull(depositDate);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_tabungan': savingId,
      'tanggal_setor': AppDateFormatter.toDbDate(depositDate),
      'jumlah_setor': amount,
      'keterangan': note,
    };
  }

  factory SavingDepositModel.fromMap(Map<String, dynamic> map) {
    return SavingDepositModel(
      id: map['id'] as int?,
      savingId: map['id_tabungan'] as int? ?? 0,
      depositDate: AppDateFormatter.fromDbDate(map['tanggal_setor']?.toString() ?? ''),
      amount: double.tryParse(map['jumlah_setor']?.toString() ?? '0') ?? 0.0,
      note: map['keterangan'] as String?,
    );
  }
}

class SavingModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double collectedAmount;
  final DateTime? dueDate;
  final String status; // 'berlangsung' atau 'tercapai'
  final String? note;
  final List<SavingDepositModel> deposits;

  const SavingModel({
    this.id,
    required this.name,
    required this.targetAmount,
    this.collectedAmount = 0.0,
    this.dueDate,
    this.status = 'berlangsung',
    this.note,
    this.deposits = const [],
  });

  bool get isAchieved => status.toLowerCase() == 'tercapai' || collectedAmount >= targetAmount;
  double get remainingTarget => (targetAmount - collectedAmount).clamp(0.0, double.infinity);
  double get progressPercentage => targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  String get savingName => name;
  String get formattedTarget => CurrencyFormatter.formatRupiah(targetAmount);
  String get formattedCollected => CurrencyFormatter.formatRupiah(collectedAmount);
  String get formattedRemaining => CurrencyFormatter.formatRupiah(remainingTarget);
  String get formattedDueDate => dueDate != null ? AppDateFormatter.formatFull(dueDate!) : 'Tanpa batas waktu';
  String get formattedTargetDate => formattedDueDate;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_tabungan': name,
      'target_jumlah': targetAmount,
      'saldo_terkumpul': collectedAmount,
      'tenggat_waktu': dueDate != null ? AppDateFormatter.toDbDate(dueDate!) : null,
      'status': status,
      'keterangan': note,
    };
  }

  factory SavingModel.fromMap(Map<String, dynamic> map, {List<SavingDepositModel> deposits = const []}) {
    return SavingModel(
      id: map['id'] as int?,
      name: map['nama_tabungan'] as String? ?? 'Tabungan Impian',
      targetAmount: double.tryParse(map['target_jumlah']?.toString() ?? '0') ?? 0.0,
      collectedAmount: double.tryParse(map['saldo_terkumpul']?.toString() ?? '0') ?? 0.0,
      dueDate: map['tenggat_waktu'] != null ? AppDateFormatter.fromDbDate(map['tenggat_waktu'].toString()) : null,
      status: map['status'] as String? ?? 'berlangsung',
      note: map['keterangan'] as String?,
      deposits: deposits,
    );
  }
}
