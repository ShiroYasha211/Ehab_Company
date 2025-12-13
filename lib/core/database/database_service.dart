// File: lib/core/database/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ehab_company.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // --- الحل الجذري والمنطق الصحيح ---

  /// تُنفذ عند إنشاء قاعدة بيانات جديدة تمامًا.
  Future<void> _onCreate(Database db, int version) async {
    // أنشئ كل الجداول بالترتيب حتى الإصدار الحالي
    await _onUpgrade(db, 0, version);
  }

  /// تُنفذ عند ترقية قاعدة البيانات من إصدار قديم إلى جديد.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // نستخدم هذا الأسلوب المتسلسل لضمان تنفيذ الترقيات بالترتيب
    if (oldVersion < 1) {
      await _createV1Tables(db);
    }
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
    }
    if (oldVersion < 4) {
      await _createV4Tables(db);
    }
    if (oldVersion < 5) {
      await _createV5Tables(db);
    }
  }

  /// الإصدار 1: جداول المخازن والصندوق الأساسية
  Future<void> _createV1Tables(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, code TEXT UNIQUE,
        description TEXT, quantity REAL NOT NULL DEFAULT 0, purchasePrice REAL NOT NULL,
        salePrice REAL NOT NULL, imageUrl TEXT, category TEXT, unit TEXT,
        productionDate TEXT, expiryDate TEXT, minStockLevel REAL NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE funds (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, balance REAL NOT NULL DEFAULT 0.0)
    ''');
    batch.execute('''
      CREATE TABLE fund_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT, fundId INTEGER NOT NULL, type TEXT NOT NULL,
        amount REAL NOT NULL, description TEXT NOT NULL, referenceId INTEGER,
        transactionDate TEXT NOT NULL,
        FOREIGN KEY (fundId) REFERENCES funds(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE units (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
    batch.insert('funds', {'name': 'الصندوق الرئيسي', 'balance': 0.0});
    batch.insert('units', {'name': 'قطعة'});
    batch.insert('units', {'name': 'كرتون'});
    batch.insert('units', {'name': 'باكت'});
    await batch.commit(noResult: true);
  }

  /// الإصدار 2: جداول الموردين والمشتريات
  Future<void> _createV2Tables(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT,
        address TEXT, email TEXT, createdAt TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE purchase_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT, supplierId INTEGER, invoiceNumber TEXT,
        totalAmount REAL NOT NULL, discountAmount REAL NOT NULL DEFAULT 0.0, paidAmount REAL NOT NULL,
        remainingAmount REAL NOT NULL, invoiceDate TEXT NOT NULL, notes TEXT,
        FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON DELETE SET NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE purchase_invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT, invoiceId INTEGER NOT NULL, productId INTEGER NOT NULL,
        productName TEXT NOT NULL, quantity REAL NOT NULL, purchasePrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES purchase_invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');
    await batch.commit(noResult: true);
  }

  /// الإصدار 3: إضافة حقول لجدول الموردين
  Future<void> _createV3Tables(Database db) async {
    await db.execute('ALTER TABLE suppliers ADD COLUMN company TEXT');
    await db.execute('ALTER TABLE suppliers ADD COLUMN commercialRecord TEXT');
    await db.execute('ALTER TABLE suppliers ADD COLUMN notes TEXT');
  }

  /// الإصدار 4: إضافة حقل الرصيد للموردين وجدول حركات الموردين
  Future<void> _createV4Tables(Database db) async {
    await db.execute('ALTER TABLE suppliers ADD COLUMN balance REAL NOT NULL DEFAULT 0.0');
    await db.execute('''
      CREATE TABLE supplier_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- رقم السند (جعلته تلقائيًا لضمان عدم التضارب)
        supplierId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        transactionDate TEXT NOT NULL,
        affectsFund INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');
  }
  /// الإصدار 5: إضافة حقل الحالة للفواتير وجدول مرتجعات المشتريات
  Future<void> _createV5Tables(Database db) async {
    final batch = db.batch();
    // إضافة حقل لتتبع حالة الفاتورة (عادية، مرتجعة، ملغاة، الخ)
    batch.execute('''
      ALTER TABLE purchase_invoices ADD COLUMN status TEXT NOT NULL DEFAULT 'COMPLETED'
    ''');

    // إنشاء جدول لتخزين معلومات عمليات الإرجاع
    batch.execute('''
      CREATE TABLE purchase_returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        originalInvoiceId INTEGER NOT NULL,
        returnDate TEXT NOT NULL,
        reason TEXT,
        totalValue REAL NOT NULL,
        FOREIGN KEY (originalInvoiceId) REFERENCES purchase_invoices(id) ON DELETE CASCADE
      )
    ''');
    await batch.commit(noResult: true);
  }

}
