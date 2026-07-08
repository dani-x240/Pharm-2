import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDrugDialog(BuildContext context, [Map<String, dynamic>? drug]) {
    final isEdit = drug != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: isEdit ? drug['name'] : '');
    final categoryController = TextEditingController(text: isEdit ? drug['category'] : '');
    final buyingController = TextEditingController(text: isEdit ? drug['buying_price'].toString() : '');
    final sellingController = TextEditingController(text: isEdit ? drug['selling_price'].toString() : '');
    final qtyController = TextEditingController(text: isEdit ? drug['quantity'].toString() : '');
    final unitController = TextEditingController(text: isEdit ? drug['unit'] : 'Tablets');
    final expiryController = TextEditingController(text: isEdit ? drug['expiry_date'] : '');
    final batchController = TextEditingController(text: isEdit ? drug['batch_number'] : '');
    final supplierController = TextEditingController(text: isEdit ? drug['supplier'] : '');
    final reorderController = TextEditingController(text: isEdit ? drug['reorder_level'].toString() : '10');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit Medicine' : 'Add New Medicine',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(nameController, 'Drug Name *', 'e.g., Paracetamol', isDark, validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    _buildDialogTextField(categoryController, 'Category *', 'e.g., Painkiller', isDark, validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDialogTextField(buyingController, 'Buying Price *', 'e.g., 500', isDark, keyboard: TextInputType.number, validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid price' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDialogTextField(sellingController, 'Selling Price *', 'e.g., 1000', isDark, keyboard: TextInputType.number, validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid price' : null)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDialogTextField(qtyController, 'Quantity *', 'e.g., 100', isDark, keyboard: TextInputType.number, enabled: !isEdit, validator: (val) => int.tryParse(val ?? '') == null ? 'Invalid quantity' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDialogTextField(unitController, 'Unit *', 'e.g., Tablets, Bottles', isDark, validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiryController,
                            readOnly: true,
                            style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            decoration: _dialogInputDecoration('Expiry Date *', 'YYYY-MM-DD', isDark),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: isEdit ? DateTime.parse(drug['expiry_date']) : DateTime.now().add(const Duration(days: 365)),
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                expiryController.text = DateFormat('yyyy-MM-dd').format(picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDialogTextField(batchController, 'Batch Number *', 'e.g., PAR2027A', isDark, validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDialogTextField(supplierController, 'Supplier *', 'e.g., ABC Medical', isDark, validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDialogTextField(reorderController, 'Reorder Alert level', 'e.g., 10', isDark, keyboard: TextInputType.number, validator: (val) => int.tryParse(val ?? '') == null ? 'Invalid number' : null)),
                      ],
                    ),
                  ],
                ),
              ),
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

                final provider = Provider.of<InventoryProvider>(context, listen: false);
                bool success;

                if (isEdit) {
                  success = await provider.editDrug(
                    id: drug['id'],
                    name: nameController.text,
                    category: categoryController.text,
                    buyingPrice: double.parse(buyingController.text),
                    sellingPrice: double.parse(sellingController.text),
                    quantity: int.parse(qtyController.text),
                    unit: unitController.text,
                    expiryDate: expiryController.text,
                    batchNumber: batchController.text,
                    supplier: supplierController.text,
                    reorderLevel: int.parse(reorderController.text),
                  );
                } else {
                  success = await provider.addDrug(
                    name: nameController.text,
                    category: categoryController.text,
                    buyingPrice: double.parse(buyingController.text),
                    sellingPrice: double.parse(sellingController.text),
                    quantity: int.parse(qtyController.text),
                    unit: unitController.text,
                    expiryDate: expiryController.text,
                    batchNumber: batchController.text,
                    supplier: supplierController.text,
                    reorderLevel: int.parse(reorderController.text),
                  );
                }

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Medicine saved successfully!' : 'Error saving medicine.'),
                      backgroundColor: success ? const Color(0xFF0D9488) : Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
              child: Text(isEdit ? 'Save Changes' : 'Add Drug'),
            ),
          ],
        );
      },
    );
  }

  void _showRestockDialog(BuildContext context, Map<String, dynamic> drug) {
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController();
    final buyingController = TextEditingController(text: drug['buying_price'].toString());
    final supplierController = TextEditingController(text: drug['supplier'].toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Restock: ${drug['name']}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Stock: ${drug['quantity']} ${drug['unit']}',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488)),
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(qtyController, 'Additional Quantity *', 'e.g., 50', isDark, keyboard: TextInputType.number, validator: (val) => int.tryParse(val ?? '') == null ? 'Invalid quantity' : null),
                const SizedBox(height: 12),
                _buildDialogTextField(buyingController, 'New Buying Price (UGX) *', 'e.g., 600', isDark, keyboard: TextInputType.number, validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid price' : null),
                const SizedBox(height: 12),
                _buildDialogTextField(supplierController, 'Supplier *', 'e.g., ABC Medical Supplies', isDark, validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null),
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

                final provider = Provider.of<InventoryProvider>(context, listen: false);
                final success = await provider.restockDrug(
                  drugId: drug['id'],
                  quantity: int.parse(qtyController.text),
                  buyingPrice: double.parse(buyingController.text),
                  supplier: supplierController.text,
                );

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Restock logged successfully!' : 'Error logging restock.'),
                      backgroundColor: success ? const Color(0xFF0D9488) : Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
              child: const Text('Save Restock'),
            ),
          ],
        );
      },
    );
  }

  void _deleteConfirm(BuildContext context, Map<String, dynamic> drug) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Medicine?'),
          content: Text('Are you sure you want to delete ${drug['name']}? This will also delete its purchase logs.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<InventoryProvider>(context, listen: false).deleteDrug(drug['id']);
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
    final provider = Provider.of<InventoryProvider>(context);
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'UGX ', decimalDigits: 0);

    // Filter drugs
    final filteredDrugs = provider.drugs.where((drug) {
      final name = (drug['name'] as String).toLowerCase();
      final category = (drug['category'] as String).toLowerCase();
      final batch = (drug['batch_number'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query) || batch.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Inventory Management',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0D9488),
          unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0D9488),
          tabs: const [
            Tab(text: 'All Medicines'),
            Tab(text: 'Restock Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All Medicines list
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search by name, category, batch...',
                    hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Drugs List
                Expanded(
                  child: filteredDrugs.isEmpty
                      ? Center(
                          child: Text(
                            'No medicines in inventory.',
                            style: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredDrugs.length,
                          itemBuilder: (context, index) {
                            final drug = filteredDrugs[index];
                            final name = drug['name'] as String;
                            final category = drug['category'] as String;
                            final qty = drug['quantity'] as int;
                            final unit = drug['unit'] as String;
                            final buyPrice = (drug['buying_price'] as num).toDouble();
                            final sellPrice = (drug['selling_price'] as num).toDouble();
                            final expiry = drug['expiry_date'] as String;
                            final batch = drug['batch_number'] as String;
                            final supplier = drug['supplier'] as String;
                            final isLow = qty <= (drug['reorder_level'] as int? ?? 10);

                            // Calculate remaining days for display
                            int diffDays = 999;
                            try {
                              diffDays = DateTime.parse(expiry).difference(DateTime.now()).inDays;
                            } catch (_) {}

                            final isExpiring = diffDays >= 0 && diffDays <= 30;

                            return Card(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 16),
                              borderOnForeground: true,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: isLow || isExpiring
                                      ? (isExpiring ? Colors.redAccent.withOpacity(0.15) : Colors.orangeAccent.withOpacity(0.15))
                                      : const Color(0xFF0D9488).withOpacity(0.15),
                                  child: Icon(
                                    isExpiring
                                        ? Icons.hourglass_bottom_rounded
                                        : (isLow ? Icons.warning_amber_rounded : Icons.medication_rounded),
                                    color: isExpiring
                                        ? Colors.redAccent
                                        : (isLow ? Colors.orangeAccent : const Color(0xFF0D9488)),
                                  ),
                                ),
                                title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                subtitle: Text('$category • $qty $unit left'),
                                childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoColumn('Buying Price', currencyFmt.format(buyPrice), isDark),
                                      _buildInfoColumn('Selling Price', currencyFmt.format(sellPrice), isDark),
                                      _buildInfoColumn('Batch Number', batch, isDark),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoColumn(
                                        'Expiry Date',
                                        isExpiring ? '$expiry (⚠ Expiring)' : expiry,
                                        isDark,
                                        valColor: isExpiring ? Colors.redAccent : null,
                                      ),
                                      _buildInfoColumn('Supplier', supplier, isDark),
                                      _buildInfoColumn('Alert Level', '${drug['reorder_level'] ?? 10} $unit', isDark),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.add_business_rounded, size: 18),
                                        label: const Text('Restock'),
                                        onPressed: () => _showRestockDialog(context, drug),
                                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF0D9488)),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_rounded, size: 18),
                                        label: const Text('Edit'),
                                        onPressed: () => _showAddEditDrugDialog(context, drug),
                                        style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_rounded, size: 18),
                                        label: const Text('Delete'),
                                        onPressed: () => _deleteConfirm(context, drug),
                                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Tab 2: Purchases Log
          provider.purchases.isEmpty
              ? Center(
                  child: Text(
                    'No restock history found.',
                    style: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.purchases.length,
                  itemBuilder: (context, index) {
                    final item = provider.purchases[index];
                    final drugName = item['drug_name'] ?? 'Unknown';
                    final qty = item['quantity'] as int;
                    final unit = item['drug_unit'] ?? 'units';
                    final price = (item['buying_price'] as num).toDouble();
                    final date = item['purchase_date'] as String;
                    final supplier = item['supplier'] as String;

                    return Card(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.15),
                          child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.indigo),
                        ),
                        title: Text(
                          '$drugName (+$qty $unit)',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text('Bought from: $supplier • Date: $date'),
                        trailing: Text(
                          currencyFmt.format(price),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: ValueNotifier(_tabController.index),
        builder: (context, val, _) {
          return FloatingActionButton.extended(
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Medicine'),
            onPressed: () => _showAddEditDrugDialog(context),
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn(String label, String val, bool isDark, {Color? valColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    String hint,
    bool isDark, {
    TextInputType keyboard = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      enabled: enabled,
      validator: validator,
      style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: _dialogInputDecoration(label, hint, isDark),
    );
  }

  InputDecoration _dialogInputDecoration(String label, String hint, bool isDark) {
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
