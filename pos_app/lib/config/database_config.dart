class DatabaseConfig {
  // Local Database Configuration
  static const String databaseName = 'pos_database.db';
  static const int databaseVersion = 1;

  // Tables
  static const String productTable = 'products';
  static const String transactionTable = 'transactions';
  static const String transactionItemTable = 'transaction_items';

  // MySQL Database Configuration
  static const String host = 'localhost';
  static const int port = 3306;
  static const String username = 'root';
  static const String password = '';
  static const String database = 'pos_db';

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);
}
