import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

class ExpensesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _expenses = [];

  List<Map<String, dynamic>> get expenses => _expenses;

  double get totalExpenses {
    double total = 0.0;
    for (var exp in _expenses) {
      total += (exp['amount'] as num).toDouble();
    }
    return total;
  }

  ExpensesProvider() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    _expenses = await DbHelper.instance.queryAll('expenses', orderBy: 'date DESC');
    notifyListeners();
  }

  Future<bool> addExpense({
    required String category,
    required double amount,
    required String description,
    required String date,
  }) async {
    try {
      await DbHelper.instance.insert('expenses', {
        'category': category.trim(),
        'amount': amount,
        'description': description.trim(),
        'date': date,
      });
      await loadExpenses();
      return true;
    } catch (e) {
      if (kDebugMode) print('Add Expense Error: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await DbHelper.instance.delete('expenses', where: 'id = ?', whereArgs: [id]);
      await loadExpenses();
      return true;
    } catch (e) {
      if (kDebugMode) print('Delete Expense Error: $e');
      return false;
    }
  }

  Map<String, double> get categoryBreakdown {
    final Map<String, double> breakdown = {};
    for (var exp in _expenses) {
      final cat = exp['category'] as String;
      final amt = (exp['amount'] as num).toDouble();
      breakdown[cat] = (breakdown[cat] ?? 0.0) + amt;
    }
    return breakdown;
  }
}
