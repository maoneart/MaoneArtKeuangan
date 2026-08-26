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
    switch (name.toLowerCase().trim()) {
      // Keagamaan, Sedekah, Tahlil & Sosial
      case 'bi-heart':
      case 'bi-heart-fill':
      case 'bi-hand-thumbs-up':
      case 'sedekah':
      case 'infaq':
        return Icons.volunteer_activism_rounded;
      case 'bi-book-half':
      case 'bi-book':
      case 'tahlil':
      case 'pengajian':
      case 'quran':
        return Icons.auto_stories_rounded;
      case 'bi-moon-stars':
      case 'masjid':
      case 'zakat':
        return Icons.mosque_rounded;
      case 'bi-people':
      case 'bi-people-fill':
      case 'sosial':
        return Icons.groups_rounded;

      // Pajak, Keuangan & Bisnis
      case 'bi-receipt':
      case 'pajak':
      case 'pbb':
        return Icons.receipt_long_rounded;
      case 'bi-bank':
      case 'bi-bank2':
        return Icons.account_balance_rounded;
      case 'bi-cash-coin':
      case 'bi-coin':
      case 'investasi':
        return Icons.monetization_on_rounded;
      case 'bi-graph-up-arrow':
      case 'saham':
        return Icons.trending_up_rounded;
      case 'bi-wallet2':
      case 'bi-wallet':
        return Icons.account_balance_wallet_rounded;
      case 'bi-briefcase':
      case 'gaji':
      case 'kerja':
        return Icons.work_rounded;
      case 'bi-piggy-bank':
      case 'bi-piggy-bank-fill':
      case 'tabungan':
        return Icons.savings_rounded;
      case 'bi-credit-card':
      case 'bi-credit-card-2-front':
        return Icons.credit_card_rounded;

      // Belanja, Makanan & Kebutuhan Rumah
      case 'bi-cup-hot':
      case 'makan':
      case 'minum':
        return Icons.restaurant_rounded;
      case 'bi-cart3':
      case 'bi-cart':
      case 'belanja':
        return Icons.shopping_cart_rounded;
      case 'bi-bag':
      case 'bi-bag-fill':
        return Icons.shopping_bag_rounded;
      case 'bi-shop':
      case 'pasar':
      case 'warung':
        return Icons.storefront_rounded;
      case 'bi-gift':
      case 'hadiah':
        return Icons.card_giftcard_rounded;
      case 'bi-house':
      case 'bi-house-door':
      case 'rumah':
        return Icons.home_rounded;
      case 'bi-basket':
        return Icons.shopping_basket_rounded;

      // Utilitas & Tagihan
      case 'bi-lightning-charge':
      case 'listrik':
      case 'token':
        return Icons.bolt_rounded;
      case 'bi-droplet':
      case 'air':
      case 'pdam':
        return Icons.water_drop_rounded;
      case 'bi-wifi':
      case 'internet':
        return Icons.wifi_rounded;
      case 'bi-phone':
      case 'pulsa':
      case 'kuota':
        return Icons.phone_android_rounded;

      // Kendaraan & Transportasi
      case 'bi-fuel-pump':
      case 'bensin':
      case 'spbu':
        return Icons.local_gas_station_rounded;
      case 'bi-car':
      case 'bi-car-front':
      case 'mobil':
        return Icons.directions_car_rounded;
      case 'bi-bicycle':
      case 'motor':
        return Icons.two_wheeler_rounded;
      case 'bi-tools':
      case 'bi-wrench':
      case 'servis':
      case 'bengkel':
        return Icons.build_rounded;
      case 'bi-airplane':
      case 'pesawat':
      case 'travel':
        return Icons.flight_takeoff_rounded;

      // Kesehatan & Obat
      case 'bi-heart-pulse':
      case 'bi-hospital':
      case 'kesehatan':
      case 'dokter':
        return Icons.local_hospital_rounded;
      case 'bi-capsule':
      case 'obat':
      case 'apotek':
        return Icons.medication_rounded;

      // Pendidikan & Anak
      case 'bi-journal-bookmark':
      case 'bi-mortarboard':
      case 'sekolah':
      case 'kuliah':
      case 'spp':
        return Icons.school_rounded;
      case 'bi-emoji-smile':
      case 'anak':
      case 'keluarga':
        return Icons.family_restroom_rounded;

      // Hiburan, Hobi & Olahraga
      case 'bi-controller':
      case 'game':
        return Icons.sports_esports_rounded;
      case 'bi-film':
      case 'bioskop':
        return Icons.movie_rounded;
      case 'bi-music-note-beamed':
      case 'musik':
        return Icons.music_note_rounded;
      case 'bi-dribbble':
      case 'olahraga':
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'bi-sun':
      case 'liburan':
      case 'pantai':
        return Icons.beach_access_rounded;

      case 'bi-bookmark':
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
