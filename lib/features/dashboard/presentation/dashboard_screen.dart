import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../accounting/presentation/accounting_reports_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String selectedPeriod = 'This Week';

  DateRange rangeForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        return DateRange(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
      case 'This Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateRange(DateTime(start.year, start.month, start.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
      case 'This Month':
        return DateRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month, now.day, 23, 59, 59));
      case 'This Year':
        return DateRange(DateTime(now.year, 1, 1), DateTime(now.year, now.month, now.day, 23, 59, 59));
      case 'All Time':
      default:
        return DateRange(DateTime.fromMillisecondsSinceEpoch(0), DateTime(now.year, now.month, now.day, 23, 59, 59));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Period selector state local to widget
    final periodOptions = ['Today', 'This Week', 'This Month', 'This Year', 'All Time'];
    String selectedPeriod = periodOptions.first;

    DateRange rangeForPeriod(String period) {
      final now = DateTime.now();
      switch (period) {
        case 'Today':
          return DateRange(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
        case 'This Week':
          final start = now.subtract(Duration(days: now.weekday - 1));
          return DateRange(DateTime(start.year, start.month, start.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
        case 'This Month':
          return DateRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month, now.day, 23, 59, 59));
        case 'This Year':
          return DateRange(DateTime(now.year, 1, 1), DateTime(now.year, now.month, now.day, 23, 59, 59));
        case 'All Time':
        default:
          return DateRange(DateTime.fromMillisecondsSinceEpoch(0), DateTime(now.year, now.month, now.day, 23, 59, 59));
      }
    }

    final range = rangeForPeriod(selectedPeriod);

    final salesAsync = ref.watch(salesTotalForRangeProvider(range));
    final purchasesAsync = ref.watch(purchasesTotalForRangeProvider(range));
    final inventoryAsync = ref.watch(inventoryValueProvider);
    final profitAsync = ref.watch(netProfitForRangeProvider(range));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          if (currentUser != null) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentUser.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                Text(
                  currentUser.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
          IconButton(
            icon: Icon(
              themeMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state = !themeMode;
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
                onTap: () {
                  ref.read(currentUserProvider.notifier).state = null;
                  context.go('/login');
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'Accounting Reports',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountingReportsScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            const SizedBox(height: 24),
            // Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 1200 ? 4 : (width > 800 ? 2 : 1);
                
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: [
                    _StatCard.fromAsync(
                      title: 'Total Sales',
                      asyncValue: salesAsync,
                      icon: Icons.trending_up,
                      color: Colors.green,
                      trend: '',
                    ),
                    _StatCard.fromAsync(
                      title: 'Total Purchases',
                      asyncValue: purchasesAsync,
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.blue,
                      trend: '',
                    ),
                    _StatCard.fromAsync(
                      title: 'Inventory Value',
                      asyncValue: inventoryAsync,
                      icon: Icons.inventory_2_outlined,
                      color: Colors.orange,
                      trend: '',
                    ),
                      _StatCard.fromAsync(
                        title: 'Net Profit',
                        asyncValue: profitAsync,
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.purple,
                        trend: '',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AccountingReportsScreen()),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Charts Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sales Analytics',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            DropdownButton<String>(
                              value: selectedPeriod,
                              underline: const SizedBox(),
                              items: ['Today', 'This Week', 'This Month', 'This Year', 'All Time']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => selectedPeriod = v);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey.withOpacity(0.1),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      if (value.toInt() >= 0 && value.toInt() < titles.length) {
                                        return Text(
                                          titles[value.toInt()],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 6,
                              minY: 0,
                              maxY: 6,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    const FlSpot(0, 3),
                                    const FlSpot(1, 4),
                                    const FlSpot(2, 3.5),
                                    const FlSpot(3, 5),
                                    const FlSpot(4, 4),
                                    const FlSpot(5, 6),
                                    const FlSpot(6, 5.5),
                                  ],
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Products',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: 40,
                                  title: '40%',
                                  color: Theme.of(context).colorScheme.primary,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 30,
                                  title: '30%',
                                  color: Theme.of(context).colorScheme.secondary,
                                  radius: 55,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 20,
                                  title: '20%',
                                  color: Theme.of(context).colorScheme.tertiary,
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 10,
                                  title: '10%',
                                  color: Colors.grey,
                                  radius: 45,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LegendItem(color: Theme.of(context).colorScheme.primary, label: 'Electronics'),
                        _LegendItem(color: Theme.of(context).colorScheme.secondary, label: 'Clothing'),
                        _LegendItem(color: Theme.of(context).colorScheme.tertiary, label: 'Home & Garden'),
                        const _LegendItem(color: Colors.grey, label: 'Others'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isPositive;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.isPositive,
    this.onTap,
  });

  factory _StatCard.fromAsync({
    required String title,
    required AsyncValue<double> asyncValue,
    required IconData icon,
    required Color color,
    required String trend,
    VoidCallback? onTap,
  }) {
    final valueString = asyncValue.when(
      data: (v) => '\$${v.toStringAsFixed(2)}',
      loading: () => 'Loading',
      error: (_, __) => 'Error',
    );
    final isPositive = asyncValue.when(
      data: (v) => v >= 0,
      loading: () => true,
      error: (_, __) => true,
    );
    return _StatCard(
      title: title,
      value: valueString,
      icon: icon,
      color: color,
      trend: trend,
      isPositive: isPositive,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
