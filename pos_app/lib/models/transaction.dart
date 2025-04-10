import 'package:intl/intl.dart';

class Transaction {
  final int? id;
  final String transactionNumber;
  final double totalAmount;
  final double paymentAmount;
  final String paymentMethod;
  final DateTime transactionDate;
  final bool isSynced;
  final List<TransactionItem> items;

  Transaction({
    this.id,
    required this.transactionNumber,
    required this.totalAmount,
    required this.paymentAmount,
    required this.paymentMethod,
    required this.transactionDate,
    this.isSynced = false,
    required this.items,
  });

  double get change => paymentAmount - totalAmount;

  String get formattedDate => DateFormat('yyyy-MM-dd HH:mm:ss').format(transactionDate);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_number': transactionNumber,
      'total_amount': totalAmount,
      'payment_amount': paymentAmount,
      'payment_method': paymentMethod,
      'transaction_date': transactionDate.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, List<TransactionItem> items) {
    return Transaction(
      id: map['id'],
      transactionNumber: map['transaction_number'],
      totalAmount: map['total_amount'] is int ? 
        (map['total_amount'] as int).toDouble() : map['total_amount'],
      paymentAmount: map['payment_amount'] is int ? 
        (map['payment_amount'] as int).toDouble() : map['payment_amount'],
      paymentMethod: map['payment_method'],
      transactionDate: DateTime.parse(map['transaction_date']),
      isSynced: map['is_synced'] == 1,
      items: items,
    );
  }
}

class TransactionItem {
  final int? id;
  final int? transactionId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  TransactionItem({
    this.id,
    this.transactionId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      price: map['price'] is int ? (map['price'] as int).toDouble() : map['price'],
      quantity: map['quantity'],
      subtotal: map['subtotal'] is int ? (map['subtotal'] as int).toDouble() : map['subtotal'],
    );
  }

  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    String? productName,
    double? price,
    int? quantity,
    double? subtotal,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
