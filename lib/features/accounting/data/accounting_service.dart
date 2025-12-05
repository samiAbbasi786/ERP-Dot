import 'package:drift/drift.dart';
import '../../../core/database/database.dart';

class AccountingService {
  final AppDatabase db;

  AccountingService(this.db);

  // ==================== JOURNAL ENTRIES ====================

  /// Creates a journal entry for a sales order
  Future<void> createSaleJournalEntry({
    required SalesOrder order,
    required List<SalesOrderLine> lines,
    required String paymentMethod, // 'cash', 'card', 'online'
  }) async {
    // 1. Get Accounts
    final accounts = await db.select(db.accounts).get();
    
    // Helper to find account by code
    Account? getAccount(String code) {
      try {
        return accounts.firstWhere((a) => a.code == code);
      } catch (_) {
        return null;
      }
    }

    final salesRevenueAccount = getAccount('4000'); // Sales Revenue
    final cogsAccount = getAccount('5000'); // Cost of Goods Sold
    final inventoryAccount = getAccount('1300'); // Inventory Asset
    
    // Determine Debit Account based on payment method
    Account? debitAccount;
    if (paymentMethod == 'cash') {
      debitAccount = getAccount('1000'); // Cash
    } else if (paymentMethod == 'card' || paymentMethod == 'online') {
      debitAccount = getAccount('1100'); // Bank
    }

    if (salesRevenueAccount == null || debitAccount == null) {
      throw Exception('Critical accounts missing (Sales Revenue or Debit Account)');
    }

    // 2. Create Journal Entry Header
    final entryNumber = 'JE-${order.orderNumber}';
    final entryId = await db.into(db.journalEntries).insert(
      JournalEntriesCompanion.insert(
        entryNumber: entryNumber,
        reference: Value(order.orderNumber),
        description: Value('Sale - ${order.orderNumber}'),
        userId: Value(order.userId),
        entryDate: Value(order.orderDate),
      ),
    );

    // 3. Create Journal Entry Lines (Double Entry)

    // A. Revenue Recognition
    // Debit: Cash/Bank (Asset Increase)
    await db.into(db.journalEntryLines).insert(
      JournalEntryLinesCompanion.insert(
        entryId: entryId,
        accountId: debitAccount.id,
        debit: Value(order.total),
        credit: const Value(0.0),
        description: Value('Payment for ${order.orderNumber}'),
      ),
    );

    // Credit: Sales Revenue (Income Increase)
    await db.into(db.journalEntryLines).insert(
      JournalEntryLinesCompanion.insert(
        entryId: entryId,
        accountId: salesRevenueAccount.id,
        debit: const Value(0.0),
        credit: Value(order.subtotal), // Exclude tax for revenue, tax is separate liability
        description: Value('Revenue from ${order.orderNumber}'),
      ),
    );
    
    // Credit: Tax Payable (Liability Increase)
    if (order.taxAmount > 0) {
      final taxAccount = getAccount('2100'); // Tax Payable
      if (taxAccount != null) {
        await db.into(db.journalEntryLines).insert(
          JournalEntryLinesCompanion.insert(
            entryId: entryId,
            accountId: taxAccount.id,
            debit: const Value(0.0),
            credit: Value(order.taxAmount),
            description: Value('Tax collected on ${order.orderNumber}'),
          ),
        );
      }
    }

    // B. Cost of Goods Sold (Perpetual Inventory System)
    // We need to calculate total cost from lines. 
    // Note: In a real system, we'd track cost per batch (FIFO/LIFO). 
    // Here we use current product cost.
    double totalCost = 0;
    for (final line in lines) {
      final product = await (db.select(db.products)..where((p) => p.id.equals(line.productId))).getSingle();
      totalCost += product.costPrice * line.quantity;
    }

    if (cogsAccount != null && inventoryAccount != null && totalCost > 0) {
      // Debit: COGS (Expense Increase)
      await db.into(db.journalEntryLines).insert(
        JournalEntryLinesCompanion.insert(
          entryId: entryId,
          accountId: cogsAccount.id,
          debit: Value(totalCost),
          credit: const Value(0.0),
          description: Value('Cost of goods for ${order.orderNumber}'),
        ),
      );

      // Credit: Inventory (Asset Decrease)
      await db.into(db.journalEntryLines).insert(
        JournalEntryLinesCompanion.insert(
          entryId: entryId,
          accountId: inventoryAccount.id,
          debit: const Value(0.0),
          credit: Value(totalCost),
          description: Value('Inventory reduction for ${order.orderNumber}'),
        ),
      );
    }

    // 4. Update Account Balances
    // Update Debit Account (Cash/Bank)
    await (db.update(db.accounts)..where((a) => a.id.equals(debitAccount!.id))).write(
      AccountsCompanion(balance: Value(debitAccount.balance + order.total)),
    );

    // Update Sales Revenue
    await (db.update(db.accounts)..where((a) => a.id.equals(salesRevenueAccount.id))).write(
      AccountsCompanion(balance: Value(salesRevenueAccount.balance + order.subtotal)),
    );
    
    // Update Tax Payable
    if (order.taxAmount > 0) {
      final taxAccount = getAccount('2100');
      if (taxAccount != null) {
        await (db.update(db.accounts)..where((a) => a.id.equals(taxAccount.id))).write(
          AccountsCompanion(balance: Value(taxAccount.balance + order.taxAmount)),
        );
      }
    }
  }

