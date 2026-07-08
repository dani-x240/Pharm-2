import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expenses_provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  void _showAddExpenseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String category = 'Rent';

    final categories = ['Rent', 'Electricity', 'Salary', 'Supplies', 'Misc'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Record Expense', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: _dialogInputDecoration('Category', isDark),
                      items: categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: _dialogInputDecoration('Amount (UGX) *', isDark, hint: 'e.g., 40000'),
                      validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid amount' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: _dialogInputDecoration('Description *', isDark, hint: 'e.g., Electricity bill for June'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: _dialogInputDecoration('Date', isDark),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final provider = Provider.of<ExpensesProvider>(context, listen: false);
                    final success = await provider.addExpense(
                      category: category,
                      amount: double.parse(amountController.text),
                      description: descController.text,
                      date: dateController.text,
                    );

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Expense recorded!' : 'Error saving expense.'),
                          backgroundColor: success ? const Color(0xFF0D9488) : Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
                  child: const Text('Save Expense'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteConfirm(BuildContext context, Map<String, dynamic> exp) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text('Are you sure you want to delete this expense of UGX ${exp['amount']} for "${exp['description']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<ExpensesProvider>(context, listen: false).deleteExpense(exp['id']);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Deleted successfully.' : 'Error deleting.'),
                      backgroundColor: success ? const Color(0xFF0D9488) : Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<ExpensesProvider>(context);
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'UGX ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Expense Tracker',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Expenses Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL EXPENSES LOGGED',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFmt.format(provider.totalExpenses),
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Expense log header
            Text(
              'Expenses History (${provider.expenses.length})',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Log
            Expanded(
              child: provider.expenses.isEmpty
                  ? Center(
                      child: Text(
                        'No expenses logged yet.',
                        style: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.expenses.length,
                      itemBuilder: (context, index) {
                        final exp = provider.expenses[index];
                        final cat = exp['category'] as String;
                        final amt = (exp['amount'] as num).toDouble();
                        final desc = exp['description'] as String;
                        final date = exp['date'] as String;

                        // Icon selection
                        IconData icon;
                        Color color;
                        switch (cat) {
                          case 'Rent':
                            icon = Icons.home_rounded;
                            color = Colors.orange;
                            break;
                          case 'Electricity':
                            icon = Icons.bolt_rounded;
                            color = Colors.amber;
                            break;
                          case 'Salary':
                            icon = Icons.payments_rounded;
                            color = Colors.green;
                            break;
                          case 'Supplies':
                            icon = Icons.shopping_basket_rounded;
                            color = Colors.blue;
                            break;
                          default:
                            icon = Icons.miscellaneous_services_rounded;
                            color = Colors.purple;
                        }

                        return Card(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.15),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              desc,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text('$cat • $date', style: GoogleFonts.inter(fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencyFmt.format(amt),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteConfirm(context, exp),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Record Expense'),
        onPressed: () => _showAddExpenseDialog(context),
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String label, bool isDark, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), fontSize: 13),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}
