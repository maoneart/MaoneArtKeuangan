import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  /// Format angka integer/double menjadi string Rupiah (misal: 1500000 -> "Rp 1.500.000")
  static String formatRupiah(num amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format angka ribuan dengan titik tanpa 'Rp ' (misal: 1500000 -> "1.500.000")
  static String formatThousands(num amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount).replaceAll(',', '.');
  }

  /// Format angka kompak (misal: 1500000 -> "Rp 1,5 jt")
  static String formatCompact(num amount) {
    return _compactFormatter.format(amount);
  }

  /// Parse string input Rupiah menjadi double/int
  static double parseRupiah(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return 0.0;
    return double.tryParse(clean) ?? 0.0;
  }
}

/// Real-time TextInputFormatter yang otomatis menambahkan titik (.) saat mengetik angka nominal
/// Contoh: ketik 1000000 langsung menjadi 1.000.000
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Ambil hanya digit angka
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    final int value = int.tryParse(digitsOnly) ?? 0;
    final formatter = NumberFormat('#,###', 'id_ID');
    final String formatted = formatter.format(value).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AppDateFormatter {
  static final DateFormat _indoFull = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _indoShort = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _dbFormat = DateFormat('yyyy-MM-dd');

  static String formatFull(DateTime date) {
    try {
      return _indoFull.format(date);
    } catch (_) {
      return '${date.day}-${date.month}-${date.year}';
    }
  }

  static String formatShort(DateTime date) {
    try {
      return _indoShort.format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  static String formatMonthYear(DateTime date) {
    try {
      return _monthYear.format(date);
    } catch (_) {
      return '${date.month}-${date.year}';
    }
  }

  static String toDbDate(DateTime date) {
    return _dbFormat.format(date);
  }

  static DateTime fromDbDate(String dateStr) {
    try {
      return _dbFormat.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }
}
