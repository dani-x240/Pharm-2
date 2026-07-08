import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/sales_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProvider = Provider.of<AuthProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);

    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'UGX ', decimalDigits: 0);
    final todayStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    // Load metrics
    final totalSales = salesProvider.todaySales;
    final totalProfit = salesProvider.todayProfit;
    final totalStockVal = inventoryProvider.totalStockValue;
    final drugCount = inventoryProvider.drugs.length;
    final lowStockCount = inventoryProvider.lowStockDrugs.length;
    final expiringCount = inventoryProvider.expiringSoonDrugs.length;

    // Grid details for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 800 ? 3 : (screenWidth > 500 ? 2 : 2);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          authProvider.shopName.isNotEmpty ? authProvider.shopName : 'Pharm Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Logout / Lock App',
            icon: const Icon(Icons.lock_rounded, color: Color(0xFF0D9488)),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome header & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${authProvider.ownerName}',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todayStr,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Alerts summary section if there are critical issues
              if (lowStockCount > 0 || expiringCount > 0) ...[
                _buildAlertBanner(context, lowStockCount, expiringCount, isDark),
                const SizedBox(height: 24),
              ],

              // KPI Cards Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: screenWidth > 500 ? 1.8 : 1.4,
                children: [
                  _buildKpiCard(
                    title: "Today's Sales",
                    value: currencyFormat.format(totalSales),
                    icon: Icons.monetization_on_rounded,
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  _buildKpiCard(
                    title: "Today's Profit",
                    value: currencyFormat.format(totalProfit),
                    icon: Icons.trending_up_rounded,
                    color: Colors.teal,
                    isDark: isDark,
                  ),
                  _buildKpiCard(
                    title: "Total Stock Value",
                    value: currencyFormat.format(totalStockVal),
                    icon: Icons.inventory_2_rounded,
                    color: Colors.blueAccent,
                    isDark: isDark,
                  ),
                  _buildKpiCard(
                    title: "Medicines Count",
                    value: "$drugCount",
                    icon: Icons.medication_rounded,
                    color: Colors.indigo,
                    isDark: isDark,
                  ),
                  _buildKpiCard(
                    title: "Low Stock Alerts",
                    value: "$lowStockCount",
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                    isDark: isDark,
                    onTap: lowStockCount > 0 ? () => _showAlertsDialog(context, "Low Stock Medicines", inventoryProvider.lowStockDrugs, isDark) : null,
                  ),
                  _buildKpiCard(
                    title: "Expiring Soon",
                    value: "$expiringCount",
                    icon: Icons.hourglass_bottom_rounded,
                    color: Colors.redAccent,
                    isDark: isDark,
                    onTap: expiringCount > 0 ? () => _showAlertsDialog(context, "Expiring Soon (30 Days)", inventoryProvider.expiringSoonDrugs, isDark, showExpiry: true) : null,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Navigation Shortcuts
              Text(
                'Quick Actions',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Actions layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final actionCols = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: actionCols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth > 600 ? 1.6 : 1.3,
                    children: [
                      _buildActionButton(
                        context: context,
                        title: 'Sell Drug',
                        subtitle: 'Process customer cart',
                        icon: Icons.shopping_cart_rounded,
                        route: '/pos',
                        color: const Color(0xFF0D9488),
                        isDark: isDark,
                      ),
                      _buildActionButton(
                        context: context,
                        title: 'Inventory',
                        subtitle: 'View & add medicines',
                        icon: Icons.inventory_rounded,
                        route: '/inventory',
                        color: const Color(0xFF0F766E),
                        isDark: isDark,
                      ),
                      _buildActionButton(
                        context: context,
                        title: 'Expenses',
                        subtitle: 'Rent, utility & salaries',
                        icon: Icons.receipt_long_rounded,
                        route: '/expenses',
                        color: const Color(0xFF4F46E5),
                        isDark: isDark,
                      ),
                      _buildActionButton(
                        context: context,
                        title: 'Reports',
                        subtitle: 'Sales, margins & trends',
                        icon: Icons.bar_chart_rounded,
                        route: '/reports',
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                      ),
                      _buildActionButton(
                        context: context,
                        title: 'Customer Debts',
                        subtitle: 'Credit accounts',
                        icon: Icons.people_alt_rounded,
                        route: '/debts',
                        color: const Color(0xFFDB2777),
                        isDark: isDark,
                      ),
                      _buildActionButton(
                        context: context,
                        title: 'Settings',
                        subtitle: 'Shop & PIN setup',
                        icon: Icons.settings_rounded,
                        route: '/settings',
                        color: const Color(0xFF64748B),
                        isDark: isDark,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
               Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    ),
                    children: [
                      const TextSpan(text: 'Created & Copyrighted by '),
                      TextSpan(
                        text: 'https://www.altrastate.com/',
                        style: const TextStyle(
                          color: Color(0xFF0D9488),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            try {
                              await launchUrl(
                                Uri.parse('https://www.altrastate.com/contact'),
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {}
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: onTap != null
                ? color.withOpacity(0.4)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: onTap != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: value.length > 10 ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (onTap != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Tap to view',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    required Color color,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, int lowStock, int expiring, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Light amber
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D)), // Amber border
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFD97706), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Alerts Pending',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lowStock > 0 ? "$lowStock item(s) are low in stock. " : ""}${expiring > 0 ? "$expiring item(s) are expiring soon." : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Direct navigation to inventory or trigger details dialog
              Navigator.of(context).pushNamed('/inventory');
            },
            child: Text(
              'Manage',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertsDialog(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    bool isDark, {
    bool showExpiry = false,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final subtitleText = showExpiry
                    ? 'Expires on: ${item['expiry_date']} (Batch: ${item['batch_number']})'
                    : 'Remaining: ${item['quantity']} ${item['unit']}';
                return Card(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: showExpiry ? Colors.redAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
                      child: Icon(
                        showExpiry ? Icons.hourglass_bottom_rounded : Icons.warning_amber_rounded,
                        color: showExpiry ? Colors.redAccent : Colors.orangeAccent,
                      ),
                    ),
                    title: Text(
                      item['name'] as String,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      subtitleText,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0D9488)),
              ),
            ),
          ],
        );
      },
    );
  }
}
