import '../models/category_model.dart';

class CategoryResolver {
  static CategoryModel resolveCategory({
    required String note,
    String? categoryHint,
    int? categoryId,
    required String type, // 'pemasukan' or 'pengeluaran'
    required List<CategoryModel> categories,
  }) {
    if (categories.isEmpty) {
      return CategoryModel(id: 1, name: 'Umum', type: type);
    }

    // 1. Jika ID kategori spesifik diberikan dan valid
    if (categoryId != null && categoryId > 0) {
      final matchById = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => categories.first,
      );
      if (matchById.id == categoryId) return matchById;
    }

    final lowerNote = note.toLowerCase().trim();
    final lowerHint = (categoryHint ?? '').toLowerCase().trim();
    final combined = '$lowerNote $lowerHint';

    // 2. Pencocokan langsung dengan nama kategori di database
    if (lowerHint.isNotEmpty) {
      for (final c in categories) {
        if (c.type == type && (c.name.toLowerCase() == lowerHint ||
            c.name.toLowerCase().contains(lowerHint) ||
            lowerHint.contains(c.name.toLowerCase()))) {
          return c;
        }
      }
    }

    for (final c in categories) {
      if (c.type == type && (lowerNote.contains(c.name.toLowerCase()) || c.name.toLowerCase().contains(lowerNote))) {
        return c;
      }
    }

    // 3. Kamus Semantik Kata Kunci Cerdas (Smart Semantic Keyword Rules)
    if (type == 'pemasukan') {
      if (RegExp(r'\b(gaji|upah|salary|honor|thr|lembur|tunjangan|pesangon|gajian)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['gaji', 'upah', 'salary']);
      }
      if (RegExp(r'\b(usaha|jual|omset|dagang|toko|freelance|proyek|side\s*job|bisnis|profit|laba)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['usaha', 'sampingan', 'bisnis']);
      }
      if (RegExp(r'\b(investasi|saham|crypto|reksadana|dividen|deviden|emas|bunga|deposito)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['investasi', 'deviden', 'bunga']);
      }
      if (RegExp(r'\b(bonus|hadiah|giveaway|angpao|cashback|undian|reward|tips)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['bonus', 'hadiah', 'reward']);
      }
    } else {
      // Pengeluaran
      if (RegExp(r'\b(listrik|pln|token|pdam|air|tagihan|iuran|bpjs|pbb|retribusi|spaylater|gopaylater|paylater|kredivo|kartu\s*kredit|cicilan)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['listrik', 'tagihan', 'pembayaran']);
      }
      if (RegExp(r'\b(indihome|wifi|pulsa|paket\s*data|internet|kuota|telkomsel|indosat|xl|smartfren|tri|myrepublic|biznet|first\s*media)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['internet', 'pulsa', 'wifi', 'tagihan', 'listrik']);
      }
      if (RegExp(r'\b(bensin|pertalite|pertamax|solar|bbm|spbu|ojol|grab|gojek|maxim|parkir|tol|angkot|bus|kereta|tiket|transport)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['transportasi', 'bensin', 'kendaraan']);
      }
      if (RegExp(r'\b(makan|minum|resto|cafe|warteg|kopi|coffee|snack|jajan|sarapan|siang|malam|bakso|mie|nasi|ayam|es\s|teh\s|soto|gofood|grabfood|shopeefood)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['makan', 'minum', 'kuliner']);
      }
      if (RegExp(r'\b(belanja|pasar|supermarket|indomaret|alfamart|galon|gas|lpg|sayur|sabun|shampo|minyak|beras|telur|dapur|bulanan|harian)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['belanja', 'harian', 'kebutuhan']);
      }
      if (RegExp(r'\b(servis|service|bengkel|oli|ban|cuci\s*motor|cuci\s*mobil|reparasi|onderdil|sparepart)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['servis', 'bengkel', 'transportasi']);
      }
      if (RegExp(r'\b(obat|dokter|klinik|apotek|rumah\s*sakit|puskesmas|vitamin|rapid|periksa|gigi|medis|sehat)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['kesehatan', 'medis', 'obat']);
      }
      if (RegExp(r'\b(spp|sekolah|kuliah|buku|kursus|les|pelatihan|ujian|seragam|alat\s*tulis|atk|pendidikan)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['pendidikan', 'sekolah', 'kursus']);
      }
      if (RegExp(r'\b(sedekah|infaq|infak|zakat|donasi|amal|masjid|mushola|tahlil|pengajian|santunan|sosial)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['sedekah', 'infaq', 'zakat', 'sosial']);
      }
      if (RegExp(r'\b(hiburan|liburan|nonton|bioskop|cinema|hotel|villa|wisata|game|topup|steam|netflix|spotify|youtube)\b').hasMatch(combined)) {
        return _findCategoryByKeywords(categories, type, ['hiburan', 'liburan', 'rekreasi']);
      }
    }

    // 4. Fallback: kategori pertama yang sesuai dengan tipe
    return categories.firstWhere(
      (c) => c.type == type,
      orElse: () => categories.first,
    );
  }

  static CategoryModel _findCategoryByKeywords(List<CategoryModel> categories, String type, List<String> keywords) {
    for (final kw in keywords) {
      for (final c in categories) {
        if (c.type == type && c.name.toLowerCase().contains(kw.toLowerCase())) {
          return c;
        }
      }
    }
    return categories.firstWhere(
      (c) => c.type == type,
      orElse: () => categories.first,
    );
  }
}
