import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/database_config.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';
import 'local_database.dart';

class MySQLSyncService {
  static final MySQLSyncService instance = MySQLSyncService._init();
  final LocalDatabase _localDb = LocalDatabase.instance;
  
  // Base URL for API endpoints
  final String baseUrl = 'http://${DatabaseConfig.host}:${DatabaseConfig.port}/api';

  MySQLSyncService._init();

  // Sync all data
  Future<void> syncAll() async {
    try {
      await syncProducts();
      await syncTransactions();
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  // Sync products
  Future<void> syncProducts() async {
    try {
      // Get unsynced local products
      final unsyncedProducts = await _localDb.getUnsyncedProducts();
      
      // Push unsynced products to MySQL
      for (var product in unsyncedProducts) {
        final response = await http.post(
          Uri.parse('$baseUrl/products'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(product.toMap()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _localDb.markAsSynced(DatabaseConfig.productTable, product.id!);
        } else {
          throw Exception('Failed to sync product ${product.id}');
        }
      }

      // Pull new products from MySQL
      final response = await http.get(Uri.parse('$baseUrl/products'));
      
      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        for (var productJson in productsJson) {
          final product = Product.fromMap(productJson);
          final localProduct = await _localDb.getProduct(product.id!);
          
          if (localProduct == null) {
            await _localDb.insertProduct(product);
          } else if (product.updatedAt.isAfter(localProduct.updatedAt)) {
            await _localDb.updateProduct(product);
          }
        }
      } else {
        throw Exception('Failed to fetch products from server');
      }
    } catch (e) {
      throw Exception('Product sync failed: $e');
    }
  }

  // Sync transactions
  Future<void> syncTransactions() async {
    try {
      // Get unsynced local transactions
      final unsyncedTransactions = await _localDb.getUnsyncedTransactions();
      
      // Push unsynced transactions to MySQL
      for (var transaction in unsyncedTransactions) {
        final response = await http.post(
          Uri.parse('$baseUrl/transactions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            ...transaction.toMap(),
            'items': transaction.items.map((item) => item.toMap()).toList(),
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _localDb.markAsSynced(DatabaseConfig.transactionTable, transaction.id!);
        } else {
          throw Exception('Failed to sync transaction ${transaction.id}');
        }
      }
    } catch (e) {
      throw Exception('Transaction sync failed: $e');
    }
  }

  // Retry mechanism for failed sync operations
  Future<void> retrySync(Future<void> Function() syncOperation) async {
    int retryCount = 0;
    bool syncSuccessful = false;

    while (!syncSuccessful && retryCount < DatabaseConfig.maxRetries) {
      try {
        await syncOperation();
        syncSuccessful = true;
      } catch (e) {
        retryCount++;
        if (retryCount >= DatabaseConfig.maxRetries) {
          throw Exception('Sync failed after $retryCount retries: $e');
        }
        await Future.delayed(DatabaseConfig.retryDelay);
      }
    }
  }

  // Check server connectivity
  Future<bool> checkServerConnectivity() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Initialize sync schedule
  void initializeSyncSchedule() {
    Future.doWhile(() async {
      try {
        if (await checkServerConnectivity()) {
          await syncAll();
        }
      } catch (e) {
        print('Scheduled sync failed: $e');
      }
      await Future.delayed(DatabaseConfig.syncInterval);
      return true; // Continue the loop
    });
  }
}
