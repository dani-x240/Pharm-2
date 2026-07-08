import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

class SalesProvider extends ChangeNotifier {
  // Cart maps drugId -> quantity
  final Map<int, int> _cart = {};
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _customers = [];

  Map<int, int> get cart => _cart;
  List<Map<String, dynamic>> get sales => _sales;
  List<Map<String, dynamic>> get customers => _customers;

  double get todaySales {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    double total = 0.0;
    for (var sale in _sales) {
      if (sale['sale_date'].toString().startsWith(todayStr)) {
        total += (sale['total_amount'] as num).toDouble();
      }
    }
    return total;
  }

  double get todayProfit {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    double total = 0.0;
    for (var sale in _sales) {
      if (sale['sale_date'].toString().startsWith(todayStr)) {
        total += (sale['total_profit'] as num).toDouble();
      }
    }
    return total;
  }

  SalesProvider() {
    loadSalesData();
  }

  Future<void> loadSalesData() async {
    _sales = await DbHelper.instance.queryAll('sales', orderBy: 'sale_date DESC');
    _customers = await DbHelper.instance.query('customers', orderBy: 'name ASC');
    notifyListeners();
  }

  // Cart operations

  void addToCart(int drugId, {int qty = 1, int availableQty = 0}) {
    final currentQty = _cart[drugId] ?? 0;
    if (currentQty + qty <= availableQty) {
      _cart[drugId] = currentQty + qty;
      notifyListeners();
    }
  }

  void updateCartQty(int drugId, int qty, int availableQty) {
    if (qty <= 0) {
      _cart.remove(drugId);
    } else if (qty <= availableQty) {
      _cart[drugId] = qty;
    }
    notifyListeners();
  }

  void removeFromCart(int drugId) {
    _cart.remove(drugId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // Calculate totals from database drugs listing
  double getCartTotal(List<Map<String, dynamic>> allDrugs) {
    double total = 0.0;
    _cart.forEach((drugId, qty) {
      final drug = allDrugs.firstWhere((d) => d['id'] == drugId, orElse: () => {});
      if (drug.isNotEmpty) {
        final price = (drug['selling_price'] as num).toDouble();
        total += price * qty;
      }
    });
    return total;
  }

  double getCartCost(List<Map<String, dynamic>> allDrugs) {
    double totalCost = 0.0;
    _cart.forEach((drugId, qty) {
      final drug = allDrugs.firstWhere((d) => d['id'] == drugId, orElse: () => {});
      if (drug.isNotEmpty) {
        final cost = (drug['buying_price'] as num).toDouble();
        totalCost += cost * qty;
      }
    });
    return totalCost;
  }

  // Checkout process inside SQLite transaction
  Future<bool> checkout({
    required List<Map<String, dynamic>> allDrugs,
    String? customerName,
    required double amountPaid,
    required double totalAmount,
    required double totalCost,
  }) async {
    if (_cart.isEmpty) return false;

    try {
      final debtBalance = totalAmount - amountPaid;
      final finalCustomerName = (customerName != null && customerName.trim().isNotEmpty) ? customerName.trim() : null;

      final result = await DbHelper.instance.runInTransaction<bool>((txn) async {
        // 1. Insert Sales entry
        final saleId = await txn.insert('sales', {
          'sale_date': DateTime.now().toIso8601String(),
          'total_amount': totalAmount,
          'total_cost': totalCost,
          'total_profit': totalAmount - totalCost,
          'customer_name': finalCustomerName,
          'amount_paid': amountPaid,
          'debt_balance': debtBalance > 0 ? debtBalance : 0.0,
        });

        // 2. Process each item in cart
        for (var entry in _cart.entries) {
          final drugId = entry.key;
          final qty = entry.value;

          // Fetch original drug to reduce inventory
          final drugsResult = await txn.query('drugs', where: 'id = ?', whereArgs: [drugId]);
          if (drugsResult.isEmpty) {
            throw Exception('Drug with ID $drugId not found');
          }

          final drug = drugsResult.first;
          final drugQty = drug['quantity'] as int;
          final buyingPrice = (drug['buying_price'] as num).toDouble();
          final sellingPrice = (drug['selling_price'] as num).toDouble();
          final profit = (sellingPrice - buyingPrice) * qty;

          if (drugQty < qty) {
            throw Exception('Insufficient quantity for ${drug['name']}');
          }

          // Update drug quantity
          await txn.update(
            'drugs',
            {'quantity': drugQty - qty},
            where: 'id = ?',
            whereArgs: [drugId],
          );

          // Insert sale_items record
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'drug_id': drugId,
            'quantity': qty,
            'selling_price': sellingPrice,
            'buying_price': buyingPrice,
            'profit': profit,
          });
        }

        // 3. Update customer outstanding balance if debt exists
        if (debtBalance > 0 && finalCustomerName != null) {
          final custResult = await txn.query('customers', where: 'name = ?', whereArgs: [finalCustomerName]);
          if (custResult.isNotEmpty) {
            final currentDebt = (custResult.first['outstanding_balance'] as num).toDouble();
            await txn.update(
              'customers',
              {'outstanding_balance': currentDebt + debtBalance},
              where: 'name = ?',
              whereArgs: [finalCustomerName],
            );
          } else {
            await txn.insert('customers', {
              'name': finalCustomerName,
              'outstanding_balance': debtBalance,
            });
          }
        }

        return true;
      });

      if (result) {
        clearCart();
        await loadSalesData();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Checkout Error: $e');
      return false;
    }
  }

  // Pay Debt operation
  Future<bool> payDebt(int customerId, double amountPaid) async {
    try {
      final custResult = await DbHelper.instance.query('customers', where: 'id = ?', whereArgs: [customerId]);
      if (custResult.isEmpty) return false;

      final currentBalance = (custResult.first['outstanding_balance'] as num).toDouble();
      final customerName = custResult.first['name'] as String;
      final newBalance = currentBalance - amountPaid;

      await DbHelper.instance.update(
        'customers',
        {'outstanding_balance': newBalance >= 0 ? newBalance : 0.0},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      // Log this as a partial transaction or payment receipt
      // Simply insert a sales transaction representing the received cash
      await DbHelper.instance.insert('sales', {
        'sale_date': DateTime.now().toIso8601String(),
        'total_amount': amountPaid,
        'total_cost': 0.0, // No material cost since it was recorded on purchase
        'total_profit': amountPaid, // Direct profit payment
        'customer_name': '$customerName (Debt Payment)',
        'amount_paid': amountPaid,
        'debt_balance': 0.0,
      });

      await loadSalesData();
      return true;
    } catch (e) {
      if (kDebugMode) print('Pay Debt Error: $e');
      return false;
    }
  }
}
