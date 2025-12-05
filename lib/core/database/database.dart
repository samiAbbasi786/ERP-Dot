import 'package:drift/drift.dart';
import 'connection/connection.dart' as impl;

part 'database.g.dart';

// ==================== TABLES ====================

// Users Table
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get password => text()();
  TextColumn get role => text()(); // admin, manager, cashier
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Products Table
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get sku => text().nullable().unique()();
  TextColumn get description => text().nullable()();
  TextColumn get imagePath => text().nullable()(); // New
  TextColumn get brand => text().nullable()(); // New
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get salePrice => real().withDefault(const Constant(0.0))();
  RealColumn get stockQty => real().withDefault(const Constant(0.0))();
  RealColumn get minStockLevel => real().withDefault(const Constant(0.0))(); // New
  TextColumn get unit => text().withDefault(const Constant('pcs'))(); // pcs, kg, ltr
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Categories Table
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Partners Table (Customers & Vendors)
class Partners extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get type => text()(); // customer, vendor, both
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Sales Orders Table
class SalesOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderNumber => text().unique()();
  IntColumn get customerId => integer().nullable().references(Partners, #id)();
  TextColumn get status => text()(); // draft, confirmed, done, cancelled
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()(); // New
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Sales Order Lines Table
class SalesOrderLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(SalesOrders, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Purchase Orders Table
class PurchaseOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderNumber => text().unique()();
  IntColumn get vendorId => integer().nullable().references(Partners, #id)();
  TextColumn get status => text()(); // draft, confirmed, received, cancelled
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Purchase Order Lines Table
class PurchaseOrderLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(PurchaseOrders, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Stock Moves Table
class StockMoves extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get moveType => text()(); // in, out, adjustment
  TextColumn get reference => text().nullable()(); // SO-001, PO-001
  RealColumn get quantity => real()();
  RealColumn get unitCost => real().nullable()();
  DateTimeColumn get moveDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Accounts Table (Chart of Accounts)
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get type => text()(); // asset, liability, equity, income, expense
  IntColumn get parentId => integer().nullable().references(Accounts, #id)();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Journal Entries Table
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryNumber => text().unique()();
  TextColumn get reference => text().nullable()(); // SO-001, PO-001, INV-001
  DateTimeColumn get entryDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get description => text().nullable()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Journal Entry Lines Table
class JournalEntryLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer().references(JournalEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  RealColumn get debit => real().withDefault(const Constant(0.0))();
  RealColumn get credit => real().withDefault(const Constant(0.0))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Payments Table
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get paymentNumber => text().unique()();
  IntColumn get partnerId => integer().nullable().references(Partners, #id)();
  TextColumn get paymentType => text()(); // receive, pay
  TextColumn get reference => text().nullable()(); // SO-001, PO-001
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text()(); // cash, bank, card
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Expenses Table
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get expenseNumber => text().unique()();
  TextColumn get category => text()(); // rent, utilities, salary, etc.
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get expenseDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ==================== DATABASE ====================

@DriftDatabase(tables: [
  Users,
  Products,
  Categories,
  Partners,
  SalesOrders,
  SalesOrderLines,
  PurchaseOrders,
  PurchaseOrderLines,
  StockMoves,
  Accounts,
  JournalEntries,
  JournalEntryLines,
  Payments,
  Expenses,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          
          // Insert default admin user
          await into(users).insert(UsersCompanion.insert(
            username: 'admin',
            password: 'admin123', // In production, hash this!
            role: 'admin',
          ));

          // Insert sales person for testing
          await into(users).insert(UsersCompanion.insert(
            username: 'sales',
            password: 'sales123',
            role: 'sales',
          ));

          // Insert manager for testing
          await into(users).insert(UsersCompanion.insert(
            username: 'manager',
            password: 'manager123',
            role: 'manager',
          ));

          // Insert default accounts
          await _createDefaultAccounts();
          
          // Insert dummy categories and products for testing
          await _createDummyData();
        },
      );

  Future<void> _createDefaultAccounts() async {
    final defaultAccounts = [
      // Assets
      AccountsCompanion.insert(code: '1000', name: 'Cash', type: 'asset'),
      AccountsCompanion.insert(code: '1100', name: 'Bank', type: 'asset'),
      AccountsCompanion.insert(code: '1200', name: 'Accounts Receivable', type: 'asset'),
      AccountsCompanion.insert(code: '1300', name: 'Inventory', type: 'asset'),
      
      // Liabilities
      AccountsCompanion.insert(code: '2000', name: 'Accounts Payable', type: 'liability'),
      AccountsCompanion.insert(code: '2100', name: 'Tax Payable', type: 'liability'),
      
      // Equity
      AccountsCompanion.insert(code: '3000', name: 'Owner\'s Equity', type: 'equity'),
      AccountsCompanion.insert(code: '3100', name: 'Retained Earnings', type: 'equity'),
      
      // Income
      AccountsCompanion.insert(code: '4000', name: 'Sales Revenue', type: 'income'),
      AccountsCompanion.insert(code: '4100', name: 'Service Revenue', type: 'income'),
      
      // Expenses
      AccountsCompanion.insert(code: '5000', name: 'Cost of Goods Sold', type: 'expense'),
      AccountsCompanion.insert(code: '5100', name: 'Operating Expenses', type: 'expense'),
      AccountsCompanion.insert(code: '5200', name: 'Rent Expense', type: 'expense'),
      AccountsCompanion.insert(code: '5300', name: 'Utilities Expense', type: 'expense'),
      AccountsCompanion.insert(code: '5400', name: 'Salary Expense', type: 'expense'),
    ];

    for (final account in defaultAccounts) {
      await into(accounts).insert(account);
    }
  }

  Future<void> _createDummyData() async {
    // Create categories
    final categoryIds = <String, int>{};
    
    final categories = [
      CategoriesCompanion.insert(name: 'Electronics', description: const Value('Electronic devices and accessories')),
      CategoriesCompanion.insert(name: 'Food & Beverages', description: const Value('Food and drink items')),
      CategoriesCompanion.insert(name: 'Clothing', description: const Value('Apparel and fashion items')),
      CategoriesCompanion.insert(name: 'Office Supplies', description: const Value('Office and stationery items')),
      CategoriesCompanion.insert(name: 'Home & Garden', description: const Value('Home improvement and garden supplies')),
    ];

    for (final category in categories) {
      final id = await into(this.categories).insert(category);
      categoryIds[category.name.value] = id;
    }

    // Create dummy products
    final products = [
      // Electronics
      ProductsCompanion.insert(
        name: 'Wireless Mouse',
        barcode: const Value('1234567890123'),
        sku: const Value('WM-001'),
        brand: const Value('Logitech'),
        description: const Value('Ergonomic wireless mouse with USB receiver'),
        categoryId: Value(categoryIds['Electronics']),
        costPrice: const Value(15.00),
        salePrice: const Value(29.99),
        stockQty: const Value(45),
        minStockLevel: const Value(10),
        unit: const Value('pcs'),
      ),
      ProductsCompanion.insert(
        name: 'USB-C Cable',
        barcode: const Value('1234567890124'),
        sku: const Value('CB-002'),
        brand: const Value('Anker'),
        description: const Value('6ft USB-C charging cable'),
        categoryId: Value(categoryIds['Electronics']),
        costPrice: const Value(5.00),
        salePrice: const Value(12.99),
        stockQty: const Value(120),
        minStockLevel: const Value(20),
        unit: const Value('pcs'),
      ),
      ProductsCompanion.insert(
        name: 'Bluetooth Headphones',
        barcode: const Value('1234567890125'),
        sku: const Value('HP-003'),
        brand: const Value('Sony'),
        description: const Value('Noise-cancelling over-ear headphones'),
        categoryId: Value(categoryIds['Electronics']),
        costPrice: const Value(80.00),
        salePrice: const Value(149.99),
        stockQty: const Value(8),
        minStockLevel: const Value(5),
        unit: const Value('pcs'),
      ),
      
      // Food & Beverages
      ProductsCompanion.insert(
        name: 'Organic Coffee Beans',
        barcode: const Value('2234567890123'),
        sku: const Value('CF-001'),
        brand: const Value('Starbucks'),
        description: const Value('Premium arabica coffee beans 1kg'),
        categoryId: Value(categoryIds['Food & Beverages']),
        costPrice: const Value(12.00),
        salePrice: const Value(24.99),
        stockQty: const Value(30),
        minStockLevel: const Value(10),
        unit: const Value('kg'),
      ),
      ProductsCompanion.insert(
        name: 'Green Tea Box',
        barcode: const Value('2234567890124'),
        sku: const Value('GT-002'),
        brand: const Value('Lipton'),
        description: const Value('Premium green tea 100 bags'),
        categoryId: Value(categoryIds['Food & Beverages']),
        costPrice: const Value(4.00),
        salePrice: const Value(8.99),
        stockQty: const Value(50),
        minStockLevel: const Value(15),
        unit: const Value('box'),
      ),
      ProductsCompanion.insert(
        name: 'Mineral Water',
        barcode: const Value('2234567890125'),
        sku: const Value('MW-003'),
        brand: const Value('Evian'),
        description: const Value('Natural mineral water 1.5L'),
        categoryId: Value(categoryIds['Food & Beverages']),
        costPrice: const Value(0.50),
        salePrice: const Value(1.49),
        stockQty: const Value(200),
        minStockLevel: const Value(50),
        unit: const Value('bottle'),
      ),
      
      // Clothing
      ProductsCompanion.insert(
        name: 'Cotton T-Shirt',
        barcode: Value('3234567890123'),
        sku: Value('TS-001'),
        brand: Value('Nike'),
        description: Value('100% cotton crew neck t-shirt'),
        categoryId: Value(categoryIds['Clothing']),
        costPrice: Value(10.00),
        salePrice: Value(24.99),
        stockQty: Value(60),
        minStockLevel: Value(20),
        unit: Value('pcs'),
      ),
      ProductsCompanion.insert(
        name: 'Denim Jeans',
        barcode: Value('3234567890124'),
        sku: Value('DJ-002'),
        brand: Value('Levi\'s'),
        description: Value('Classic fit denim jeans'),
        categoryId: Value(categoryIds['Clothing']),
        costPrice: Value(30.00),
        salePrice: Value(69.99),
        stockQty: Value(25),
        minStockLevel: Value(10),
        unit: Value('pcs'),
      ),
      
      // Office Supplies
      ProductsCompanion.insert(
        name: 'A4 Paper Ream',
        barcode: Value('4234567890123'),
        sku: Value('PP-001'),
        brand: Value('HP'),
        description: Value('500 sheets A4 copy paper'),
        categoryId: Value(categoryIds['Office Supplies']),
        costPrice: Value(3.50),
        salePrice: Value(7.99),
        stockQty: Value(100),
        minStockLevel: Value(25),
        unit: Value('ream'),
      ),
      ProductsCompanion.insert(
        name: 'Ballpoint Pens',
        barcode: Value('4234567890124'),
        sku: Value('BP-002'),
        brand: Value('BIC'),
        description: Value('Blue ballpoint pens pack of 10'),
        categoryId: Value(categoryIds['Office Supplies']),
        costPrice: Value(2.00),
        salePrice: Value(4.99),
        stockQty: Value(3),
        minStockLevel: Value(10),
        unit: Value('pack'),
      ),
      
      // Home & Garden
      ProductsCompanion.insert(
        name: 'LED Light Bulb',
        barcode: Value('5234567890123'),
        sku: Value('LB-001'),
        brand: Value('Philips'),
        description: Value('9W LED bulb warm white'),
        categoryId: Value(categoryIds['Home & Garden']),
        costPrice: Value(3.00),
        salePrice: Value(7.99),
        stockQty: Value(75),
        minStockLevel: Value(20),
        unit: Value('pcs'),
      ),
      ProductsCompanion.insert(
        name: 'Garden Hose',
        barcode: Value('5234567890124'),
        sku: Value('GH-002'),
        brand: Value('Gardena'),
        description: Value('50ft expandable garden hose'),
        categoryId: Value(categoryIds['Home & Garden']),
        costPrice: Value(20.00),
        salePrice: Value(44.99),
        stockQty: Value(15),
        minStockLevel: Value(5),
        unit: Value('pcs'),
      ),
      ProductsCompanion.insert(
        name: 'Plant Fertilizer',
        barcode: Value('5234567890125'),
        sku: Value('PF-003'),
        brand: Value('Miracle-Gro'),
        description: Value('All-purpose plant food 1kg'),
        categoryId: Value(categoryIds['Home & Garden']),
        costPrice: Value(6.00),
        salePrice: Value(14.99),
        stockQty: Value(40),
        minStockLevel: Value(10),
        unit: Value('kg'),
      ),
    ];

    for (final product in products) {
      await into(this.products).insert(product);
    }
  }
}
