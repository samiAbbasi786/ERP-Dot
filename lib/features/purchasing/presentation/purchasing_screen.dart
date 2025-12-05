import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/providers/app_providers.dart';
import '../../partners/presentation/partners_screen.dart';

// Purchase Orders Provider
final purchaseOrdersProvider = StreamProvider<List<PurchaseOrder>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.purchaseOrders).watch();
});

// Vendors Provider (Partners who are vendors)
final vendorsProvider = StreamProvider<List<Partner>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.partners)
        ..where((p) => p.type.equals('vendor') | p.type.equals('both')))
      .watch();
});

// Products Provider for purchase dialog
final productsForPurchaseProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.products).watch();
});

class PurchasingScreen extends ConsumerWidget {
  const PurchasingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchaseOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const PurchaseOrderDialog(),
              );
            },
          ),
        ],
      ),
      body: purchasesAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No purchase orders yet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const PurchaseOrderDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Purchase Order'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Order #')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Vendor')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Paid')),
                  DataColumn(label: Text('Balance')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: orders.map((order) {
                  final balance = order.total - order.paidAmount;
                  return DataRow(cells: [
                    DataCell(Text(order.orderNumber)),
                    DataCell(Text(DateFormat('yyyy-MM-dd').format(order.orderDate))),
                    DataCell(Text(order.vendorId?.toString() ?? '-')),
                    DataCell(
                      Chip(
                        label: Text(order.status.toUpperCase()),
                        backgroundColor: _getStatusColor(order.status),
                      ),
                    ),
                    DataCell(Text('\$${order.total.toStringAsFixed(2)}')),
                    DataCell(Text('\$${order.paidAmount.toStringAsFixed(2)}')),
                    DataCell(
                      Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: balance > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => PurchaseOrderDialog(order: order),
                          );
                        },
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'confirmed':
        return Colors.blue;
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class PurchaseOrderDialog extends ConsumerStatefulWidget {
  final PurchaseOrder? order;

  const PurchaseOrderDialog({super.key, this.order});

  @override
  ConsumerState<PurchaseOrderDialog> createState() => _PurchaseOrderDialogState();
}

class _PurchaseOrderDialogState extends ConsumerState<PurchaseOrderDialog> {
  int? selectedVendorId;
  String selectedStatus = 'draft';
  DateTime orderDate = DateTime.now();
  double paidAmount = 0.0;
  final List<PurchaseOrderLineItem> lineItems = [];
  final paidController = TextEditingController(text: '0');

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      selectedVendorId = widget.order!.vendorId;
      selectedStatus = widget.order!.status;
      orderDate = widget.order!.orderDate;
      paidAmount = widget.order!.paidAmount;
      paidController.text = paidAmount.toStringAsFixed(2);
      // Load existing line items
      _loadExistingLineItems();
    }
  }

  Future<void> _loadExistingLineItems() async {
    if (widget.order == null) return;
    final db = ref.read(databaseProvider);
    final lines = await (db.select(db.purchaseOrderLines)
          ..where((l) => l.orderId.equals(widget.order!.id)))
        .get();

    for (final line in lines) {
      final product = await (db.select(db.products)
            ..where((p) => p.id.equals(line.productId)))
          .getSingle();
      setState(() {
        lineItems.add(PurchaseOrderLineItem(
          product: product,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          tax: line.tax,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsProvider);
    final productsAsync = ref.watch(productsForPurchaseProvider);

    return Dialog(
      child: Container(
        width: 1000,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.order == null ? 'Create Purchase Order' : 'Edit Purchase Order',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                child: vendorsAsync.when(
                  data: (vendors) {
                    if (vendors.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No vendors available. Please add a vendor first.'),
                        ),
                      );
                    }

                    final selectedVendor = selectedVendorId != null
                        ? vendors.firstWhere((v) => v.id == selectedVendorId, orElse: () => vendors.first)
                        : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vendor selection and order meta
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<int>(
                                value: selectedVendorId,
                                decoration: const InputDecoration(
                                  labelText: 'Vendor *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.business),
                                ),
                                items: vendors
                                    .map((vendor) => DropdownMenuItem<int>(value: vendor.id, child: Text(vendor.name)))
                                    .toList(),
                                onChanged: (value) => setState(() => selectedVendorId = value),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: orderDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) setState(() => orderDate = date);
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Order Date',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(DateFormat('yyyy-MM-dd').format(orderDate)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                                  DropdownMenuItem(value: 'received', child: Text('Received')),
                                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                                ],
                                onChanged: (value) {
                                  if (value != null) setState(() => selectedStatus = value);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Vendor details
                        if (selectedVendor != null)
                          Card(
                            color: Colors.blue.withOpacity(0.05),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info, color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Vendor Details',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue.shade700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow('Name', selectedVendor.name),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Email', selectedVendor.email ?? 'N/A'),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Address', selectedVendor.address ?? 'N/A'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow('Phone', selectedVendor.phone ?? 'N/A'),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Type', selectedVendor.type),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Status', selectedVendor.isActive ? 'Active' : 'Inactive'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Line items header + add button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Products', style: Theme.of(context).textTheme.titleMedium),
                            ElevatedButton.icon(
                              onPressed: () => _showAddProductDialog(productsAsync),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Product'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Line items table
                        SizedBox(
                          height: 300,
                          child: lineItems.isEmpty
                              ? const Center(child: Text('No products added yet'))
                              : SingleChildScrollView(
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Product')),
                                      DataColumn(label: Text('Quantity')),
                                      DataColumn(label: Text('Unit Price')),
                                      DataColumn(label: Text('Tax')),
                                      DataColumn(label: Text('Subtotal')),
                                      DataColumn(label: Text('')),
                                    ],
                                    rows: lineItems.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final line = entry.value;
                                      return DataRow(cells: [
                                        DataCell(Text(line.product.name)),
                                        DataCell(Text('${line.quantity.toStringAsFixed(2)} ${line.product.unit}')),
                                        DataCell(Text('\$${line.unitPrice.toStringAsFixed(2)}')),
                                        DataCell(Text('\$${line.tax.toStringAsFixed(2)}')),
                                        DataCell(Text('\$${line.subtotal.toStringAsFixed(2)}')),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => setState(() => lineItems.removeAt(index)),
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading vendors')),
                ),
              ),
            ),

            const Divider(),

            // Totals Section
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Subtotal: \$${_calculateSubtotal().toStringAsFixed(2)}'),
                    Text('Tax: \$${_calculateTax().toStringAsFixed(2)}'),
                    Text(
                      'Total: \$${_calculateTotal().toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: paidController,
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      paidAmount = double.tryParse(value) ?? 0.0;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _savePurchaseOrder, child: const Text('Save Purchase Order')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    return lineItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double _calculateTax() {
    return lineItems.fold(0.0, (sum, item) => sum + item.tax);
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTax();
  }

  Future<void> _savePurchaseOrder() async {
    if (selectedVendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor')),
      );
      return;
    }

    if (lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final currentUser = ref.read(currentUserProvider);

    try {
      final subtotal = _calculateSubtotal();
      final taxAmount = _calculateTax();
      final total = _calculateTotal();
      final orderNumber = widget.order?.orderNumber ?? 
          'PO-${DateTime.now().millisecondsSinceEpoch}';

      int purchaseOrderId;

      if (widget.order == null) {
        // Create new purchase order
        purchaseOrderId = await db.into(db.purchaseOrders).insert(
              PurchaseOrdersCompanion.insert(
                orderNumber: orderNumber,
                vendorId: drift.Value(selectedVendorId),
                status: selectedStatus,
                subtotal: drift.Value(subtotal),
                taxAmount: drift.Value(taxAmount),
                total: drift.Value(total),
                paidAmount: drift.Value(paidAmount),
                orderDate: drift.Value(orderDate),
                userId: drift.Value(currentUser?.id),
              ),
            );

        // Insert line items
        for (final line in lineItems) {
          await db.into(db.purchaseOrderLines).insert(
                PurchaseOrderLinesCompanion.insert(
                  orderId: purchaseOrderId,
                  productId: line.product.id,
                  quantity: line.quantity,
                  unitPrice: line.unitPrice,
                  tax: drift.Value(line.tax),
                  subtotal: line.subtotal,
                ),
              );
        }
        // If there was a paid amount, record a payment (default to bank) and update Bank account
        if (paidAmount > 0) {
          try {
            await db.into(db.payments).insert(
              PaymentsCompanion.insert(
                paymentNumber: 'PMT-${orderNumber}',
                partnerId: drift.Value(selectedVendorId),
                paymentType: 'pay',
                reference: drift.Value(orderNumber),
                amount: paidAmount,
                paymentMethod: 'bank',
                userId: drift.Value(currentUser?.id),
              ),
            );

            // Update Bank account (code 1100)
            final accounts = await db.select(db.accounts).get();
            try {
              final bankAccount = accounts.firstWhere((a) => a.code == '1100');
              await (db.update(db.accounts)..where((a) => a.id.equals(bankAccount.id))).write(
                AccountsCompanion(balance: drift.Value(bankAccount.balance - paidAmount)),
              );
            } catch (_) {
              // no bank account found; skip
            }
          } catch (_) {
            // ignore payment record failure
          }
        }
      } else {
        // Update existing purchase order
        purchaseOrderId = widget.order!.id;
        await (db.update(db.purchaseOrders)
              ..where((po) => po.id.equals(purchaseOrderId)))
            .write(
          PurchaseOrdersCompanion(
            vendorId: drift.Value(selectedVendorId),
            status: drift.Value(selectedStatus),
            subtotal: drift.Value(subtotal),
            taxAmount: drift.Value(taxAmount),
            total: drift.Value(total),
            paidAmount: drift.Value(paidAmount),
            orderDate: drift.Value(orderDate),
          ),
        );

        // Delete old line items and insert new ones
        await (db.delete(db.purchaseOrderLines)
              ..where((l) => l.orderId.equals(purchaseOrderId)))
            .go();

        for (final line in lineItems) {
          await db.into(db.purchaseOrderLines).insert(
                PurchaseOrderLinesCompanion.insert(
                  orderId: purchaseOrderId,
                  productId: line.product.id,
                  quantity: line.quantity,
                  unitPrice: line.unitPrice,
                  tax: drift.Value(line.tax),
                  subtotal: line.subtotal,
                ),
              );
        }
        // If payment made, record it (default to bank) and update Bank account
        if (paidAmount > 0) {
          try {
            await db.into(db.payments).insert(
              PaymentsCompanion.insert(
                paymentNumber: 'PMT-${orderNumber}',
                partnerId: drift.Value(selectedVendorId),
                paymentType: 'pay',
                reference: drift.Value(orderNumber),
                amount: paidAmount,
                paymentMethod: 'bank',
                userId: drift.Value(currentUser?.id),
              ),
            );

            final accounts = await db.select(db.accounts).get();
            try {
              final bankAccount = accounts.firstWhere((a) => a.code == '1100');
              await (db.update(db.accounts)..where((a) => a.id.equals(bankAccount.id))).write(
                AccountsCompanion(balance: drift.Value(bankAccount.balance - paidAmount)),
              );
            } catch (_) {}
          } catch (_) {}
        }
      }

      // If status is 'received', update stock quantities
      if (selectedStatus == 'received') {
        for (final line in lineItems) {
          final product = line.product;
          await (db.update(db.products)..where((p) => p.id.equals(product.id)))
              .write(
            ProductsCompanion(
              stockQty: drift.Value(product.stockQty + line.quantity),
            ),
          );

          // Create stock move record
          await db.into(db.stockMoves).insert(
                StockMovesCompanion.insert(
                  productId: product.id,
                  moveType: 'in',
                  reference: drift.Value(orderNumber),
                  quantity: line.quantity,
                  unitCost: drift.Value(line.unitPrice),
                  userId: drift.Value(currentUser?.id),
                  notes: drift.Value('Purchase order received'),
                ),
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase order saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddProductDialog(AsyncValue<List<Product>> productsAsync) {
    showDialog(
      context: context,
      builder: (context) => productsAsync.when(
        data: (products) {
          return _ProductSearchDialog(
            products: products,
            onProductSelected: (product, quantity, price, tax) {
              setState(() {
                lineItems.add(PurchaseOrderLineItem(
                  product: product,
                  quantity: quantity,
                  unitPrice: price,
                  tax: tax,
                ));
              });
              Navigator.pop(context);
            },
          );
        },
        loading: () => AlertDialog(
          title: const Text('Loading Products'),
          content: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error loading products: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSearchDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Product, double, double, double) onProductSelected;

  const _ProductSearchDialog({
    required this.products,
    required this.onProductSelected,
  });

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  late TextEditingController searchController;
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController taxController;
  Product? selectedProduct;
  List<Product> filteredProducts = [];
  bool showFilteredList = false;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    quantityController = TextEditingController(text: '1');
    priceController = TextEditingController();
    taxController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    searchController.dispose();
    quantityController.dispose();
    priceController.dispose();
    taxController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      showFilteredList = query.isNotEmpty;
      if (query.isEmpty) {
        filteredProducts = [];
      } else {
        final q = query.toLowerCase();
        filteredProducts = widget.products
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                (p.sku?.toLowerCase().contains(q) ?? false) ||
                (p.barcode?.toLowerCase().contains(q) ?? false))
            .toList();
      }
    });
  }

  void _selectProduct(Product product) {
    setState(() {
      selectedProduct = product;
      priceController.text = product.costPrice.toStringAsFixed(2);
      searchController.clear();
      showFilteredList = false;
      filteredProducts = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Product Search Field
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                hintText: 'Enter product name, SKU, or barcode',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                            showFilteredList = false;
                            selectedProduct = null;
                            filteredProducts = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: 16),
            // Product List
            if (showFilteredList && filteredProducts.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        'SKU: ${product.sku ?? "N/A"} | Cost: \$${product.costPrice.toStringAsFixed(2)}',
                      ),
                      onTap: () => _selectProduct(product),
                    );
                  },
                ),
              )
            else if (showFilteredList && filteredProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No products found'),
              ),
            const SizedBox(height: 16),
            // Selected Product Display
            if (selectedProduct != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${selectedProduct!.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('SKU: ${selectedProduct!.sku ?? "N/A"}'),
                    Text('Cost Price: \$${selectedProduct!.costPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Quantity Field
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Unit Price Field
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Tax Field
            TextField(
              controller: taxController,
              decoration: const InputDecoration(
                labelText: 'Tax',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedProduct != null) {
              final quantity = double.tryParse(quantityController.text) ?? 1.0;
              final price = double.tryParse(priceController.text) ?? 0.0;
              final tax = double.tryParse(taxController.text) ?? 0.0;
              widget.onProductSelected(selectedProduct!, quantity, price, tax);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class PurchaseOrderLineItem {
  final Product product;
  final double quantity;
  final double unitPrice;
  final double tax;

  PurchaseOrderLineItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.tax,
  });

  double get subtotal => quantity * unitPrice;
}
