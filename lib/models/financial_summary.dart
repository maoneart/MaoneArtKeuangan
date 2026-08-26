import '../utils/currency_formatter.dart';

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double totalDebt;
  final double totalReceivable;
  final double totalSavings;

  const FinancialSummary({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.netBalance = 0.0,
    this.totalDebt = 0.0,
    this.totalReceivable = 0.0,
    this.totalSavings = 0.0,
  });

  String get formattedIncome => CurrencyFormatter.formatRupiah(totalIncome);
  String get formattedExpense => CurrencyFormatter.formatRupiah(totalExpense);
  String get formattedBalance => CurrencyFormatter.formatRupiah(netBalance);
  String get formattedDebt => CurrencyFormatter.formatRupiah(totalDebt);
  String get formattedReceivable => CurrencyFormatter.formatRupiah(totalReceivable);
  String get formattedSavings => CurrencyFormatter.formatRupiah(totalSavings);
}
