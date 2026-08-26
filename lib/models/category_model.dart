import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final String type; // 'pemasukan' atau 'pengeluaran'
  final String iconName;
  final String colorHex;

  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.iconName = 'bi-bookmark',
    this.colorHex = '#10B981',
  });

  bool get isIncome => type.toLowerCase() == 'pemasukan';
  bool get isExpense => type.toLowerCase() == 'pengeluaran';

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    }
  }

  static IconData mapBootstrapIcon(String name) {
    switch (name.toLowerCase()) {
      case 'bi-wallet2':
        return Icons.account_balance_wallet_rounded;
      case 'bi-briefcase':
        return Icons.work_rounded;
      case 'bi-piggy-bank':
      case 'bi-piggy-bank-fill':
        return Icons.savings_rounded;
      case 'bi-gift':
        return Icons.card_giftcard_rounded;
      case 'bi-cup-hot':
        return Icons.restaurant_rounded;
      case 'bi-cart3':
        return Icons.shopping_cart_rounded;
      case 'bi-fuel-pump':
        return Icons.local_gas_station_rounded;
      case 'bi-lightning-charge':
        return Icons.bolt_rounded;
      case 'bi-controller':
        return Icons.sports_esports_rounded;
      case 'bi-heart-pulse':
        return Icons.medical_services_rounded;
      case 'bi-journal-bookmark':
        return Icons.school_rounded;
      case 'bi-bookmark':
        return Icons.bookmark_rounded;
      case 'bi-house':
        return Icons.home_rounded;
      case 'bi-car':
        return Icons.directions_car_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  IconData get iconData => mapBootstrapIcon(iconName);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_kategori': name,
      'tipe': type,
      'ikon': iconName,
      'warna': colorHex,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['nama_kategori'] as String? ?? 'Kategori',
      type: map['tipe'] as String? ?? 'pengeluaran',
      iconName: map['ikon'] as String? ?? 'bi-bookmark',
      colorHex: map['warna'] as String? ?? '#10B981',
    );
  }
}
