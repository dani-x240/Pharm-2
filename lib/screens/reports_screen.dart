import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;

  double _totalSales = 0.0;
  double _grossProfit = 0.0;
  double _totalExpenses = 0.0;
  double _netProfit = 0.0;

  List<Map<String, dynamic>> _bestSellers = [];
  List<Map<String, dynamic>> _lowestSellers = [];
  List<Map<String, dynamic>> _monthlyTrends = [];
  Map<String, double> _expenseBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Core aggregates
      final salesData = await DbHelper.instance.rawQuery('SELECT SUM(total_amount) as sales, SUM(total_profit) as profit FROM sales');
      final expensesData = await DbHelper.instance.rawQuery('SELECT SUM(amount) as expenses FROM expenses');

      _totalSales = (salesData.first['sales'] as num?)?.toDouble() ?? 0.0;
      _grossProfit = (salesData.first['profit'] as num?)?.toDouble() ?? 0.0;
      _totalExpenses = (expensesData.first['expenses'] as num?)?.toDouble() ?? 0.0;
      _netProfit = _grossProfit - _totalExpenses;

      // 2. Best sellers (Top 5)
      _bestSellers = await DbHelper.instance.rawQuery('''
        SELECT d.name as drug_name, d.category as drug_cat, SUM(s.quantity) as total_qty, SUM(s.profit) as total_profit
        FROM sale_items s
        JOIN drugs d ON s.drug_id = d.id
        GROUP BY s.drug_id
        ORDER BY total_qty DESC
        LIMIT 5
      ''');

      // 3. Lowest sellers (Bottom 5, only items that have sold at least once)
      _lowestSellers = await DbHelper.instance.rawQuery('''
        SELECT d.name as drug_name, d.category as drug_cat, SUM(s.quantity) as total_qty, SUM(s.profit) as total_profit
        FROM sale_items s
        JOIN drugs d ON s.drug_id = d.id
        GROUP BY s.drug_id
        ORDER BY total_qty ASC
        LIMIT 5
      ''');

      // 4. Monthly trends (Last 6 months)
      _monthlyTrends = await DbHelper.instance.rawQuery('''
        SELECT SUBSTR(sale_date, 1, 7) as month, SUM(total_amount) as sales, SUM(total_profit) as profit
        FROM sales
        GROUP BY month
        ORDER BY month ASC
        LIMIT 6
      ''');

      // 5. Expense breakdown
      final expensesBreakdownData = await DbHelper.instance.rawQuery('''
        SELECT category, SUM(amount) as total
        FROM expenses
        GROUP BY category
      ''');

      _expenseBreakdown = {};
      for (var row in expensesBreakdownData) {
        _expenseBreakdown[row['category'] as String] = (row['total'] as num).toDouble();
      }
    } catch (e) {
      // Handle db error silently
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'UGX ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Financial Reports',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0D9488)),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI financial overview cards
                  _buildFinancialGrid(currencyFmt, isDark),
                  const SizedBox(height: 32),

                  // Sales & Profit Trends Chart
                  _buildTrendsSection(currencyFmt, isDark),
                  const SizedBox(height: 32),

                  // Expense Breakdown Section
                  _buildExpenseDistributionSection(currencyFmt, isDark),
                  const SizedBox(height: 32),

                  // Medicine Sales lists
                  _buildProductPerformanceTabs(currencyFmt, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildFinancialGrid(NumberFormat fmt, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildFinancialCard('Total Sales', fmt.format(_totalSales), Colors.indigo, isDark),
        _buildFinancialCard('Gross Profit', fmt.format(_grossProfit), Colors.teal, isDark),
        _buildFinancialCard('Total Expenses', fmt.format(_totalExpenses), Colors.redAccent, isDark),
        _buildFinancialCard(
          'Net Profit',
          fmt.format(_netProfit),
          _netProfit >= 0 ? Colors.green : Colors.red,
          isDark,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildFinancialCard(String title, String val, Color color, bool isDark, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary
            ? color.withOpacity(0.15)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isPrimary ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPrimary ? color : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(NumberFormat fmt, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Sales & Profit Trends',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _monthlyTrends.isEmpty
              ? const SizedBox(
                  height: 200,
                  child: Center(child: Text('No historical transactions found yet.')),
                )
              : SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxSalesY(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final index = val.toInt();
                              if (index >= 0 && index < _monthlyTrends.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _monthlyTrends[index]['month'].toString().substring(5),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(_monthlyTrends.length, (idx) {
                        final data = _monthlyTrends[idx];
                        final salesVal = (data['sales'] as num).toDouble();
                        final profitVal = (data['profit'] as num).toDouble();
                        return BarChartGroupData(
                          x: idx,
                          barRods: [
                            BarChartRodData(
                              toY: salesVal,
                              color: const Color(0xFF4F46E5),
                              width: 12,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: profitVal,
                              color: const Color(0xFF0D9488),
                              width: 12,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendBadge(const Color(0xFF4F46E5), 'Gross Revenue'),
              const SizedBox(width: 24),
              _buildLegendBadge(const Color(0xFF0D9488), 'Gross Profit'),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxSalesY() {
    double maxVal = 1000.0;
    for (var row in _monthlyTrends) {
      final s = (row['sales'] as num).toDouble();
      if (s > maxVal) maxVal = s;
    }
    return maxVal * 1.15; // 15% padding
  }

  Widget _buildLegendBadge(Color col, String lbl) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(lbl, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildExpenseDistributionSection(NumberFormat fmt, bool isDark) {
    final values = _expenseBreakdown.entries.toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operational Expenses Breakdown',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _expenseBreakdown.isEmpty
              ? const SizedBox(
                  height: 150,
                  child: Center(child: Text('No expenses recorded yet.')),
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: List.generate(values.length, (index) {
                              final entry = values[index];
                              final color = _getCategoryColor(entry.key);
                              final pct = (entry.value / _totalExpenses) * 100;
                              return PieChartSectionData(
                                color: color,
                                value: entry.value,
                                title: '${pct.toStringAsFixed(0)}%',
                                radius: 45,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: values.map((entry) {
                          final col = _getCategoryColor(entry.key);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${entry.key}: ${fmt.format(entry.value)}',
                                    style: GoogleFonts.inter(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Rent':
        return Colors.orange;
      case 'Electricity':
        return Colors.amber;
      case 'Salary':
        return Colors.green;
      case 'Supplies':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  Widget _buildProductPerformanceTabs(NumberFormat fmt, bool isDark) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              labelColor: const Color(0xFF0D9488),
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0D9488),
              tabs: const [
                Tab(text: 'Top Selling Drugs'),
                Tab(text: 'Lowest Selling Drugs'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: TabBarView(
              children: [
                _buildProductList(_bestSellers, fmt, isDark, true),
                _buildProductList(_lowestSellers, fmt, isDark, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> items, NumberFormat fmt, bool isDark, bool isBestSeller) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No transaction items recorded.',
          style: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['drug_name'] ?? 'Unknown';
        final category = item['drug_cat'] ?? '';
        final qty = item['total_qty'] as int;
        final profit = (item['total_profit'] as num).toDouble();

        return Card(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isBestSeller ? Colors.teal.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isBestSeller ? Colors.teal : Colors.redAccent,
                ),
              ),
            ),
            title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            subtitle: Text('$category • $qty units sold'),
            trailing: Text(
              'Profit: ${fmt.format(profit)}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isBestSeller ? Colors.teal : Colors.orange,
              ),
            ),
          ),
        );
      },
    );
  }
}
