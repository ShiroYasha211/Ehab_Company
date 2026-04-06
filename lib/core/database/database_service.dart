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

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ehab_company.db');

    return await openDatabase(
      path,
      version: 37,
      // --- نهاية الإصلاح ---
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _onUpgrade(db, 0, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
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
    if (oldVersion < 6) {
      await _createV6Tables(db);
    }
    // --- بداية الإصلاح: إضافة الإصدار الجديد ---
    if (oldVersion < 7) {
      await _createV7Tables(db);
    }
    // --- نهاية الإصلاح ---
    if (oldVersion < 8) {
      await _createV8Tables(db);
    }
    if (oldVersion < 9) {
      await _createV9Tables(db);
    }
    if (oldVersion < 10) {
      await _createV10Tables(db);
    }
    if (oldVersion < 11) {
      await _createV11Tables(db);
    }
    if (oldVersion < 12) {
      await _createV12Tables(db);
    }
    if (oldVersion < 13) {
      await _createV13Tables(db);
    }
    if (oldVersion < 14) {
      await _createV14Tables(db);
    }
    if (oldVersion < 15) {
      await _createV15Tables(db);
    }
    if (oldVersion < 16) {
      await _createV16Tables(db);
    }
    if (oldVersion < 17) {
      await _createV17Tables(db);
    }
    if (oldVersion < 18) {
      await _createV18Tables(db);
    }
    if (oldVersion < 19) {
      await _createV19Tables(db);
    }
    if (oldVersion < 20) {
      await _createV20Tables(db);
    }
    if (oldVersion < 21) {
      await _createV21Tables(db);
    }
    if (oldVersion < 22) {
      await _createV22Tables(db);
    }
    if (oldVersion < 23) {
      await _createV23Tables(db);
    }
    if (oldVersion < 24) {
      await _createV24Tables(db);
    }
    if (oldVersion < 25) {
      await _createV25Tables(db);
    }
    if (oldVersion < 26) {
      await _createV26Tables(db);
    }
    if (oldVersion < 27) {
      await _createV27Tables(db);
    }
    if (oldVersion < 28) {
      // إعادة التأكد من إنشاء الجدول في حال فشل الإصدار السابق
      await _createV27Tables(db);
    }
    if (oldVersion < 29) {
      await _createV29Tables(db);
    }
    if (oldVersion < 30) {
      await _createV30Tables(db);
    }
    if (oldVersion < 31) {
      await _createV31Tables(db);
    }
    if (oldVersion < 32) {
      await _createV32Tables(db);
    }
    if (oldVersion < 33) {
      await _createV33Tables(db);
    }
    if (oldVersion < 34) {
      await _createV34Tables(db);
    }
    if (oldVersion < 35) {
      await _createV35Tables(db);
    }
    if (oldVersion < 36) {
      await _createV36Tables(db);
    }
    if (oldVersion < 37) {
      await _createV37Tables(db);
    }
  }

  /// الإصدار 1: جداول المخازن والصندوق الأساسية
  Future<void> _createV1Tables(Database db) async {
    // ... (هذا الجزء يبقى كما هو)
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
    batch.execute(
      'CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)',
    );
    batch.execute(
      'CREATE TABLE units (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)',
    );
    batch.insert('funds', {'name': 'الصندوق الرئيسي', 'balance': 0.0});
    batch.insert('units', {'name': 'قطعة'});
    batch.insert('units', {'name': 'كرتون'});
    batch.insert('units', {'name': 'باكت'});
    await batch.commit(noResult: true);
  }

  /// الإصدار 2: جداول الموردين والمشتريات
  Future<void> _createV2Tables(Database db) async {
    // ... (هذا الجزء يبقى كما هو)
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
    // ... (هذا الجزء يبقى كما هو)
    await db.execute('ALTER TABLE suppliers ADD COLUMN company TEXT');
    await db.execute('ALTER TABLE suppliers ADD COLUMN commercialRecord TEXT');
    await db.execute('ALTER TABLE suppliers ADD COLUMN notes TEXT');
  }

  /// الإصدار 4: إضافة حقل الرصيد للموردين وجدول حركات الموردين
  Future<void> _createV4Tables(Database db) async {
    // ... (هذا الجزء يبقى كما هو)
    await db.execute(
      'ALTER TABLE suppliers ADD COLUMN balance REAL NOT NULL DEFAULT 0.0',
    );
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
    // ... (هذا الجزء يبقى كما هو)
    final batch = db.batch();
    batch.execute('''
      ALTER TABLE purchase_invoices ADD COLUMN status TEXT NOT NULL DEFAULT 'COMPLETED'
    ''');
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

  /// الإصدار 6: إضافة جداول العملاء وحركاتهم
  Future<void> _createV6Tables(Database db) async {
    // ... (هذا الجزء يبقى كما هو)
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        email TEXT,
        company TEXT,
        notes TEXT,
        balance REAL NOT NULL DEFAULT 0.0,
        createdAt TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE customer_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        transactionDate TEXT NOT NULL,
        affectsFund INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (customerId) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
    await batch.commit(noResult: true);
  }

  // --- بداية الإضافة: دالة الترقية الجديدة ---
  /// الإصدار 7: إضافة جداول المبيعات
  Future<void> _createV7Tables(Database db) async {
    final batch = db.batch();
    // إنشاء جدول فواتير المبيعات
    batch.execute('''
      CREATE TABLE sales_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        totalAmount REAL NOT NULL,
        discountAmount REAL NOT NULL DEFAULT 0.0,
        paidAmount REAL NOT NULL,
        remainingAmount REAL NOT NULL,
        invoiceDate TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'COMPLETED',
        FOREIGN KEY (customerId) REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');

    // إنشاء جدول أصناف فواتير المبيعات
    batch.execute('''
      CREATE TABLE sales_invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity REAL NOT NULL,
        salePrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES sales_invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');
    await batch.commit(noResult: true);
  }

  /// الإصدار 8: إضافة جداول المصروفات وبنودها
  Future<void> _createV8Tables(Database db) async {
    final batch = db.batch();

    // إنشاء جدول لتصنيف المصروفات (البنود)
    batch.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // إنشاء جدول لتسجيل المصروفات الفعلية
    batch.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        amount REAL NOT NULL,
        expenseDate TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (categoryId) REFERENCES expense_categories(id) ON DELETE RESTRICT
      )
    ''');

    // إضافة بعض البنود الافتراضية
    batch.insert('expense_categories', {'name': 'إيجار'});
    batch.insert('expense_categories', {'name': 'رواتب وأجور'});
    batch.insert('expense_categories', {
      'name': 'فواتير (كهرباء، ماء، إنترنت)',
    });
    batch.insert('expense_categories', {'name': 'مصاريف تسويق'});
    batch.insert('expense_categories', {'name': 'ضيافة ونثريات'});

    await batch.commit(noResult: true);
  }

  Future<void> _createV9Tables(Database db) async {
    // سيتم تعيين القيمة الافتراضية إلى تاريخ إنشاء العميل
    await db.execute(
      'ALTER TABLE customers ADD COLUMN lastTransactionDate TEXT',
    );
    await db.execute('UPDATE customers SET lastTransactionDate = createdAt');
  }

  // --- بداية الإضافة: دالة الترقية الجديدة ---
  /// الإصدار 10: إضافة حقل الخصم من الصندوق للمصروفات
  Future<void> _createV10Tables(Database db) async {
    await db.execute('''
      ALTER TABLE expenses ADD COLUMN deductFromFund INTEGER NOT NULL DEFAULT 1
    ''');
  }

  /// الإصدار 11: نظام الوحدات المتداخلة
  Future<void> _createV11Tables(Database db) async {
    final batch = db.batch();

    // 1. تحديث جدول الوحدات لإضافة الربط المتداخل ومعامل التحويل
    batch.execute('ALTER TABLE units ADD COLUMN childUnitId INTEGER');
    batch.execute(
      'ALTER TABLE units ADD COLUMN conversionFactor REAL DEFAULT 1.0',
    );

    // 2. تحديث جدول المنتجات لاستبدال حقل unit (النص) بـ unitId (الرقم)
    // في SQLite لا يمكن حذف عمود أو تعديل نوعه بسهولة، لذا سنضيف المعرف ونحاول الربط
    batch.execute('ALTER TABLE products ADD COLUMN unitId INTEGER');

    await batch.commit(noResult: true);

    // 3. محاولة تنظيف البيانات (نقل الوحدات النصية إلى IDs)
    // هذا الجزء "اجتهادي" لضمان استمرارية العمل
    final List<Map<String, dynamic>> products = await db.query('products');
    final List<Map<String, dynamic>> units = await db.query('units');

    for (var product in products) {
      final String? oldUnitName = product['unit'];
      if (oldUnitName != null) {
        final unitMatch = units.firstWhere(
          (u) => u['name'] == oldUnitName,
          orElse: () => {},
        );
        if (unitMatch.isNotEmpty) {
          await db.update(
            'products',
            {'unitId': unitMatch['id']},
            where: 'id = ?',
            whereArgs: [product['id']],
          );
        }
      }
    }
  }

  /// الإصدار 12: تحرير القيود على جدول الوحدات لدعم السلاسل المستقلة
  Future<void> _createV12Tables(Database db) async {
    // 1. إعادة تسمية الجدول القديم
    await db.execute('ALTER TABLE units RENAME TO units_old');

    // 2. إنشاء الجدول الجديد بدون UNIQUE على الاسم
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        childUnitId INTEGER,
        conversionFactor REAL DEFAULT 1.0
      )
    ''');

    // 3. نقل البيانات للجدول الجديد
    await db.execute('''
      INSERT INTO units (id, name, childUnitId, conversionFactor)
      SELECT id, name, childUnitId, conversionFactor FROM units_old
    ''');

    // 4. حذف الجدول المؤقت
    await db.execute('DROP TABLE units_old');
  }

  /// الإصدار 13: إضافة حقل وحدات البيع المسموح بها للمنتجات
  Future<void> _createV13Tables(Database db) async {
    await db.execute(
      'ALTER TABLE products ADD COLUMN allowedUnits TEXT',
    );
  }

  /// الإصدار 14: إضافة سعر الشراء والوحدة في تفاصيل المبيعات لضمان دقة COGS
  Future<void> _createV14Tables(Database db) async {
    final batch = db.batch();
    batch.execute(
      'ALTER TABLE sales_invoice_items ADD COLUMN purchasePrice REAL DEFAULT 0.0',
    );
    batch.execute(
      'ALTER TABLE sales_invoice_items ADD COLUMN unitId INTEGER',
    );
    await batch.commit(noResult: true);
  }
  /// الإصدار 15: إعادة هيكلة نظام الصندوق - صناديق فرعية متعددة
  Future<void> _createV15Tables(Database db) async {
    // التحقق من الأعمدة الموجودة حالياً لتجنب خطأ الـ "duplicate column"
    final List<Map<String, dynamic>> fundsColumns = await db.rawQuery('PRAGMA table_info(funds)');
    final List<String> fundsColumnNames = fundsColumns.map((col) => col['name'] as String).toList();

    final List<Map<String, dynamic>> txColumns = await db.rawQuery('PRAGMA table_info(fund_transactions)');
    final List<String> txColumnNames = txColumns.map((col) => col['name'] as String).toList();

    final batch = db.batch();

    // 1. إضافة أعمدة جديدة لجدول funds
    if (!fundsColumnNames.contains('fundType')) {
      batch.execute("ALTER TABLE funds ADD COLUMN fundType TEXT NOT NULL DEFAULT 'cash'");
    }
    if (!fundsColumnNames.contains('bankName')) {
      batch.execute('ALTER TABLE funds ADD COLUMN bankName TEXT');
    }
    if (!fundsColumnNames.contains('accountNumber')) {
      batch.execute('ALTER TABLE funds ADD COLUMN accountNumber TEXT');
    }
    if (!fundsColumnNames.contains('isActive')) {
      batch.execute('ALTER TABLE funds ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1');
    }
    if (!fundsColumnNames.contains('initialBalance')) {
      batch.execute('ALTER TABLE funds ADD COLUMN initialBalance REAL NOT NULL DEFAULT 0.0');
    }

    // 2. إضافة أعمدة جديدة لجدول fund_transactions
    if (!txColumnNames.contains('sourceFundId')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN sourceFundId INTEGER');
    }
    if (!txColumnNames.contains('targetFundId')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN targetFundId INTEGER');
    }
    if (!txColumnNames.contains('transferCompany')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN transferCompany TEXT');
    }
    if (!txColumnNames.contains('senderName')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN senderName TEXT');
    }
    if (!txColumnNames.contains('receiverName')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN receiverName TEXT');
    }
    if (!txColumnNames.contains('transferNumber')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN transferNumber TEXT');
    }
    if (!txColumnNames.contains('referenceType')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN referenceType TEXT');
    }

    // 3. تحديث الصندوق الحالي (ID=1) ليصبح نوعه cash
    batch.update('funds', {'fundType': 'cash'}, where: 'id = ?', whereArgs: [1]);

    await batch.commit(noResult: true);
  }

  /// الإصدار 16: دعم الرسوم والمرفقات في حركات الصناديق
  Future<void> _createV16Tables(Database db) async {
    final batch = db.batch();
    
    // التحقق من وجود الحقول لتجنب الأخطاء عند إعادة التشغيل
    final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(fund_transactions)');
    final List<String> columnNames = columns.map((col) => col['name'] as String).toList();

    if (!columnNames.contains('fees')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN fees REAL DEFAULT 0.0');
    }
    if (!columnNames.contains('attachmentPath')) {
      batch.execute('ALTER TABLE fund_transactions ADD COLUMN attachmentPath TEXT');
    }

    await batch.commit(noResult: true);
  }

  /// الإصدار 17: إضافة حقل إيقاف البيع للمنتجات
  Future<void> _createV17Tables(Database db) async {
    final batch = db.batch();
    
    // التحقق من وجود الحقل لتجنب الأخطاء
    final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(products)');
    final List<String> columnNames = columns.map((col) => col['name'] as String).toList();

    if (!columnNames.contains('isSalesStopped')) {
      batch.execute('ALTER TABLE products ADD COLUMN isSalesStopped INTEGER NOT NULL DEFAULT 0');
    }

    await batch.commit(noResult: true);
  }

  /// الإصدار 18: نظام المخازن المتعددة وعُهد المندوبين
  Future<void> _createV18Tables(Database db) async {
    final batch = db.batch();

    // 1. إنشاء جدول المخازن
    batch.execute('''
      CREATE TABLE IF NOT EXISTS warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'main',
        salesRepName TEXT,
        salesRepPhone TEXT,
        creditLimit REAL DEFAULT 0.0,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. إنشاء جدول أرصدة المخازن
    batch.execute('''
      CREATE TABLE IF NOT EXISTS warehouse_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouseId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (warehouseId) REFERENCES warehouses(id),
        FOREIGN KEY (productId) REFERENCES products(id),
        UNIQUE(warehouseId, productId)
      )
    ''');

    // 3. إنشاء جدول سندات التحويل المخزني
    batch.execute('''
      CREATE TABLE IF NOT EXISTS inventory_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sourceWarehouseId INTEGER NOT NULL,
        destinationWarehouseId INTEGER NOT NULL,
        transferDate TEXT NOT NULL,
        totalValue REAL NOT NULL DEFAULT 0.0,
        totalCostValue REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'COMPLETED',
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (sourceWarehouseId) REFERENCES warehouses(id),
        FOREIGN KEY (destinationWarehouseId) REFERENCES warehouses(id)
      )
    ''');

    // 4. إنشاء جدول تفاصيل التحويل
    batch.execute('''
      CREATE TABLE IF NOT EXISTS inventory_transfer_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transferId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitId INTEGER,
        salePrice REAL NOT NULL,
        purchasePrice REAL NOT NULL,
        totalSaleValue REAL NOT NULL,
        totalCostValue REAL NOT NULL,
        FOREIGN KEY (transferId) REFERENCES inventory_transfers(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    await batch.commit(noResult: true);

    // 5. إضافة عمود warehouseId لجدول المبيعات
    final List<Map<String, dynamic>> salesCols = await db.rawQuery('PRAGMA table_info(sales_invoices)');
    final List<String> salesColNames = salesCols.map((col) => col['name'] as String).toList();
    if (!salesColNames.contains('warehouseId')) {
      await db.execute('ALTER TABLE sales_invoices ADD COLUMN warehouseId INTEGER DEFAULT 1');
    }

    // 6. إنشاء المخزن الرئيسي تلقائياً
    final existingWarehouses = await db.query('warehouses');
    if (existingWarehouses.isEmpty) {
      await db.insert('warehouses', {
        'name': 'المخزن الرئيسي',
        'type': 'main',
        'isActive': 1,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    // 7. نقل كميات المنتجات الحالية إلى warehouse_stock للمخزن الرئيسي (ID=1)
    final products = await db.query('products', columns: ['id', 'quantity']);
    for (final product in products) {
      final productId = product['id'] as int;
      final quantity = (product['quantity'] as num).toDouble();
      if (quantity > 0) {
        // التحقق من عدم وجود سجل مسبق
        final existing = await db.query(
          'warehouse_stock',
          where: 'warehouseId = 1 AND productId = ?',
          whereArgs: [productId],
        );
        if (existing.isEmpty) {
          await db.insert('warehouse_stock', {
            'warehouseId': 1,
            'productId': productId,
            'quantity': quantity,
          });
        }
      }
    }
  }

  /// الإصدار 19: نظام التسوية اليدوي ومديونيات المناديب
  Future<void> _createV19Tables(Database db) async {
    final batch = db.batch();

    // 1. إضافة حقل الرصيد لجدول المخازن (المناديب)
    final List<Map<String, dynamic>> warehousesCols = await db.rawQuery('PRAGMA table_info(warehouses)');
    final List<String> warehousesColNames = warehousesCols.map((col) => col['name'] as String).toList();
    if (!warehousesColNames.contains('balance')) {
      batch.execute('ALTER TABLE warehouses ADD COLUMN balance REAL DEFAULT 0.0');
    }

    // 2. إنشاء جدول التسويات (رأس العملية)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS settlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouseId INTEGER NOT NULL,
        totalSales REAL NOT NULL,
        totalReturned REAL NOT NULL,
        totalCredit REAL NOT NULL,
        amountPaid REAL NOT NULL,
        deficit REAL DEFAULT 0.0,
        settlementDate TEXT NOT NULL,
        notes TEXT,
        paymentMethod TEXT, -- 'cash', 'bank', 'transfer'
        fundId INTEGER,
        isStockCleared INTEGER NOT NULL DEFAULT 0,
        isCreditToCustomers INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (warehouseId) REFERENCES warehouses(id),
        FOREIGN KEY (fundId) REFERENCES funds(id)
      )
    ''');

    // 3. إنشاء جدول تفاصيل أصناف التسوية
    batch.execute('''
      CREATE TABLE IF NOT EXISTS settlement_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        settlementId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        initialQty REAL NOT NULL,
        soldQty REAL NOT NULL,
        returnedQty REAL NOT NULL,
        unitId INTEGER,
        salePrice REAL NOT NULL,
        FOREIGN KEY (settlementId) REFERENCES settlements(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    // 4. إنشاء جدول حركات المندوبين (كشف الحساب)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS warehouse_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouseId INTEGER NOT NULL,
        type TEXT NOT NULL, -- 'settlement', 'payment', 'adjustment'
        amount REAL NOT NULL,
        notes TEXT,
        transactionDate TEXT NOT NULL,
        referenceId INTEGER, -- قد يربط بـ settlementId
        FOREIGN KEY (warehouseId) REFERENCES warehouses(id)
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// الإصدار 20: تفصيل التحصيل المالي لكل صنف في التسوية
  Future<void> _createV20Tables(Database db) async {
    // إضافة أعمدة مالية لجدول settlement_items بشكل آمن
    await _addColumnIfNotExists(db, 'settlement_items', 'cashAmount REAL DEFAULT 0.0');
    await _addColumnIfNotExists(db, 'settlement_items', 'cashFundId INTEGER');
    
    await _addColumnIfNotExists(db, 'settlement_items', 'bankAmount REAL DEFAULT 0.0');
    await _addColumnIfNotExists(db, 'settlement_items', 'bankFundId INTEGER');
    await _addColumnIfNotExists(db, 'settlement_items', 'bankDetails TEXT');
    
    await _addColumnIfNotExists(db, 'settlement_items', 'transferAmount REAL DEFAULT 0.0');
    await _addColumnIfNotExists(db, 'settlement_items', 'transferFundId INTEGER');
    await _addColumnIfNotExists(db, 'settlement_items', 'transferDetails TEXT');
    
    await _addColumnIfNotExists(db, 'settlement_items', 'creditAmount REAL DEFAULT 0.0');
    await _addColumnIfNotExists(db, 'settlement_items', 'creditTarget TEXT'); // 'rep' or 'customer'
    await _addColumnIfNotExists(db, 'settlement_items', 'customerId INTEGER');
  }

  /// الإصدار 21: إضافة حقل الكمية المجانية في أصناف الفواتير
  Future<void> _createV21Tables(Database db) async {
    await _addColumnIfNotExists(db, 'sales_invoice_items', 'freeQuantity REAL DEFAULT 0.0');
  }

  /// الإصدار 22: إضافة حقل الوحدة النصي المفقود في أصناف الفواتير
  Future<void> _createV22Tables(Database db) async {
    await _addColumnIfNotExists(db, 'sales_invoice_items', 'unit TEXT');
  }

  Future<void> _createV23Tables(Database db) async {
    await _addColumnIfNotExists(db, 'sales_invoices', 'issuedBy TEXT');
  }

  /// دالة مساعدة لإضافة عمود فقط إذا لم يكن موجوداً (تمنع خطأ Duplicate Column)
  Future<void> _addColumnIfNotExists(Database db, String tableName, String columnDefinition) async {
    // استخراج اسم العمود من التعريف (أول كلمة)
    final columnName = columnDefinition.split(' ').first;
    
    // فحص معلومات الجدول
    final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info($tableName)');
    
    // التحقق مما إذا كان العمود موجوداً
    bool exists = columns.any((column) => column['name'] == columnName);
    
    if (!exists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnDefinition');
    }
  }

  /// الإصدار 24: نظام تعدد طرق الدفع (نقد، حوالة، بنك)
  Future<void> _createV24Tables(Database db) async {
    final batch = db.batch();

    // إنشاء جدول تفاصيل طرق الدفع لكل فاتورة
    batch.execute('''
      CREATE TABLE IF NOT EXISTS sales_invoice_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        method TEXT NOT NULL, -- 'cash', 'transfer', 'bank'
        amount REAL NOT NULL,
        
        -- بيانات الحوالة
        transferNumber TEXT,
        senderName TEXT,
        transferCompany TEXT,
        transferImage TEXT,
        
        -- بيانات البنك
        bankName TEXT,
        bankReference TEXT,
        bankImage TEXT,
        
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES sales_invoices(id) ON DELETE CASCADE
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// الإصدار 25: إضافة حقل معرف الصندوق لكل دفعة
  Future<void> _createV25Tables(Database db) async {
    await _addColumnIfNotExists(db, 'sales_invoice_payments', 'fundId INTEGER');
  }

  /// الإصدار 26: دعم تفاصيل الحوالات والبنوك في حركات الصناديق بالكامل
  Future<void> _createV26Tables(Database db) async {
    final batch = db.batch();
    await _addColumnIfNotExists(db, 'fund_transactions', 'bankName TEXT');
    await _addColumnIfNotExists(db, 'fund_transactions', 'bankReference TEXT');
    await _addColumnIfNotExists(db, 'fund_transactions', 'notes TEXT');
    await batch.commit(noResult: true);
  }

  /// الإصدار 27: إنشاء جدول سجلات المرتجعات المستقل (Audit Logic)
  Future<void> _createV27Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        originalInvoiceId INTEGER NOT NULL,
        returnDate TEXT NOT NULL,
        reason TEXT,
        totalReturnedValue REAL NOT NULL,
        returnedToFund INTEGER NOT NULL DEFAULT 1, -- هل تم إرجاع المال للصندوق (1) أم للرصيد (0)
        FOREIGN KEY (originalInvoiceId) REFERENCES sales_invoices(id) ON DELETE CASCADE
      )
    ''');
  }

  /// الإصدار 29: إضافة الكمية المجانية للمشتريات
  Future<void> _createV29Tables(Database db) async {
    await _addColumnIfNotExists(db, 'purchase_invoice_items', 'freeQuantity REAL DEFAULT 0.0');
  }

  /// الإصدار 30: توثيق مُصدر فاتورة المشتريات وتفاصيل الدفع المختلط
  Future<void> _createV30Tables(Database db) async {
    await _addColumnIfNotExists(db, 'purchase_invoices', 'issuedBy TEXT');
  }

  /// الإصدار 31: نظام تعدد طرق الدفع للمشتريات (كاش، حوالة، بنك)
  Future<void> _createV31Tables(Database db) async {
    final batch = db.batch();

    // إنشاء جدول تفاصيل طرق الدفع لكل فاتورة مشتريات
    batch.execute('''
      CREATE TABLE IF NOT EXISTS purchase_invoice_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        method TEXT NOT NULL, -- 'cash', 'transfer', 'bank'
        amount REAL NOT NULL,
        fundId INTEGER, -- معرف الصندوق أو الحساب البنكي
        
        -- بيانات الحوالة
        transferNumber TEXT,
        senderName TEXT,
        transferCompany TEXT,
        transferImage TEXT,
        
        -- بيانات البنك
        bankName TEXT,
        bankReference TEXT,
        bankImage TEXT,
        
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES purchase_invoices(id) ON DELETE CASCADE
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// الإصدار 32: إضافة حقل الوحدة لتفاصيل المشتريات
  Future<void> _createV32Tables(Database db) async {
    await _addColumnIfNotExists(db, 'purchase_invoice_items', 'unit TEXT');
  }

  /// الإصدار 33: إنشاء جدول سجلات النشاطات (Audit Logs)
  Future<void> _createV33Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        userName TEXT,
        userRole TEXT,
        action TEXT NOT NULL,
        details TEXT,
        type TEXT NOT NULL, -- auth, sale, purchase, inventory, expense, fund, system, admin
        time TEXT NOT NULL,
        deviceInfo TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }
  
  /// الإصدار 34: إضافة معرف الصندوق لجدول المصروفات
  Future<void> _createV34Tables(Database db) async {
    // إضافة عمود معرف الصندوق للمصروفات
    await _addColumnIfNotExists(db, 'expenses', 'fundId INTEGER DEFAULT 1');
    // تحديث السجلات القديمة لتشير إلى الصندوق الرئيسي
    await db.execute('UPDATE expenses SET fundId = 1 WHERE fundId IS NULL');
  }

  /// الإصدار 35: دعم مصروفات الموردين
  Future<void> _createV35Tables(Database db) async {
    // إضافة معرف المورد للمصروفات (اختياري)
    await _addColumnIfNotExists(db, 'expenses', 'supplierId INTEGER');
  }

  /// الإصدار 36: إصلاح نقص عمود المرجع في حركات الموردين
  Future<void> _createV36Tables(Database db) async {
    await _addColumnIfNotExists(db, 'supplier_transactions', 'referenceId INTEGER');
  }

  /// الإصدار 37: إضافة مُصدر المصروف لجدول المصروفات
  Future<void> _createV37Tables(Database db) async {
    await _addColumnIfNotExists(db, 'expenses', 'issuedBy TEXT');
  }
}
