import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/app_providers.dart';

// Accounts Provider
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.accounts).watch();
});

// Journal Entries Provider
final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.journalEntries).watch();
});

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accounting'),
          bottom: TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            tabs: const [
              Tab(text: 'Chart of Accounts'),
              Tab(text: 'Journal Entries'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedTab,
          children: const [
            _ChartOfAccountsTab(),
            _JournalEntriesTab(),
            _ReportsTab(),
          ],
        ),
      ),
    );
  }
}

class _ChartOfAccountsTab extends ConsumerWidget {
  const _ChartOfAccountsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        final grouped = <String, List<Account>>{};
        for (final account in accounts) {
          grouped.putIfAbsent(account.type, () => []).add(account);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: grouped.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Code')),
                        DataColumn(label: Text('Account Name')),
                        DataColumn(label: Text('Balance')),
                      ],
                      rows: entry.value.map((account) {
                        return DataRow(cells: [
                          DataCell(Text(account.code)),
                          DataCell(Text(account.name)),
                          DataCell(
                            Text(
                              '\$${account.balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: account.balance >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _JournalEntriesTab extends ConsumerWidget {
  const _JournalEntriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('No journal entries yet'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Entry #')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Reference')),
                DataColumn(label: Text('Description')),
              ],
              rows: entries.map((entry) {
                return DataRow(cells: [
                  DataCell(Text(entry.entryNumber)),
                  DataCell(Text(entry.entryDate.toString().substring(0, 10))),
                  DataCell(Text(entry.reference ?? '-')),
                  DataCell(Text(entry.description ?? '-')),
                ]);
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        final assets = accounts.where((a) => a.type == 'asset').toList();
        final liabilities = accounts.where((a) => a.type == 'liability').toList();
        final equity = accounts.where((a) => a.type == 'equity').toList();
        final income = accounts.where((a) => a.type == 'income').toList();
        final expenses = accounts.where((a) => a.type == 'expense').toList();

        final totalAssets = assets.fold<double>(0, (sum, a) => sum + a.balance);
        final totalLiabilities = liabilities.fold<double>(0, (sum, a) => sum + a.balance);
        final totalEquity = equity.fold<double>(0, (sum, a) => sum + a.balance);
        final totalIncome = income.fold<double>(0, (sum, a) => sum + a.balance);
        final totalExpenses = expenses.fold<double>(0, (sum, a) => sum + a.balance);
        final netProfit = totalIncome - totalExpenses;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Balance Sheet
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance Sheet',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      _buildReportSection('Assets', totalAssets),
                      _buildReportSection('Liabilities', totalLiabilities),
                      _buildReportSection('Equity', totalEquity),
                      const Divider(),
                      _buildReportSection('Total', totalAssets, isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Profit & Loss
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profit & Loss Statement',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      _buildReportSection('Income', totalIncome),
                      _buildReportSection('Expenses', totalExpenses),
                      const Divider(),
                      _buildReportSection(
                        'Net Profit',
                        netProfit,
                        isBold: true,
                        color: netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildReportSection(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
