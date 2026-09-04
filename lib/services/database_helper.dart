import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';
import '../models/saving_model.dart';
import '../models/financial_summary.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('maoneart_keuangan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onOpen: _checkAndMigrateTables,
    );
  }

  Future<void> _checkAndMigrateTables(Database db) async {
    try {
      final hutangInfo = await db.rawQuery("PRAGMA table_info(hutang)");
      final cols = hutangInfo.map((row) => row['name'].toString()).toSet();
      if (!cols.contains('tenor_bulan')) {
        await db.execute("ALTER TABLE hutang ADD COLUMN tenor_bulan INTEGER DEFAULT 0");
      }
      if (!cols.contains('jatuh_tempo_hari')) {
        await db.execute("ALTER TABLE hutang ADD COLUMN jatuh_tempo_hari INTEGER DEFAULT 0");
      }
      if (!cols.contains('cicilan_per_bulan')) {
        await db.execute("ALTER TABLE hutang ADD COLUMN cicilan_per_bulan REAL DEFAULT 0.0");
      }

      // Bersihkan transaksi duplikat otomatis saat aplikasi dibuka
      await db.rawDelete('''
        DELETE FROM transaksi 
        WHERE id NOT IN (
          SELECT MIN(id) 
          FROM transaksi 
          GROUP BY strftime('%Y-%m-%d', tanggal), jumlah, TRIM(LOWER(keterangan))
        )
      ''');
    } catch (_) {}
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Kategori
    await db.execute('''
      CREATE TABLE kategori (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kategori TEXT NOT NULL,
        tipe TEXT NOT NULL,
        ikon TEXT DEFAULT 'bi-bookmark',
        warna TEXT DEFAULT '#10B981',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Tabel Transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        tipe TEXT NOT NULL,
        id_kategori INTEGER NOT NULL,
        jumlah REAL NOT NULL,
        keterangan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_kategori) REFERENCES kategori (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel Hutang & Piutang
    await db.execute('''
      CREATE TABLE hutang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_penghutang TEXT NOT NULL,
        tipe TEXT NOT NULL,
        kategori_hutang TEXT DEFAULT 'Perorangan / Teman',
        total_hutang REAL NOT NULL,
        sisa_hutang REAL NOT NULL,
        status TEXT DEFAULT 'belum_lunas',
        tanggal_pinjam TEXT NOT NULL,
        tenggat_waktu TEXT,
        tenor_bulan INTEGER DEFAULT 0,
        jatuh_tempo_hari INTEGER DEFAULT 0,
        cicilan_per_bulan REAL DEFAULT 0.0,
        keterangan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 4. Tabel Pembayaran Hutang
    await db.execute('''
      CREATE TABLE pembayaran_hutang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_hutang INTEGER NOT NULL,
        tanggal_bayar TEXT NOT NULL,
        jumlah_bayar REAL NOT NULL,
        keterangan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_hutang) REFERENCES hutang (id) ON DELETE CASCADE
      )
    ''');

    // 5. Tabel Tabungan & Target Impian
    await db.execute('''
      CREATE TABLE tabungan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_tabungan TEXT NOT NULL,
        target_jumlah REAL NOT NULL,
        saldo_terkumpul REAL DEFAULT 0.0,
        tenggat_waktu TEXT,
        status TEXT DEFAULT 'berlangsung',
        keterangan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 6. Tabel Setoran Tabungan
    await db.execute('''
      CREATE TABLE setoran_tabungan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_tabungan INTEGER NOT NULL,
        tanggal_setor TEXT NOT NULL,
        jumlah_setor REAL NOT NULL,
        keterangan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_tabungan) REFERENCES tabungan (id) ON DELETE CASCADE
      )
    ''');

    // Seed Data Kategori Standar
    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final defaultCategories = [
      // Pemasukan
      {'nama_kategori': 'Gaji & Upah', 'tipe': 'pemasukan', 'ikon': 'bi-wallet2', 'warna': '#10B981'},
      {'nama_kategori': 'Usaha & Sampingan', 'tipe': 'pemasukan', 'ikon': 'bi-briefcase', 'warna': '#06B6D4'},
      {'nama_kategori': 'Investasi & Bunga', 'tipe': 'pemasukan', 'ikon': 'bi-piggy-bank', 'warna': '#3B82F6'},
      {'nama_kategori': 'Bonus & Hadiah', 'tipe': 'pemasukan', 'ikon': 'bi-gift', 'warna': '#8B5CF6'},
      
      // Pengeluaran
      {'nama_kategori': 'Makanan & Minuman', 'tipe': 'pengeluaran', 'ikon': 'bi-cup-hot', 'warna': '#F43F5E'},
      {'nama_kategori': 'Belanja Harian', 'tipe': 'pengeluaran', 'ikon': 'bi-cart3', 'warna': '#F59E0B'},
      {'nama_kategori': 'Sedekah & Infaq', 'tipe': 'pengeluaran', 'ikon': 'bi-heart', 'warna': '#059669'},
      {'nama_kategori': 'Tahlil & Pengajian', 'tipe': 'pengeluaran', 'ikon': 'bi-book-half', 'warna': '#0D9488'},
      {'nama_kategori': 'Pajak & Retribusi', 'tipe': 'pengeluaran', 'ikon': 'bi-receipt', 'warna': '#D97706'},
      {'nama_kategori': 'Transportasi & Bensin', 'tipe': 'pengeluaran', 'ikon': 'bi-fuel-pump', 'warna': '#EAB308'},
      {'nama_kategori': 'Servis & Bengkel', 'tipe': 'pengeluaran', 'ikon': 'bi-tools', 'warna': '#EA580C'},
      {'nama_kategori': 'Tagihan & Listrik', 'tipe': 'pengeluaran', 'ikon': 'bi-lightning-charge', 'warna': '#EC4899'},
      {'nama_kategori': 'Pulsa & Internet', 'tipe': 'pengeluaran', 'ikon': 'bi-wifi', 'warna': '#2563EB'},
      {'nama_kategori': 'Pendidikan & SPP', 'tipe': 'pengeluaran', 'ikon': 'bi-journal-bookmark', 'warna': '#6366F1'},
      {'nama_kategori': 'Kesehatan & Medis', 'tipe': 'pengeluaran', 'ikon': 'bi-heart-pulse', 'warna': '#14B8A6'},
      {'nama_kategori': 'Keluarga & Anak', 'tipe': 'pengeluaran', 'ikon': 'bi-emoji-smile', 'warna': '#8B5CF6'},
      {'nama_kategori': 'Hiburan & Liburan', 'tipe': 'pengeluaran', 'ikon': 'bi-controller', 'warna': '#A855F7'},
      {'nama_kategori': 'Zakat & Sosial', 'tipe': 'pengeluaran', 'ikon': 'bi-moon-stars', 'warna': '#047857'},
      {'nama_kategori': 'Lain-lain', 'tipe': 'pengeluaran', 'ikon': 'bi-bookmark', 'warna': '#64748B'},
    ];

    for (final cat in defaultCategories) {
      await db.insert('kategori', cat);
    }
  }

  // ==================== KATEGORI CRUD ====================
  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (type != null) {
      maps = await db.query('kategori', where: 'tipe = ?', whereArgs: [type], orderBy: 'id ASC');
    } else {
      maps = await db.query('kategori', orderBy: 'tipe DESC, id ASC');
    }
    return maps.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<bool> categoryExists({required String name, required String type}) async {
    final db = await database;
    final cleanName = name.trim().toLowerCase();
    final maps = await db.rawQuery(
      "SELECT id, nama_kategori FROM kategori WHERE tipe = ?",
      [type],
    );
    for (final m in maps) {
      final rowName = (m['nama_kategori']?.toString() ?? '').trim().toLowerCase();
      if (rowName == cleanName) {
        return true;
      }
    }
    return false;
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('kategori', category.toMap());
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update('kategori', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('kategori', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TRANSAKSI CRUD ====================
  Future<List<TransactionModel>> getTransactions({
    String? type,
    int? categoryId,
    String? month, // 'YYYY-MM'
    String? searchQuery,
    int limit = 50,
  }) async {
    final db = await database;
    String query = '''
      SELECT t.*, k.nama_kategori, k.tipe as kategori_tipe, k.ikon, k.warna
      FROM transaksi t
      LEFT JOIN kategori k ON t.id_kategori = k.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (type != null && type.isNotEmpty && type != 'semua') {
      query += ' AND t.tipe = ?';
      args.add(type);
    }

    if (categoryId != null) {
      query += ' AND t.id_kategori = ?';
      args.add(categoryId);
    }

    if (month != null && month.isNotEmpty) {
      query += " AND strftime('%Y-%m', t.tanggal) = ?";
      args.add(month);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query += ' AND (t.keterangan LIKE ? OR k.nama_kategori LIKE ?)';
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
    }

    query += ' ORDER BY t.tanggal DESC, t.id DESC LIMIT ?';
    args.add(limit);

    final maps = await db.rawQuery(query, args);
    return maps.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<bool> transactionExists({
    required DateTime date,
    required double amount,
    required String note,
  }) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final cleanNote = note.trim().toLowerCase();

    final maps = await db.rawQuery(
      "SELECT id, keterangan FROM transaksi WHERE strftime('%Y-%m-%d', tanggal) = ? AND ABS(jumlah - ?) < 0.01",
      [dateStr, amount],
    );

    for (final m in maps) {
      final rowNote = (m['keterangan']?.toString() ?? '').trim().toLowerCase();
      if (rowNote == cleanNote) {
        return true;
      }
    }
    return false;
  }

  Future<int> removeDuplicateTransactions() async {
    final db = await database;
    try {
      return await db.rawDelete('''
        DELETE FROM transaksi 
        WHERE id NOT IN (
          SELECT MIN(id) 
          FROM transaksi 
          GROUP BY strftime('%Y-%m-%d', tanggal), jumlah, TRIM(LOWER(keterangan))
        )
      ''');
    } catch (_) {
      return 0;
    }
  }

  Future<bool> debtExists({
    required String debtorName,
    required double totalAmount,
  }) async {
    final db = await database;
    final cleanName = debtorName.trim().toLowerCase();
    final maps = await db.rawQuery(
      "SELECT id, nama_penghutang FROM hutang WHERE ABS(total_hutang - ?) < 0.01",
      [totalAmount],
    );
    for (final m in maps) {
      final rowName = (m['nama_penghutang']?.toString() ?? '').trim().toLowerCase();
      if (rowName == cleanName) {
        return true;
      }
    }
    return false;
  }

  Future<bool> savingExists({
    required String name,
  }) async {
    final db = await database;
    final cleanName = name.trim().toLowerCase();
    final maps = await db.rawQuery("SELECT id, nama_tabungan FROM tabungan");
    for (final m in maps) {
      final rowName = (m['nama_tabungan']?.toString() ?? '').trim().toLowerCase();
      if (rowName == cleanName) {
        return true;
      }
    }
    return false;
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transaksi', transaction.toMap());
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update('transaksi', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== FINANCIAL SUMMARY ====================
  Future<FinancialSummary> getFinancialSummary({String? month}) async {
    final db = await database;
    
    // 1. Total Pemasukan & Pengeluaran pada Bulan yang Dipilih
    String query = '''
      SELECT 
        SUM(CASE WHEN tipe = 'pemasukan' THEN jumlah ELSE 0 END) as total_pemasukan,
        SUM(CASE WHEN tipe = 'pengeluaran' THEN jumlah ELSE 0 END) as total_pengeluaran
      FROM transaksi
    ''';
    List<dynamic> args = [];
    if (month != null && month.isNotEmpty) {
      query += " WHERE strftime('%Y-%m', tanggal) = ?";
      args.add(month);
    }

    final txResult = await db.rawQuery(query, args);
    double income = 0.0;
    double expense = 0.0;
    if (txResult.isNotEmpty) {
      income = double.tryParse(txResult.first['total_pemasukan']?.toString() ?? '0') ?? 0.0;
      expense = double.tryParse(txResult.first['total_pengeluaran']?.toString() ?? '0') ?? 0.0;
    }

    // 2. Total Saldo Kas Kumulatif (Saldo Berjalan / Uang Kas Kumulatif hingga bulan ini)
    String cumulativeQuery = '''
      SELECT 
        SUM(CASE WHEN tipe = 'pemasukan' THEN jumlah ELSE -jumlah END) as total_saldo_kas
      FROM transaksi
    ''';
    List<dynamic> cumulativeArgs = [];
    if (month != null && month.isNotEmpty) {
      cumulativeQuery += " WHERE strftime('%Y-%m', tanggal) <= ?";
      cumulativeArgs.add(month);
    }

    final cumulativeResult = await db.rawQuery(cumulativeQuery, cumulativeArgs);
    double cumulativeBalance = 0.0;
    if (cumulativeResult.isNotEmpty && cumulativeResult.first['total_saldo_kas'] != null) {
      cumulativeBalance = double.tryParse(cumulativeResult.first['total_saldo_kas']?.toString() ?? '0') ?? 0.0;
    }

    // 3. Total Hutang (Belum Lunas)
    final debtResult = await db.rawQuery("SELECT SUM(sisa_hutang) as total FROM hutang WHERE tipe = 'hutang' AND status = 'belum_lunas'");
    double debt = 0.0;
    if (debtResult.isNotEmpty) {
      debt = double.tryParse(debtResult.first['total']?.toString() ?? '0') ?? 0.0;
    }

    // 4. Total Piutang (Belum Lunas)
    final recResult = await db.rawQuery("SELECT SUM(sisa_hutang) as total FROM hutang WHERE tipe = 'piutang' AND status = 'belum_lunas'");
    double receivable = 0.0;
    if (recResult.isNotEmpty) {
      receivable = double.tryParse(recResult.first['total']?.toString() ?? '0') ?? 0.0;
    }

    // 5. Total Tabungan Terkumpul
    final saveResult = await db.rawQuery("SELECT SUM(saldo_terkumpul) as total FROM tabungan");
    double savings = 0.0;
    if (saveResult.isNotEmpty) {
      savings = double.tryParse(saveResult.first['total']?.toString() ?? '0') ?? 0.0;
    }

    return FinancialSummary(
      totalIncome: income,
      totalExpense: expense,
      netBalance: cumulativeBalance,
      totalDebt: debt,
      totalReceivable: receivable,
      totalSavings: savings,
    );
  }

  // ==================== HUTANG & PIUTANG CRUD ====================
  Future<List<DebtModel>> getDebts({String? type, String? status}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];

    if (type != null && type.isNotEmpty && type != 'semua') {
      where += ' AND tipe = ?';
      args.add(type);
    }
    if (status != null && status.isNotEmpty && status != 'semua') {
      where += ' AND status = ?';
      args.add(status);
    }

    final maps = await db.query('hutang', where: where, whereArgs: args, orderBy: 'status ASC, tanggal_pinjam DESC');
    
    final List<DebtModel> list = [];
    for (final map in maps) {
      final id = map['id'] as int;
      final paymentsMap = await db.query('pembayaran_hutang', where: 'id_hutang = ?', whereArgs: [id], orderBy: 'tanggal_bayar DESC');
      final payments = paymentsMap.map((p) => DebtPaymentModel.fromMap(p)).toList();
      list.add(DebtModel.fromMap(map, payments: payments));
    }
    return list;
  }

  Future<int> insertDebt(DebtModel debt) async {
    final db = await database;
    return await db.insert('hutang', debt.toMap());
  }

  Future<void> addDebtPayment(int debtId, double amount, DateTime paymentDate, {String? note}) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Simpan bukti pembayaran
      await txn.insert('pembayaran_hutang', {
        'id_hutang': debtId,
        'tanggal_bayar': paymentDate.toIso8601String().substring(0, 10),
        'jumlah_bayar': amount,
        'keterangan': note,
      });

      // 2. Ambil data hutang
      final debtMap = await txn.query('hutang', where: 'id = ?', whereArgs: [debtId]);
      if (debtMap.isNotEmpty) {
        final debtorName = debtMap.first['nama_penghutang']?.toString() ?? 'Pihak Terkait';
        final type = debtMap.first['tipe']?.toString() ?? 'hutang';
        final currentRemaining = double.tryParse(debtMap.first['sisa_hutang']?.toString() ?? '0') ?? 0.0;
        final newRemaining = (currentRemaining - amount).clamp(0.0, double.infinity);
        final newStatus = newRemaining <= 0 ? 'lunas' : 'belum_lunas';

        await txn.update('hutang', {
          'sisa_hutang': newRemaining,
          'status': newStatus,
        }, where: 'id = ?', whereArgs: [debtId]);

        // 3. Otomatis Rekam ke Tabel Transaksi agar Saldo Kas Riil Terupdate
        if (type == 'hutang') {
          // Bayar Hutang -> Mengurangi Saldo Kas (Pengeluaran)
          await txn.insert('transaksi', {
            'tanggal': paymentDate.toIso8601String().substring(0, 10),
            'tipe': 'pengeluaran',
            'id_kategori': 8, // Tagihan & Pembayaran Hutang
            'jumlah': amount,
            'keterangan': 'Pelunasan/Cicilan Hutang ke $debtorName${note != null && note.isNotEmpty ? " ($note)" : ""}',
          });
        } else {
          // Terima Piutang -> Menambah Saldo Kas (Pemasukan)
          await txn.insert('transaksi', {
            'tanggal': paymentDate.toIso8601String().substring(0, 10),
            'tipe': 'pemasukan',
            'id_kategori': 4, // Penerimaan Piutang / Bonus
            'jumlah': amount,
            'keterangan': 'Penerimaan Piutang dari $debtorName${note != null && note.isNotEmpty ? " ($note)" : ""}',
          });
        }
      }
    });
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return await db.delete('hutang', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TABUNGAN & IMPIAN CRUD ====================
  Future<List<SavingModel>> getSavings({String? status}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];

    if (status != null && status.isNotEmpty && status != 'semua') {
      where += ' AND status = ?';
      args.add(status);
    }

    final maps = await db.query('tabungan', where: where, whereArgs: args, orderBy: 'status ASC, created_at DESC');
    
    final List<SavingModel> list = [];
    for (final map in maps) {
      final id = map['id'] as int;
      final depositsMap = await db.query('setoran_tabungan', where: 'id_tabungan = ?', whereArgs: [id], orderBy: 'tanggal_setor DESC');
      final deposits = depositsMap.map((d) => SavingDepositModel.fromMap(d)).toList();
      list.add(SavingModel.fromMap(map, deposits: deposits));
    }
    return list;
  }

  Future<int> insertSaving(SavingModel saving) async {
    final db = await database;
    int newId = 0;
    await db.transaction((txn) async {
      newId = await txn.insert('tabungan', saving.toMap());
      if (saving.collectedAmount > 0) {
        // 1. Simpan riwayat setoran awal
        await txn.insert('setoran_tabungan', {
          'id_tabungan': newId,
          'tanggal_setor': DateTime.now().toIso8601String().substring(0, 10),
          'jumlah_setor': saving.collectedAmount,
          'keterangan': 'Setoran Awal saat Pembuatan Target Tabungan',
        });

        // 2. Otomatis Rekam ke Tabel Transaksi (Setor Awal memotong Saldo Kas)
        await txn.insert('transaksi', {
          'tanggal': DateTime.now().toIso8601String().substring(0, 10),
          'tipe': 'pengeluaran',
          'id_kategori': 3, // Investasi & Tabungan
          'jumlah': saving.collectedAmount,
          'keterangan': 'Setoran Awal Tabungan: ${saving.name}',
        });
      }
    });
    return newId;
  }

  Future<void> addSavingDeposit(int savingId, double amount, DateTime depositDate, {String? note}) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Simpan riwayat setoran
      await txn.insert('setoran_tabungan', {
        'id_tabungan': savingId,
        'tanggal_setor': depositDate.toIso8601String().substring(0, 10),
        'jumlah_setor': amount,
        'keterangan': note,
      });

      // 2. Update saldo tabungan
      final saveMap = await txn.query('tabungan', where: 'id = ?', whereArgs: [savingId]);
      if (saveMap.isNotEmpty) {
        final savingName = saveMap.first['nama_tabungan']?.toString() ?? 'Tabungan Impian';
        final currentCollected = double.tryParse(saveMap.first['saldo_terkumpul']?.toString() ?? '0') ?? 0.0;
        final targetAmount = double.tryParse(saveMap.first['target_jumlah']?.toString() ?? '0') ?? 0.0;
        final newCollected = currentCollected + amount;
        final newStatus = newCollected >= targetAmount ? 'tercapai' : 'berlangsung';

        await txn.update('tabungan', {
          'saldo_terkumpul': newCollected,
          'status': newStatus,
        }, where: 'id = ?', whereArgs: [savingId]);

        // 3. Otomatis Rekam ke Tabel Transaksi (Setor Tabungan mengurangi kas utama)
        await txn.insert('transaksi', {
          'tanggal': depositDate.toIso8601String().substring(0, 10),
          'tipe': 'pengeluaran',
          'id_kategori': 3, // Investasi & Tabungan
          'jumlah': amount,
          'keterangan': 'Setor Tabungan Impian: $savingName${note != null && note.isNotEmpty ? " ($note)" : ""}',
        });
      }
    });
  }

  Future<int> deleteSaving(int id) async {
    final db = await database;
    return await db.delete('tabungan', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetAllTransactionsData() async {
    final db = await database;
    await db.delete('pembayaran_hutang');
    await db.delete('hutang');
    await db.delete('setoran_tabungan');
    await db.delete('tabungan');
    await db.delete('transaksi');
    try {
      await db.rawDelete("DELETE FROM sqlite_sequence WHERE name IN ('transaksi', 'hutang', 'tabungan', 'pembayaran_hutang', 'setoran_tabungan')");
    } catch (_) {}
  }
}
