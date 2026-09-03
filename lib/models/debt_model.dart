import '../utils/currency_formatter.dart';

class DebtPaymentModel {
  final int? id;
  final int debtId;
  final DateTime paymentDate;
  final double amount;
  final String? note;

  const DebtPaymentModel({
    this.id,
    required this.debtId,
    required this.paymentDate,
    required this.amount,
    this.note,
  });

  String get formattedAmount => CurrencyFormatter.formatRupiah(amount);
  String get formattedDate => AppDateFormatter.formatFull(paymentDate);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_hutang': debtId,
      'tanggal_bayar': AppDateFormatter.toDbDate(paymentDate),
      'jumlah_bayar': amount,
      'keterangan': note,
    };
  }

  factory DebtPaymentModel.fromMap(Map<String, dynamic> map) {
    return DebtPaymentModel(
      id: map['id'] as int?,
      debtId: map['id_hutang'] as int? ?? 0,
      paymentDate: AppDateFormatter.fromDbDate(map['tanggal_bayar']?.toString() ?? ''),
      amount: double.tryParse(map['jumlah_bayar']?.toString() ?? '0') ?? 0.0,
      note: map['keterangan'] as String?,
    );
  }
}

class DebtModel {
  final int? id;
  final String debtorName;
  final String type; // 'hutang' (kita berhutang) atau 'piutang' (orang berhutang ke kita)
  final String categoryDebt;
  final double totalAmount;
  final double remainingAmount;
  final String status; // 'belum_lunas' atau 'lunas'
  final DateTime borrowDate;
  final DateTime? dueDate;
  final int tenorMonths; // Durasi tenor cicilan dalam bulan (misal: 33 bulan)
  final int dueDay; // Tanggal jatuh tempo rutin bulanan (1 - 31, misal: 15)
  final double monthlyInstallment; // Estimasi nominal cicilan per bulan
  final String? note;
  final List<DebtPaymentModel> payments;

  const DebtModel({
    this.id,
    required this.debtorName,
    required this.type,
    this.categoryDebt = 'Perorangan / Teman',
    required this.totalAmount,
    required this.remainingAmount,
    this.status = 'belum_lunas',
    required this.borrowDate,
    this.dueDate,
    this.tenorMonths = 0,
    this.dueDay = 0,
    this.monthlyInstallment = 0.0,
    this.note,
    this.payments = const [],
  });

  bool get isDebt => type.toLowerCase() == 'hutang';
  bool get isReceivable => type.toLowerCase() == 'piutang';
  bool get isSettled => status.toLowerCase() == 'lunas' || remainingAmount <= 0;
  bool get isInstallment => tenorMonths > 0 || dueDay > 0 || monthlyInstallment > 0;

  double get paidAmount => totalAmount - remainingAmount;
  double get progressPercentage => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
  double get calculatedMonthlyInstallment => monthlyInstallment > 0 ? monthlyInstallment : (tenorMonths > 0 ? (totalAmount / tenorMonths) : 0.0);

  String get formattedTotal => CurrencyFormatter.formatRupiah(totalAmount);
  String get formattedRemaining => CurrencyFormatter.formatRupiah(remainingAmount);
  String get formattedPaid => CurrencyFormatter.formatRupiah(paidAmount);
  String get formattedMonthlyInstallment => CurrencyFormatter.formatRupiah(calculatedMonthlyInstallment);
  String get formattedBorrowDate => AppDateFormatter.formatFull(borrowDate);
  String get formattedDueDate => dueDate != null ? AppDateFormatter.formatFull(dueDate!) : 'Tidak ada tenggat';
  
  String get formattedDueDayInfo {
    if (dueDay > 0) {
      if (dueDate != null && tenorMonths > 0) {
        return 'Tiap tgl $dueDay (Lunas: ${AppDateFormatter.formatMonthYear(dueDate!)})';
      }
      return 'Tiap tgl $dueDay setiap bulan';
    }
    return dueDate != null ? AppDateFormatter.formatShort(dueDate!) : 'Tanpa batas waktu';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_penghutang': debtorName,
      'tipe': type,
      'kategori_hutang': categoryDebt,
      'total_hutang': totalAmount,
      'sisa_hutang': remainingAmount,
      'status': status,
      'tanggal_pinjam': AppDateFormatter.toDbDate(borrowDate),
      'tenggat_waktu': dueDate != null ? AppDateFormatter.toDbDate(dueDate!) : null,
      'tenor_bulan': tenorMonths,
      'jatuh_tempo_hari': dueDay,
      'cicilan_per_bulan': monthlyInstallment,
      'keterangan': note,
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map, {List<DebtPaymentModel> payments = const []}) {
    return DebtModel(
      id: map['id'] as int?,
      debtorName: map['nama_penghutang'] as String? ?? 'Nama',
      type: map['tipe'] as String? ?? 'hutang',
      categoryDebt: map['kategori_hutang'] as String? ?? 'Perorangan',
      totalAmount: double.tryParse(map['total_hutang']?.toString() ?? '0') ?? 0.0,
      remainingAmount: double.tryParse(map['sisa_hutang']?.toString() ?? '0') ?? 0.0,
      status: map['status'] as String? ?? 'belum_lunas',
      borrowDate: AppDateFormatter.fromDbDate(map['tanggal_pinjam']?.toString() ?? ''),
      dueDate: map['tenggat_waktu'] != null ? AppDateFormatter.fromDbDate(map['tenggat_waktu'].toString()) : null,
      tenorMonths: int.tryParse(map['tenor_bulan']?.toString() ?? '0') ?? 0,
      dueDay: int.tryParse(map['jatuh_tempo_hari']?.toString() ?? '0') ?? 0,
      monthlyInstallment: double.tryParse(map['cicilan_per_bulan']?.toString() ?? '0') ?? 0.0,
      note: map['keterangan'] as String?,
      payments: payments,
    );
  }
}