  // ==================== REPORTS ====================

  Future<Map<String, double>> getDailyStats(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final orders = await (db.select(db.salesOrders)
      ..where((o) => o.orderDate.isBetweenValues(startOfDay, endOfDay))
      ..where((o) => o.status.equals('done')))
      .get();

    double totalSales = 0;
    double totalProfit = 0;

    for (final order in orders) {
      totalSales += order.total;
      
      // Calculate profit (Sales - Cost)
      // Get lines
      final lines = await (db.select(db.salesOrderLines)..where((l) => l.orderId.equals(order.id))).get();
      double orderCost = 0;
      for (final line in lines) {
        final product = await (db.select(db.products)..where((p) => p.id.equals(line.productId))).getSingle();
        orderCost += product.costPrice * line.quantity;
      }
      totalProfit += (order.subtotal - orderCost); // Profit excludes tax
    }

    return {
      'sales': totalSales,
      'profit': totalProfit,
      'count': orders.length.toDouble(),
    };
  }

  Future<Map<String, double>> getWeeklyStats(DateTime date) async {
    // Start of week (Monday)
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));

    return _getStatsForRange(start, end);
  }

  Future<Map<String, double>> getMonthlyStats(DateTime date) async {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1);

    return _getStatsForRange(start, end);
  }

  Future<Map<String, double>> getYearlyStats(int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    return _getStatsForRange(start, end);
  }

  Future<Map<String, double>> _getStatsForRange(DateTime start, DateTime end) async {
    final orders = await (db.select(db.salesOrders)
      ..where((o) => o.orderDate.isBetween(Variable(start), Variable(end)))
      ..where((o) => o.status.equals('done')))
      .get();

    double totalSales = 0;
    double totalProfit = 0;

    for (final order in orders) {
      totalSales += order.total;
      
      // Calculate profit (Sales - Cost)
      final lines = await (db.select(db.salesOrderLines)..where((l) => l.orderId.equals(order.id))).get();
      double orderCost = 0;
      for (final line in lines) {
        final product = await (db.select(db.products)..where((p) => p.id.equals(line.productId))).getSingle();
        orderCost += product.costPrice * line.quantity;
      }
      totalProfit += (order.subtotal - orderCost);
    }

    return {
      'sales': totalSales,
      'profit': totalProfit,
      'count': orders.length.toDouble(),
    };
  }

  Future<Map<String, dynamic>> getProfitAndLoss(DateTime start, DateTime end) async {
    // 1. Revenue
    final salesOrders = await (db.select(db.salesOrders)
      ..where((o) => o.orderDate.isBetween(Variable(start), Variable(end)))
      ..where((o) => o.status.equals('done')))
      .get();
      
    double totalRevenue = salesOrders.fold(0, (sum, o) => sum + o.subtotal); // Revenue is subtotal (excl tax)

    // 2. COGS
    double totalCOGS = 0;
    for (final order in salesOrders) {
      final lines = await (db.select(db.salesOrderLines)..where((l) => l.orderId.equals(order.id))).get();
      for (final line in lines) {
        final product = await (db.select(db.products)..where((p) => p.id.equals(line.productId))).getSingle();
        totalCOGS += product.costPrice * line.quantity;
      }
    }

    // 3. Expenses
    final expenses = await (db.select(db.expenses)
      ..where((e) => e.expenseDate.isBetween(Variable(start), Variable(end))))
      .get();
      
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);

    // 4. Net Profit
    double grossProfit = totalRevenue - totalCOGS;
    double netProfit = grossProfit - totalExpenses;

    return {
      'revenue': totalRevenue,
      'cogs': totalCOGS,
      'grossProfit': grossProfit,
      'expenses': totalExpenses,
      'netProfit': netProfit,
    };
  }
}
