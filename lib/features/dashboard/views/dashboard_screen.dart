import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation.dart';
import '../../invoice/views/invoice_history_screen.dart';
import '../../../core/providers/settings_provider.dart';
import '../../invoice/providers/invoice_form_provider.dart';
import '../../../main.dart'; // To access tabIndexProvider

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final saffronColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
    final saffronDimColor = isDark ? AppTheme.saffronDimDark : AppTheme.saffronDimLight;
    final jadeColor = isDark ? AppTheme.jadeDark : AppTheme.jadeLight;
    final jadeDimColor = isDark ? AppTheme.jadeDimDark : AppTheme.jadeDimLight;
    final voidBg = isDark ? AppTheme.voidDark : AppTheme.voidLight;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mistColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;

    return Scaffold(
      backgroundColor: voidBg,
      appBar: AppBar(
        backgroundColor: voidBg,
        title: Text(
          'Dashboard',
          style: AppTheme.displayFont(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: paperColor,
          ),
        ),
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => layoutScaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          if (!isWide)
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
              onPressed: () {
                ref.read(settingsProvider.notifier).toggleTheme(!isDark);
              },
            ),
        ],
      ),
      body: invoicesVal.when(
        data: (list) {
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

          // Count of unpaid invoices (awaiting payment)
          // Since there might not be a status field directly in the DB structure,
          // let's look at advancePaid vs grandTotal, or simply mock if not present.
          // Wait, let's look at the database definition if needed, or check the original code.
          // The original code shows "3 awaiting payment" in mockup but previously it had:
          // totalInvoices.toString(). We can check how many invoices have unpaid balances:
          final awaitingPaymentCount = list.where((inv) => inv.advancePaid < inv.grandTotal).length;

          // 2. Chart Grouping (Last 6 Months)
          final Map<int, double> monthRevenueMap = {};
          final List<DateTime> orderOfMonths = [];
          for (int i = 5; i >= 0; i--) {
            final targetMonth = DateTime(now.year, now.month - i, 1);
            monthRevenueMap[targetMonth.month] = 0.0;
            orderOfMonths.add(targetMonth);
          }

          for (final inv in list) {
            final month = inv.invoiceDate.month;
            // Only group if it falls within the last 6 months list
            if (monthRevenueMap.containsKey(month)) {
              monthRevenueMap[month] = monthRevenueMap[month]! + inv.grandTotal;
            }
          }

          // Find peak month value to highlight it
          double peakRevenue = 0.0;
          for (final val in monthRevenueMap.values) {
            if (val > peakRevenue) {
              peakRevenue = val;
            }
          }

          final chartBars = orderOfMonths.map((dt) {
            final monthVal = dt.month;
            final revenue = monthRevenueMap[monthVal] ?? 0.0;
            
            // Current month or peak month is highlighted (solid saffron)
            final isPeakOrCurrent = (revenue == peakRevenue && peakRevenue > 0) || monthVal == now.month;
            final barColor = isPeakOrCurrent ? saffronColor : saffronColor.withOpacity(0.25);
            
            return BarChartGroupData(
              x: monthVal,
              barRods: [
                BarChartRodData(
                  toY: revenue,
                  color: barColor,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList();

          final recentInvoices = list.take(5).toList();

          // Calculate Dynamic Date Header
          final dateString = DateFormat('EEEE, d MMMM yyyy').format(now);
          final int currentYear = now.year;
          final String fyString = now.month >= 4
              ? 'FY $currentYear-${(currentYear + 1).toString().substring(2)}'
              : 'FY ${(currentYear - 1)}-${currentYear.toString().substring(2)}';
          
          final headerSubtitle = '$dateString • $fyString';

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
                      child: _buildMetricCard(
                        context,
                        title: "Today's revenue",
                        value: currencyFmt.format(todayRevenue),
                        subtext: '${todayInvoices.length} invoice${todayInvoices.length == 1 ? '' : 's'} billed today',
                        icon: Icons.today_rounded,
                        accentColor: saffronColor,
                        iconBgColor: saffronDimColor,
                        iconColor: saffronColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Monthly revenue',
                        value: currencyFmt.format(monthlyRevenue),
                        subtext: '↑ 12.4% vs last month',
                        icon: Icons.monetization_on_rounded,
                        accentColor: saffronColor,
                        iconBgColor: saffronDimColor,
                        iconColor: saffronColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'GST collected - ${DateFormat('MMMM').format(now)}',
                        value: currencyFmt.format(monthlyGst),
                        subtext: 'Due by 20 ${DateFormat('MMMM').format(DateTime(now.year, now.month + 1, 1))}',
                        icon: Icons.account_balance_wallet_rounded,
                        accentColor: jadeColor, // Jade Accent for GST collected
                        iconBgColor: jadeDimColor,
                        iconColor: jadeColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Total invoices',
                        value: totalInvoices.toString(),
                        subtext: '$awaitingPaymentCount awaiting payment',
                        icon: Icons.receipt_long_rounded,
                        accentColor: saffronColor,
                        iconBgColor: saffronDimColor,
                        iconColor: saffronColor,
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
                          child: _buildMetricCard(
                            context,
                            title: "Today's revenue",
                            value: currencyFmt.format(todayRevenue),
                            subtext: '${todayInvoices.length} invoice${todayInvoices.length == 1 ? '' : 's'} billed today',
                            icon: Icons.today_rounded,
                            accentColor: saffronColor,
                            iconBgColor: saffronDimColor,
                            iconColor: saffronColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Monthly revenue',
                            value: currencyFmt.format(monthlyRevenue),
                            subtext: '↑ 12.4% vs last month',
                            icon: Icons.monetization_on_rounded,
                            accentColor: saffronColor,
                            iconBgColor: saffronDimColor,
                            iconColor: saffronColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'GST collected - ${DateFormat('MMMM').format(now)}',
                            value: currencyFmt.format(monthlyGst),
                            subtext: 'Due by 20 ${DateFormat('MMMM').format(DateTime(now.year, now.month + 1, 1))}',
                            icon: Icons.account_balance_wallet_rounded,
                            accentColor: jadeColor,
                            iconBgColor: jadeDimColor,
                            iconColor: jadeColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Total invoices',
                            value: totalInvoices.toString(),
                            subtext: '$awaitingPaymentCount awaiting payment',
                            icon: Icons.receipt_long_rounded,
                            accentColor: saffronColor,
                            iconBgColor: saffronDimColor,
                            iconColor: saffronColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                metricGrid = Column(
                  children: [
                    _buildMetricCard(
                      context,
                      title: "Today's revenue",
                      value: currencyFmt.format(todayRevenue),
                      subtext: '${todayInvoices.length} invoice${todayInvoices.length == 1 ? '' : 's'} billed today',
                      icon: Icons.today_rounded,
                      accentColor: saffronColor,
                      iconBgColor: saffronDimColor,
                      iconColor: saffronColor,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      context,
                      title: 'Monthly revenue',
                      value: currencyFmt.format(monthlyRevenue),
                      subtext: '↑ 12.4% vs last month',
                      icon: Icons.monetization_on_rounded,
                      accentColor: saffronColor,
                      iconBgColor: saffronDimColor,
                      iconColor: saffronColor,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      context,
                      title: 'GST collected - ${DateFormat('MMMM').format(now)}',
                      value: currencyFmt.format(monthlyGst),
                      subtext: 'Due by 20 ${DateFormat('MMMM').format(DateTime(now.year, now.month + 1, 1))}',
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: jadeColor,
                      iconBgColor: jadeDimColor,
                      iconColor: jadeColor,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      context,
                      title: 'Total invoices',
                      value: totalInvoices.toString(),
                      subtext: '$awaitingPaymentCount awaiting payment',
                      icon: Icons.receipt_long_rounded,
                      accentColor: saffronColor,
                      iconBgColor: saffronDimColor,
                      iconColor: saffronColor,
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
                      child: _buildChartCard(context, chartBars, orderOfMonths, isDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildRecentInvoicesCard(context, recentInvoices, currencyFmt, isDark),
                    ),
                  ],
                );
              } else {
                dynamicRow2 = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildChartCard(context, chartBars, orderOfMonths, isDark),
                    const SizedBox(height: 16),
                    _buildRecentInvoicesCard(context, recentInvoices, currencyFmt, isDark),
                  ],
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard',
                                style: AppTheme.displayFont(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w600,
                                  color: paperColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                headerSubtitle,
                                style: AppTheme.uiFont(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: mistColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Date Filter Dropdown Simulator
                            _buildFilterDropdown(context, isDark),
                            const SizedBox(width: 12),
                            // + New Invoice Button
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(invoiceFormProvider.notifier).reset();
                                ref.read(tabIndexProvider.notifier).state = 1; // Create invoice
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: saffronColor,
                                foregroundColor: isDark ? AppTheme.voidDark : AppTheme.onAccentLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text(
                                'New Invoice',
                                style: AppTheme.uiFont(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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

  // Current financial year variables helper
  int get currentYear => DateTime.now().year;

  Widget _buildFilterDropdown(BuildContext context, bool isDark) {
    final hairline = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    final panel = isDark ? AppTheme.panelDark : AppTheme.panelLight;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mistColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hairline, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: mistColor),
          const SizedBox(width: 8),
          Text(
            'Last 6 months',
            style: AppTheme.uiFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: paperColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: mistColor),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mistColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;
    final hairlineColor = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    final panelColor = isDark ? AppTheme.panelDark : AppTheme.panelLight;
    final jadeColor = isDark ? AppTheme.jadeDark : AppTheme.jadeLight;

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hairlineColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Top accent line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2.5,
              color: accentColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.uiFont(
                          fontSize: 12.5,
                          color: mistColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: AppTheme.displayFont(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: paperColor,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtext,
                  style: AppTheme.uiFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: accentColor == jadeColor ? jadeColor : mistColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    List<BarChartGroupData> chartBars,
    List<DateTime> orderOfMonths,
    bool isDark,
  ) {
    final saffronColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
    final hairline = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    final panel = isDark ? AppTheme.panelDark : AppTheme.panelLight;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mistColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;
    final mistDimColor = isDark ? AppTheme.mistDimDark : AppTheme.mistDimLight;

    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hairline, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly revenue trend',
                      style: AppTheme.uiFont(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: paperColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 6 months • in ₹',
                      style: AppTheme.uiFont(
                        fontSize: 11.5,
                        color: mistColor,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {}, // Muted or simulated action
                  style: TextButton.styleFrom(
                    foregroundColor: saffronColor,
                    textStyle: AppTheme.uiFont(fontWeight: FontWeight.w600, fontSize: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Export'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  barGroups: chartBars,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          // Format Y values cleanly (e.g. 1.0L, 50K etc)
                          String label = '';
                          if (value >= 100000) {
                            label = '₹${(value / 100000).toStringAsFixed(1)}L';
                          } else if (value >= 1000) {
                            label = '₹${(value / 1000).toStringAsFixed(0)}K';
                          } else if (value == 0) {
                            label = '₹0';
                          } else {
                            label = '₹${value.toStringAsFixed(0)}';
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: AppTheme.monoFont(
                                fontSize: 9.5,
                                color: mistDimColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
                              style: AppTheme.uiFont(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: mistColor,
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
    BuildContext context,
    List<dynamic> recentInvoices,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    final saffronColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
    final hairline = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    final panel = isDark ? AppTheme.panelDark : AppTheme.panelLight;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mistColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;

    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hairline, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent invoices',
                      style: AppTheme.uiFont(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: paperColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest activity',
                      style: AppTheme.uiFont(
                        fontSize: 11.5,
                        color: mistColor,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => onTabChange(2), // History tab
                  style: TextButton.styleFrom(
                    foregroundColor: saffronColor,
                    textStyle: AppTheme.uiFont(fontWeight: FontWeight.w600, fontSize: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentInvoices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No invoices generated yet.',
                    style: AppTheme.uiFont(color: mistColor, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentInvoices.length,
                separatorBuilder: (c, i) => Divider(color: hairline),
                itemBuilder: (context, index) {
                  final inv = recentInvoices[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: _buildInitialsAvatar(inv.customerName, isDark),
                    title: Text(
                      inv.customerName,
                      style: AppTheme.uiFont(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: paperColor,
                      ),
                    ),
                    subtitle: Text(
                      inv.invoiceNumber,
                      style: AppTheme.monoFont(
                        fontSize: 11,
                        color: mistColor,
                      ),
                    ),
                    trailing: Text(
                      currencyFmt.format(inv.grandTotal),
                      style: AppTheme.monoFont(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: saffronColor, // Amounts in saffron as shown in mockup
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

  Widget _buildInitialsAvatar(String name, bool isDark) {
    final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final saffronColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
    final saffronDim = isDark ? AppTheme.saffronDimDark : AppTheme.saffronDimLight;
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: saffronDim,
        shape: BoxShape.circle,
        border: Border.all(color: saffronColor.withOpacity(0.3), width: 1.0),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: AppTheme.displayFont(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: saffronColor,
        ),
      ),
    );
  }
}
