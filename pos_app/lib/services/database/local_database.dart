import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../config/database_config.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(DatabaseConfig.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: DatabaseConfig.databaseVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.productTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        image_url TEXT,
        barcode TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.transactionTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_number TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Create transaction items table
    await db.execute('''
      CREATE TABLE ${DatabaseConfig.transactionItemTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES ${DatabaseConfig.transactionTable} (id)
        ON DELETE CASCADE
      )
    ''');
  }

  // Product Operations
  Future<Product> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert(DatabaseConfig.productTable, product.toMap());
    return product.copyWith(id: id);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseConfig.productTable);
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConfig.productTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return db.update(
      DatabaseConfig.productTable,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete(
      DatabaseConfig.productTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction Operations
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    final batch = db.batch();
    
    // Insert transaction
    batch.insert(DatabaseConfig.transactionTable, transaction.toMap());
    
    // Insert transaction items
    for (var item in transaction.items) {
      batch.insert(DatabaseConfig.transactionItemTable, item.toMap());
    }
    
    final results = await batch.commit();
    return results.first as int;
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> transactionMaps = await db.query(
      DatabaseConfig.transactionTable,
      orderBy: 'transaction_date DESC',
    );

    return Future.wait(transactionMaps.map((transactionMap) async {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        DatabaseConfig.transactionItemTable,
        where: 'transaction_id = ?',
        whereArgs: [transactionMap['id']],
      );

      final items = itemMaps.map((item) => TransactionItem.fromMap(item)).toList();
      return Transaction.fromMap(transactionMap, items);
    }));
  }

  Future<Transaction?> getTransaction(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> transactionMaps = await db.query(
      DatabaseConfig.transactionTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (transactionMaps.isEmpty) return null;

    final List<Map<String, dynamic>> itemMaps = await db.query(
      DatabaseConfig.transactionItemTable,
      where: 'transaction_id = ?',
      whereArgs: [id],
    );

    final items = itemMaps.map((item) => TransactionItem.fromMap(item)).toList();
    return Transaction.fromMap(transactionMaps.first, items);
  }

  // Sync Operations
  Future<List<Product>> getUnsyncedProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConfig.productTable,
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Transaction>> getUnsyncedTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> transactionMaps = await db.query(
      DatabaseConfig.transactionTable,
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return Future.wait(transactionMaps.map((transactionMap) async {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        DatabaseConfig.transactionItemTable,
        where: 'transaction_id = ?',
        whereArgs: [transactionMap['id']],
      );

      final items = itemMaps.map((item) => TransactionItem.fromMap(item)).toList();
      return Transaction.fromMap(transactionMap, items);
    }));
  }

  Future<void> markAsSynced(String table, int id) async {
    final db = await database;
    await db.update(
      table,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
