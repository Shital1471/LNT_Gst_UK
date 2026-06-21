import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../invoice/views/invoice_history_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int) onTabChange;
  const DashboardScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesVal = ref.watch(invoicesStreamProvider);
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: invoicesVal.when(
        data: (list) {
          final now = DateTime.now();

          // 1. Calculations
          final totalInvoices = list.length;
          
          final todayInvoices = list.where((inv) =>
              inv.invoiceDate.year == now.year &&
              inv.invoiceDate.month == now.month &&
              inv.invoiceDate.day == now.day);
          final todayRevenue = todayInvoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);

          final monthlyInvoices = list.where((inv) =>
              inv.invoiceDate.year == now.year &&
              inv.invoiceDate.month == now.month);
          final monthlyRevenue = monthlyInvoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
          final monthlyGst = monthlyInvoices.fold(0.0, (sum, inv) => sum + inv.totalGst);

          // 2. Chart Grouping (Last 6 Months)
          final Map<int, double> monthRevenueMap = {};
          for (int i = 5; i >= 0; i--) {
            final targetMonth = DateTime(now.year, now.month - i, 1);
            monthRevenueMap[targetMonth.month] = 0.0;
          }

          for (final inv in list) {
            final month = inv.invoiceDate.month;
            if (monthRevenueMap.containsKey(month) && inv.invoiceDate.year == now.year) {
              monthRevenueMap[month] = monthRevenueMap[month]! + inv.grandTotal;
            }
          }

          final chartBars = monthRevenueMap.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: AppTheme.primaryGreen,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList();

          final recentInvoices = list.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ROW 1: Metric KPI Grid Cards
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'Today\'s Revenue',
                        value: currencyFmt.format(todayRevenue),
                        icon: Icons.today,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'Monthly Revenue',
                        value: currencyFmt.format(monthlyRevenue),
                        icon: Icons.monetization_on,
                        color: AppTheme.deepBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'GST Collected (Month)',
                        value: currencyFmt.format(monthlyGst),
                        icon: Icons.account_balance_wallet,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'Total Invoices',
                        value: totalInvoices.toString(),
                        icon: Icons.receipt_long,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // ROW 2: Bar Chart and Recent Invoices side-by-side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sales trend chart
                    Expanded(
                      flex: 3,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly Revenue Trend (Last 6 Months)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 260,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: chartBars,
                                    borderData: FlBorderData(show: false),
                                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                            final mVal = value.toInt();
                                            final label = (mVal >= 1 && mVal <= 12) ? months[mVal] : '';
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Recent Invoices List
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Recent Invoices',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
                                  ),
                                  TextButton(
                                    onPressed: () => onTabChange(2), // History tab
                                    child: const Text('View All'),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (recentInvoices.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(child: Text('No invoices generated yet.')),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: recentInvoices.length,
                                  separatorBuilder: (c, i) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final inv = recentInvoices[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(inv.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text(inv.invoiceNumber, style: const TextStyle(fontSize: 11)),
                                      trailing: Text(
                                        currencyFmt.format(inv.grandTotal),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                      ),
                                      onTap: () => onTabChange(2), // Redirect to history to inspect
                                    );
                                  },
                                )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.deepBlue,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
