import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../../features/accounting/data/accounting_service.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Theme Mode Provider
final themeModeProvider = StateProvider<bool>((ref) => false); // false = light, true = dark

// Current User Provider
final currentUserProvider = StateProvider<User?>((ref) => null);

// Accounting Service Provider
final accountingServiceProvider = Provider<AccountingService>((ref) {
  return AccountingService(ref.watch(databaseProvider));
});

// --- Accounting / Dashboard Aggregates ---

// Total Sales (all time) - sums SalesOrders.total
final totalSalesProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final stream = db.select(db.salesOrders).watch();
  return stream.map((orders) => orders.fold<double>(0.0, (s, o) => s + (o.total ?? 0.0)));
});

// Total Purchases (all time) - sums PurchaseOrders.total
final totalPurchasesProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final stream = db.select(db.purchaseOrders).watch();
  return stream.map((orders) => orders.fold<double>(0.0, (s, o) => s + (o.total ?? 0.0)));
});

// Inventory Value = sum(product.stockQty * product.costPrice)
final inventoryValueProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final stream = db.select(db.products).watch();
  return stream.map((products) => products.fold<double>(0.0, (sum, p) => sum + (p.stockQty * p.costPrice)));
});

// Net Profit (simple): total sales - total expenses
final netProfitProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final salesStream = db.select(db.salesOrders).watch();
  final expensesStream = db.select(db.expenses).watch();

  // Combine streams by mapping sales + expenses into a single stream via watch().map()
  return salesStream.asyncMap((sales) async {
    final expenses = await expensesStream.first;
    final totalSales = sales.fold<double>(0.0, (s, o) => s + (o.total ?? 0.0));
    final totalExpenses = expenses.fold<double>(0.0, (s, e) => s + (e.amount ?? 0.0));
    return totalSales - totalExpenses;
  });
});

// Receivables: sum of partner balances for customers/both where balance > 0
final receivablesProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.partners).watch().map((parts) {
    return parts
        .where((p) => p.type == 'customer' || p.type == 'both')
        .fold<double>(0.0, (s, p) => s + (p.balance > 0 ? p.balance : 0.0));
  });
});

// Payables: sum of partner balances for vendors/both where balance < 0 (absolute)
final payablesProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.partners).watch().map((parts) {
    return parts
        .where((p) => p.type == 'vendor' || p.type == 'both')
        .fold<double>(0.0, (s, p) => s + (p.balance < 0 ? -p.balance : 0.0));
  });
});

// Cash / Bank balance from Accounts table (codes 1000 and 1100)
final cashBalanceProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.accounts).watch().map((accounts) {
    final cash = accounts.where((a) => a.code == '1000' || a.code == '1100');
    return cash.fold<double>(0.0, (s, a) => s + a.balance);
  });
});

// --- Date Range helpers and range-based aggregates ---
class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);
}

// Selected range provider (default: today)
final selectedRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return DateRange(start, end);
});

bool _inRange(DateTime dt, DateTime start, DateTime end) {
  return (dt.isAtSameMomentAs(start) || dt.isAfter(start)) &&
      (dt.isAtSameMomentAs(end) || dt.isBefore(end));
}

// Sales total for a given date range
final salesTotalForRangeProvider = StreamProvider.family<double, DateRange>((ref, range) {
  final db = ref.watch(databaseProvider);
  final stream = db.select(db.salesOrders).watch();
  return stream.map((orders) {
    final filtered = orders.where((o) => _inRange(o.orderDate, range.start, range.end));
    return filtered.fold<double>(0.0, (s, o) => s + (o.total ?? 0.0));
  });
});

// Purchases total for a given date range
final purchasesTotalForRangeProvider = StreamProvider.family<double, DateRange>((ref, range) {
  final db = ref.watch(databaseProvider);
  final stream = db.select(db.purchaseOrders).watch();
  return stream.map((orders) {
    final filtered = orders.where((o) => _inRange(o.orderDate, range.start, range.end));
    return filtered.fold<double>(0.0, (s, o) => s + (o.total ?? 0.0));
  });
});

