import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/sales_provider.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _amountPaidController = TextEditingController();

  String _searchQuery = '';
  int _activeTab = 0; // 0 = Browse, 1 = Cart (for mobile view)

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  void _processCheckout(
    SalesProvider salesProvider,
    List<Map<String, dynamic>> allDrugs,
    double totalAmount,
    double totalCost,
  ) async {
    final paidText = _amountPaidController.text.trim();
    final amtPaid = paidText.isEmpty ? totalAmount : double.tryParse(paidText) ?? totalAmount;

    if (amtPaid < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount paid cannot be negative.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await salesProvider.checkout(
      allDrugs: allDrugs,
      customerName: _customerNameController.text,
      amountPaid: amtPaid,
      totalAmount: totalAmount,
      totalCost: totalCost,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale processed successfully!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
        // Refresh inventory to update quantities on screen
        Provider.of<InventoryProvider>(context, listen: false).loadInventory();
        _customerNameController.clear();
        _amountPaidController.clear();
        setState(() {
          _activeTab = 0;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error processing checkout. Please check stock.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);

    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'UGX ', decimalDigits: 0);

    // Filter drugs by search query
    final filteredDrugs = inventoryProvider.drugs.where((drug) {
      final name = (drug['name'] as String).toLowerCase();
      final category = (drug['category'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    final totalAmount = salesProvider.getCartTotal(inventoryProvider.drugs);
    final totalCost = salesProvider.getCartCost(inventoryProvider.drugs);
    final profit = totalAmount - totalCost;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 750;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Sell Drug (POS)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: !isTablet
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Browse Drugs', salesProvider.cart.length, isDark),
                    _buildTabButton(1, 'Cart', salesProvider.cart.length, isDark),
                  ],
                ),
              )
            : null,
      ),
      body: isTablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left pane: Browse & Search
                Expanded(
                  flex: 3,
                  child: _buildSearchPane(filteredDrugs, salesProvider, currencyFormat, isDark),
                ),
                VerticalDivider(width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                // Right pane: Cart & Checkout
                Expanded(
                  flex: 2,
                  child: _buildCartPane(salesProvider, inventoryProvider.drugs, totalAmount, totalCost, profit, currencyFormat, isDark),
                ),
              ],
            )
          : (_activeTab == 0
              ? _buildSearchPane(filteredDrugs, salesProvider, currencyFormat, isDark)
              : _buildCartPane(salesProvider, inventoryProvider.drugs, totalAmount, totalCost, profit, currencyFormat, isDark)),
    );
  }

  Widget _buildTabButton(int index, String label, int cartCount, bool isDark) {
    final active = _activeTab == index;
    final color = active ? const Color(0xFF0D9488) : Colors.transparent;
    final textStyle = GoogleFonts.inter(
      fontWeight: active ? FontWeight.bold : FontWeight.normal,
      color: active ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFF64748B),
    );

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: textStyle),
              if (index == 1 && cartCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$cartCount',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPane(
    List<Map<String, dynamic>> drugsList,
    SalesProvider salesProvider,
    NumberFormat fmt,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Search Paracetamol, painkiller, etc...',
              hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488)),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Browse Header
          Text(
            'Inventory Results (${drugsList.length})',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Grid / List of drugs
          Expanded(
            child: drugsList.isEmpty
                ? Center(
                    child: Text(
                      'No medicines found.',
                      style: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.builder(
                    itemCount: drugsList.length,
                    itemBuilder: (context, index) {
                      final drug = drugsList[index];
                      final drugId = drug['id'] as int;
                      final name = drug['name'] as String;
                      final category = drug['category'] as String;
                      final qty = drug['quantity'] as int;
                      final unit = drug['unit'] as String;
                      final price = (drug['selling_price'] as num).toDouble();
                      final isLow = qty <= (drug['reorder_level'] as int? ?? 10);

                      final cartQty = salesProvider.cart[drugId] ?? 0;
                      final remainingInStock = qty - cartQty;

                      return Card(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        borderOnForeground: true,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Text(
                                fmt.format(price),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$category • $remainingInStock $unit left',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isLow
                                        ? Colors.orangeAccent
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                                if (qty == 0)
                                  Text(
                                    'OUT OF STOCK',
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.add_shopping_cart_rounded,
                              color: remainingInStock > 0 ? const Color(0xFF0D9488) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            onPressed: remainingInStock > 0
                                ? () {
                                    salesProvider.addToCart(drugId, availableQty: qty);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$name added to cart.'),
                                        duration: const Duration(milliseconds: 500),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPane(
    SalesProvider salesProvider,
    List<Map<String, dynamic>> allDrugs,
    double totalAmount,
    double totalCost,
    double profit,
    NumberFormat fmt,
    bool isDark,
  ) {
    final cartItems = salesProvider.cart.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Current Cart',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Items listing
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          'Your cart is empty.',
                          style: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final drugId = item.key;
                      final qty = item.value;

                      final drug = allDrugs.firstWhere((d) => d['id'] == drugId, orElse: () => {});
                      if (drug.isEmpty) return const SizedBox();

                      final name = drug['name'] as String;
                      final availableQty = drug['quantity'] as int;
                      final price = (drug['selling_price'] as num).toDouble();
                      final subtotal = price * qty;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${fmt.format(price)} x $qty = ${fmt.format(subtotal)}',
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0D9488)),
                                  ),
                                ],
                              ),
                            ),
                            // Qty controls
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                                  onPressed: () => salesProvider.updateCartQty(drugId, qty - 1, availableQty),
                                ),
                                Text(
                                  '$qty',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.teal),
                                  onPressed: () => salesProvider.updateCartQty(drugId, qty + 1, availableQty),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => salesProvider.removeFromCart(drugId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Pricing Summary & POS Calculations
          if (cartItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Amount', fmt.format(totalAmount), isDark, isBold: true),
                  const SizedBox(height: 4),
                  _buildSummaryRow('Buying Cost', fmt.format(totalCost), isDark),
                  const SizedBox(height: 4),
                  _buildSummaryRow('Expected Profit', fmt.format(profit), isDark, valueColor: Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Checkout Inputs
            TextField(
              controller: _customerNameController,
              style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'Customer Name (Optional)',
                labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountPaidController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'Amount Paid (UGX)',
                labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                hintText: 'Defaults to full payment',
                hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _processCheckout(salesProvider, allDrugs, totalAmount, totalCost),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Complete Sale Checkout',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final style = GoogleFonts.inter(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: isDark ? Colors.white : const Color(0xFF0F172A),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
