import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation.dart';
import '../../invoice/views/invoice_history_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int) onTabChange;
  const DashboardScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesVal = ref.watch(invoicesStreamProvider);
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final isWide = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => layoutScaffoldKey.currentState?.openDrawer(),
              ),
      ),
      body: invoicesVal.when(
        data: (list) {
          final theme = Theme.of(context);
          final now = DateTime.now();

          // 1. Calculations
          final totalInvoices = list.length;

          final todayInvoices = list.where(
            (inv) =>
                inv.invoiceDate.year == now.year &&
                inv.invoiceDate.month == now.month &&
                inv.invoiceDate.day == now.day,
          );
          final todayRevenue = todayInvoices.fold(
            0.0,
            (sum, inv) => sum + inv.grandTotal,
          );

          final monthlyInvoices = list.where(
            (inv) =>
                inv.invoiceDate.year == now.year &&
                inv.invoiceDate.month == now.month,
          );
          final monthlyRevenue = monthlyInvoices.fold(
            0.0,
            (sum, inv) => sum + inv.grandTotal,
          );
          final monthlyGst = monthlyInvoices.fold(
            0.0,
            (sum, inv) => sum + inv.totalGst,
          );

          // 2. Chart Grouping (Last 6 Months)
          final Map<int, double> monthRevenueMap = {};
          for (int i = 5; i >= 0; i--) {
            final targetMonth = DateTime(now.year, now.month - i, 1);
            monthRevenueMap[targetMonth.month] = 0.0;
          }

          for (final inv in list) {
            final month = inv.invoiceDate.month;
            if (monthRevenueMap.containsKey(month) &&
                inv.invoiceDate.year == now.year) {
              monthRevenueMap[month] = monthRevenueMap[month]! + inv.grandTotal;
            }
          }


          final chartBars = monthRevenueMap.entries.map((entry) {
            final theme = Theme.of(context);
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.6),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList();

          final recentInvoices = list.take(5).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1000;
              final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

              // KPI metrics structured responsively
              Widget metricGrid;
              if (isWide) {
                metricGrid = Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        context,
                        title: "Today's Revenue",
                        value: currencyFmt.format(todayRevenue),
                        icon: Icons.today_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'Monthly Revenue',
                        value: currencyFmt.format(monthlyRevenue),
                        icon: Icons.monetization_on_rounded,
                        color: theme.brightness == Brightness.light ? AppTheme.deepBlue : Colors.indigo.shade300,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'GST Collected (Month)',
                        value: currencyFmt.format(monthlyGst),
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'Total Invoices',
                        value: totalInvoices.toString(),
                        icon: Icons.receipt_long_rounded,
                        color: Colors.purple.shade400,
                      ),
                    ),
                  ],
                );
              } else if (isMedium) {
                metricGrid = Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            context,
                            title: "Today's Revenue",
                            value: currencyFmt.format(todayRevenue),
                            icon: Icons.today_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _metricCard(
                            context,
                            title: 'Monthly Revenue',
                            value: currencyFmt.format(monthlyRevenue),
                            icon: Icons.monetization_on_rounded,
                            color: theme.brightness == Brightness.light ? AppTheme.deepBlue : Colors.indigo.shade300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            context,
                            title: 'GST Collected (Month)',
                            value: currencyFmt.format(monthlyGst),
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _metricCard(
                            context,
                            title: 'Total Invoices',
                            value: totalInvoices.toString(),
                            icon: Icons.receipt_long_rounded,
                            color: Colors.purple.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                metricGrid = Column(
                  children: [
                    _metricCard(
                      context,
                      title: "Today's Revenue",
                      value: currencyFmt.format(todayRevenue),
                      icon: Icons.today_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _metricCard(
                      context,
                      title: 'Monthly Revenue',
                      value: currencyFmt.format(monthlyRevenue),
                      icon: Icons.monetization_on_rounded,
                      color: theme.brightness == Brightness.light ? AppTheme.deepBlue : Colors.indigo.shade300,
                    ),
                    const SizedBox(height: 12),
                    _metricCard(
                      context,
                      title: 'GST Collected (Month)',
                      value: currencyFmt.format(monthlyGst),
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppTheme.accentOrange,
                    ),
                    const SizedBox(height: 12),
                    _metricCard(
                      context,
                      title: 'Total Invoices',
                      value: totalInvoices.toString(),
                      icon: Icons.receipt_long_rounded,
                      color: Colors.purple.shade400,
                    ),
                  ],
                );
              }

              // Row 2 containing Chart and Recent Invoices
              Widget dynamicRow2;
              if (constraints.maxWidth >= 900) {
                dynamicRow2 = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildChartCard(context, chartBars),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildRecentInvoicesCard(context, recentInvoices, currencyFmt),
                    ),
                  ],
                );
              } else {
                dynamicRow2 = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildChartCard(context, chartBars),
                    const SizedBox(height: 16),
                    _buildRecentInvoicesCard(context, recentInvoices, currencyFmt),
                  ],
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    metricGrid,
                    const SizedBox(height: 24),
                    dynamicRow2,
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, List<BarChartGroupData> chartBars) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Revenue Trend (Last 6 Months)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  barGroups: chartBars,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withOpacity(0.06),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = [
                            '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                          ];
                          final mVal = value.toInt();
                          final label = (mVal >= 1 && mVal <= 12) ? months[mVal] : '';
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
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
    );
  }

  Widget _buildRecentInvoicesCard(
      BuildContext context, List<dynamic> recentInvoices, NumberFormat currencyFmt) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Invoices',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => onTabChange(2), // History tab
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentInvoices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No invoices generated yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentInvoices.length,
                separatorBuilder: (c, i) => Divider(color: theme.dividerColor.withOpacity(0.08)),
                itemBuilder: (context, index) {
                  final inv = recentInvoices[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      inv.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      inv.invoiceNumber,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    trailing: Text(
                      currencyFmt.format(inv.grandTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    onTap: () => onTabChange(2), // Redirect to history
                  );
                },
              ),
          ],
        ),
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
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