// Expenses total for a given date range
final expensesTotalForRangeProvider = StreamProvider.family<double, DateRange>((ref, range) {
  final db = ref.watch(databaseProvider);
  final stream = db.select(db.expenses).watch();
  return stream.map((expenses) {
    final filtered = expenses.where((e) => _inRange(e.expenseDate, range.start, range.end));
    return filtered.fold<double>(0.0, (s, e) => s + (e.amount ?? 0.0));
  });
});

// Net profit for a date range: sales - COGS - expenses
final netProfitForRangeProvider = StreamProvider.family<double, DateRange>((ref, range) {
  final db = ref.watch(databaseProvider);
  final salesStream = db.select(db.salesOrders).watch();

  return salesStream.asyncMap((sales) async {
    final filteredSales = sales.where((s) => _inRange(s.orderDate, range.start, range.end)).toList();
    final orderIds = filteredSales.map((s) => s.id).toList();

    double totalSales = filteredSales.fold<double>(0.0, (sum, s) => sum + (s.total ?? 0.0));

    double cogs = 0.0;
    if (orderIds.isNotEmpty) {
      final lines = await (db.select(db.salesOrderLines)..where((l) => l.orderId.isIn(orderIds))).get();
      for (final line in lines) {
        final product = await (db.select(db.products)..where((p) => p.id.equals(line.productId))).getSingle();
        cogs += product.costPrice * line.quantity;
      }
    }

    final expenses = await (db.select(db.expenses).get());
    final filteredExpenses = expenses.where((e) => _inRange(e.expenseDate, range.start, range.end)).toList();
    final totalExpenses = filteredExpenses.fold<double>(0.0, (s, e) => s + (e.amount ?? 0.0));

    return totalSales - cogs - totalExpenses;
  });
});

// Payments grouped by method for a range
final paymentsByMethodForRangeProvider = StreamProvider.family<Map<String, double>, DateRange>((ref, range) {
  final db = ref.watch(databaseProvider);
  final stream = db.select(db.payments).watch();
  return stream.map((payments) {
    final filtered = payments.where((p) => _inRange(p.paymentDate, range.start, range.end));
    final Map<String, double> map = {};
    for (final p in filtered) {
      map[p.paymentMethod] = (map[p.paymentMethod] ?? 0.0) + p.amount;
    }
    return map;
  });
});

// Cash opening balance for a date range (balance at range.start)
final cashOpeningForRangeProvider = StreamProvider.family<double, DateRange>((ref, range) async* {
  final db = ref.watch(databaseProvider);
  final accounts = await db.select(db.accounts).get();

  double balanceNow = 0.0;
  try {
    final cashAccount = accounts.firstWhere((a) => a.code == '1000');
    balanceNow = cashAccount.balance;
  } catch (_) {
    balanceNow = 0.0;
  }

  final payments = await db.select(db.payments).get();
  // delta after start = sum(receives - pays) where paymentDate >= range.start
  final deltaAfterStart = payments
      .where((p) => p.paymentDate.isAfter(range.start) || p.paymentDate.isAtSameMomentAs(range.start))
      .fold<double>(0.0, (s, p) => s + (p.paymentType == 'receive' ? p.amount : -p.amount));

  // opening = now - deltaAfterStart
  yield balanceNow - deltaAfterStart;
});

// Cash closing balance for a date range (balance at range.end)
final cashClosingForRangeProvider = StreamProvider.family<double, DateRange>((ref, range) async* {
  final db = ref.watch(databaseProvider);
  final accounts = await db.select(db.accounts).get();

  double balanceNow = 0.0;
  try {
    final cashAccount = accounts.firstWhere((a) => a.code == '1000');
    balanceNow = cashAccount.balance;
  } catch (_) {
    balanceNow = 0.0;
  }

  final payments = await db.select(db.payments).get();
  final deltaAfterEnd = payments
      .where((p) => p.paymentDate.isAfter(range.end) || p.paymentDate.isAtSameMomentAs(range.end))
      .fold<double>(0.0, (s, p) => s + (p.paymentType == 'receive' ? p.amount : -p.amount));

  // closing = now - deltaAfterEnd
  yield balanceNow - deltaAfterEnd;
});
