import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

class InventoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _drugs = [];
  List<Map<String, dynamic>> _purchases = [];

  List<Map<String, dynamic>> get drugs => _drugs;
  List<Map<String, dynamic>> get purchases => _purchases;

  List<Map<String, dynamic>> get lowStockDrugs {
    return _drugs.where((drug) {
      final qty = drug['quantity'] as int;
      final reorder = drug['reorder_level'] as int? ?? 10;
      return qty <= reorder;
    }).toList();
  }

  List<Map<String, dynamic>> get expiringSoonDrugs {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return _drugs.where((drug) {
      try {
        final expiry = DateTime.parse(drug['expiry_date'] as String);
        final diff = expiry.difference(todayStart).inDays;
        return diff >= 0 && diff <= 30;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  double get totalStockValue {
    double value = 0.0;
    for (var drug in _drugs) {
      final buyingPrice = (drug['buying_price'] as num).toDouble();
      final qty = drug['quantity'] as int;
      value += buyingPrice * qty;
    }
    return value;
  }

  InventoryProvider() {
    loadInventory();
  }

  Future<void> loadInventory() async {
    _drugs = await DbHelper.instance.queryAll('drugs', orderBy: 'name ASC');
    _purchases = await DbHelper.instance.rawQuery('''
      SELECT p.*, d.name as drug_name, d.unit as drug_unit 
      FROM purchases p
      JOIN drugs d ON p.drug_id = d.id
      ORDER BY p.purchase_date DESC
    ''');
    notifyListeners();
  }

  Future<bool> addDrug({
    required String name,
    required String category,
    required double buyingPrice,
    required double sellingPrice,
    required int quantity,
    required String unit,
    required String expiryDate,
    required String batchNumber,
    required String supplier,
    int reorderLevel = 10,
  }) async {
    try {
      final drugId = await DbHelper.instance.insert('drugs', {
        'name': name.trim(),
        'category': category.trim(),
        'buying_price': buyingPrice,
        'selling_price': sellingPrice,
        'quantity': quantity,
        'unit': unit.trim(),
        'expiry_date': expiryDate,
        'batch_number': batchNumber.trim(),
        'supplier': supplier.trim(),
        'reorder_level': reorderLevel,
      });

      // Also record this initial quantity as a purchase
      if (quantity > 0) {
        await DbHelper.instance.insert('purchases', {
          'drug_id': drugId,
          'quantity': quantity,
          'buying_price': buyingPrice,
          'purchase_date': DateTime.now().toIso8601String().split('T')[0],
          'supplier': supplier.trim(),
        });
      }

      await loadInventory();
      return true;
    } catch (e) {
      if (kDebugMode) print('Add Drug Error: $e');
      return false;
    }
  }

  Future<bool> editDrug({
    required int id,
    required String name,
    required String category,
    required double buyingPrice,
    required double sellingPrice,
    required int quantity,
    required String unit,
    required String expiryDate,
    required String batchNumber,
    required String supplier,
    int reorderLevel = 10,
  }) async {
    try {
      await DbHelper.instance.update(
        'drugs',
        {
          'name': name.trim(),
          'category': category.trim(),
          'buying_price': buyingPrice,
          'selling_price': sellingPrice,
          'quantity': quantity,
          'unit': unit.trim(),
          'expiry_date': expiryDate,
          'batch_number': batchNumber.trim(),
          'supplier': supplier.trim(),
          'reorder_level': reorderLevel,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadInventory();
      return true;
    } catch (e) {
      if (kDebugMode) print('Edit Drug Error: $e');
      return false;
    }
  }

  Future<bool> restockDrug({
    required int drugId,
    required int quantity,
    required double buyingPrice,
    required String supplier,
  }) async {
    try {
      // Find current drug to get existing quantity
      final drugList = await DbHelper.instance.query('drugs', where: 'id = ?', whereArgs: [drugId]);
      if (drugList.isEmpty) return false;

      final currentQty = drugList.first['quantity'] as int;
      final newQty = currentQty + quantity;

      // Update drug quantity & buying price in database
      await DbHelper.instance.update(
        'drugs',
        {
          'quantity': newQty,
          'buying_price': buyingPrice,
          'supplier': supplier.trim(),
        },
        where: 'id = ?',
        whereArgs: [drugId],
      );

      // Insert purchase log
      await DbHelper.instance.insert('purchases', {
        'drug_id': drugId,
        'quantity': quantity,
        'buying_price': buyingPrice,
        'purchase_date': DateTime.now().toIso8601String().split('T')[0],
        'supplier': supplier.trim(),
      });

      await loadInventory();
      return true;
    } catch (e) {
      if (kDebugMode) print('Restock Drug Error: $e');
      return false;
    }
  }

  Future<bool> deleteDrug(int id) async {
    try {
      await DbHelper.instance.delete('drugs', where: 'id = ?', whereArgs: [id]);
      await loadInventory();
      return true;
    } catch (e) {
      if (kDebugMode) print('Delete Drug Error: $e');
      return false;
    }
  }
}
