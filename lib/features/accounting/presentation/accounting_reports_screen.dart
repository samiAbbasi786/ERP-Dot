import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';

class AccountingReportsScreen extends ConsumerStatefulWidget {
  const AccountingReportsScreen({super.key});

  @override
  ConsumerState<AccountingReportsScreen> createState() => _AccountingReportsScreenState();
}

class _AccountingReportsScreenState extends ConsumerState<AccountingReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
            Tab(text: 'Profit & Loss'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DailyReportTab(),
          _WeeklyReportTab(),
          _MonthlyReportTab(),
          _YearlyReportTab(),
          _ProfitLossTab(),
        ],
      ),
    );
  }
}

class _DailyReportTab extends ConsumerWidget {
  const _DailyReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountingService = ref.watch(accountingServiceProvider);
    
    return FutureBuilder<Map<String, double>>(
      future: accountingService.getDailyStats(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        return _buildSummaryCard(context, 'Today\'s Performance', data);
      },
    );
  }
}

class _WeeklyReportTab extends ConsumerWidget {
  const _WeeklyReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountingService = ref.watch(accountingServiceProvider);
    
    return FutureBuilder<Map<String, double>>(
      future: accountingService.getWeeklyStats(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        return _buildSummaryCard(context, 'This Week\'s Performance', data);
      },
    );
  }
}

class _MonthlyReportTab extends ConsumerWidget {
  const _MonthlyReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountingService = ref.watch(accountingServiceProvider);
    
    return FutureBuilder<Map<String, double>>(
      future: accountingService.getMonthlyStats(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        return _buildSummaryCard(context, 'This Month\'s Performance', data);
      },
    );
  }
}

class _YearlyReportTab extends ConsumerWidget {
  const _YearlyReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountingService = ref.watch(accountingServiceProvider);
    
    return FutureBuilder<Map<String, double>>(
      future: accountingService.getYearlyStats(DateTime.now().year),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        return _buildSummaryCard(context, 'This Year\'s Performance', data);
      },
    );
  }
}

Widget _buildSummaryCard(BuildContext context, String title, Map<String, double> data) {
  final currencyFormat = NumberFormat.currency(symbol: '\$');
  
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const Divider(height: 32),
              _StatRow(label: 'Total Sales', value: currencyFormat.format(data['sales']), color: Colors.blue),
              const SizedBox(height: 16),
              _StatRow(label: 'Total Orders', value: '${data['count']?.toInt() ?? 0}', color: Colors.grey),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _StatRow(label: 'Gross Profit', value: currencyFormat.format(data['profit']), color: Colors.green, isBold: true),
            ],
          ),
        ),
      ),
    ],
  );
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _StatRow({required this.label, required this.value, required this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProfitLossTab extends ConsumerStatefulWidget {
  const _ProfitLossTab();

  @override
  ConsumerState<_ProfitLossTab> createState() => _ProfitLossTabState();
}

class _ProfitLossTabState extends ConsumerState<_ProfitLossTab> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final accountingService = ref.watch(accountingServiceProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text('${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}'),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() => _dateRange = picked);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: accountingService.getProfitAndLoss(_dateRange.start, _dateRange.end),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Income', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _PLRow(label: 'Sales Revenue', value: data['revenue'], isPositive: true),
                          const Divider(height: 32),
                          Text('Cost of Goods Sold', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _PLRow(label: 'COGS', value: -data['cogs'], isPositive: false),
                          const Divider(height: 32),
                          _PLRow(label: 'Gross Profit', value: data['grossProfit'], isTotal: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Operating Expenses', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _PLRow(label: 'Total Expenses', value: -data['expenses'], isPositive: false),
                          const Divider(height: 32),
                          _PLRow(label: 'Net Profit / (Loss)', value: data['netProfit'], isTotal: true, isFinal: true),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PLRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isPositive;
  final bool isTotal;
  final bool isFinal;

  const _PLRow({
    required this.label,
    required this.value,
    this.isPositive = true,
    this.isTotal = false,
    this.isFinal = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isFinal
                ? (value >= 0 ? Colors.green : Colors.red)
                : (isTotal ? Colors.black : (isPositive ? Colors.black : Colors.red)),
          ),
        ),
      ],
    );
  }
}
