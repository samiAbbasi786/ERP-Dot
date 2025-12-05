import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/app_providers.dart';
import '../data/receipt_service.dart';

// Cart Item Model
class CartItem {
  final Product product;
  double quantity;
  double discount;
  double taxRate; // Percentage

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
    this.taxRate = 0,
  });

  double get subtotal => (product.salePrice * quantity) - discount;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;
}

// Cart Provider
final cartProvider = StateProvider<List<CartItem>>((ref) => []);

// Selected Customer Provider
final selectedCustomerProvider = StateProvider<Partner?>((ref) => null);

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Partner> _customers = [];
  String _paymentMethod = 'cash'; // Default payment method

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final products = await db.select(db.products).get();
    final customers = await (db.select(db.partners)..where((p) => p.type.equals('customer') | p.type.equals('both'))).get();
    
    setState(() {
      _products = products;
      _filteredProducts = products;
      _customers = customers;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.barcode?.contains(query) ?? false) ||
              (p.sku?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  void _addToCart(Product product) {
    final cart = ref.read(cartProvider.notifier);
    final currentCart = ref.read(cartProvider);
    
    final existingIndex = currentCart.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      currentCart[existingIndex].quantity++;
      cart.state = [...currentCart];
    } else {
      cart.state = [...currentCart, CartItem(product: product)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    
    final subtotal = cart.fold<double>(0, (sum, item) => sum + item.subtotal);
    final totalTax = cart.fold<double>(0, (sum, item) => sum + item.taxAmount);
    final total = subtotal + totalTax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          // Customer Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<Partner>(
              value: selectedCustomer,
              hint: const Text('Select Customer'),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<Partner>(
                  value: null,
                  child: Text('Walk-in Customer'),
                ),
                ..._customers.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (customer) {
                ref.read(selectedCustomerProvider.notifier).state = customer;
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Products Grid
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search products',
                      hintText: 'Name, Barcode, SKU',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _filterProducts,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _addToCart(product),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: product.imagePath != null
                                    ? Image.network(
                                        product.imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        child: Icon(
                                          Icons.inventory_2,
                                          size: 48,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '\$${product.salePrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Qty: ${product.stockQty.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: product.stockQty <= product.minStockLevel ? Colors.red : Colors.grey[600],
                                            fontWeight: product.stockQty <= product.minStockLevel ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Cart
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).colorScheme.primary,
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Current Order',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cart.length} Items',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Cart is empty', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = cart[index];
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('\$${item.product.salePrice.toStringAsFixed(2)} / unit'),
                                  trailing: Text(
                                    '\$${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          item.quantity--;
                                          ref.read(cartProvider.notifier).state = [...cart];
                                        }
                                      },
                                    ),
                                    Text('${item.quantity.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        item.quantity++;
                                        ref.read(cartProvider.notifier).state = [...cart];
                                      },
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        cart.removeAt(index);
                                        ref.read(cartProvider.notifier).state = [...cart];
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Subtotal', value: subtotal),
                      const SizedBox(height: 8),
                      _SummaryRow(label: 'Tax', value: totalTax),
                      const Divider(height: 24),
                      _SummaryRow(label: 'Total', value: total, isTotal: true),
                      const SizedBox(height: 24),
                      // Payment Method Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _PaymentMethodChip(
                                label: 'Cash',
                                icon: Icons.money,
                                isSelected: _paymentMethod == 'cash',
                                onTap: () => setState(() => _paymentMethod = 'cash'),
                              ),
                              const SizedBox(width: 8),
                              _PaymentMethodChip(
                                label: 'Card',
                                icon: Icons.credit_card,
                                isSelected: _paymentMethod == 'card',
                                onTap: () => setState(() => _paymentMethod = 'card'),
                              ),
                              const SizedBox(width: 8),
                              _PaymentMethodChip(
                                label: 'Online',
                                icon: Icons.qr_code,
                                isSelected: _paymentMethod == 'online',
                                onTap: () => setState(() => _paymentMethod = 'online'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: cart.isEmpty ? null : () => _checkout(cart, total, subtotal, totalTax),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(List<CartItem> cart, double total, double subtotal, double taxAmount) async {
    final db = ref.read(databaseProvider);
    final accountingService = ref.read(accountingServiceProvider);
    final user = ref.read(currentUserProvider);
    final customer = ref.read(selectedCustomerProvider);
    
    try {
      // Generate order number
      final orderNumber = 'POS-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      
      // Create sales order
      final orderId = await db.into(db.salesOrders).insert(
        SalesOrdersCompanion.insert(
          orderNumber: orderNumber,
          customerId: drift.Value(customer?.id),
          status: 'done',
          subtotal: drift.Value(subtotal),
          taxAmount: drift.Value(taxAmount),
          total: drift.Value(total),
          paidAmount: drift.Value(total),
          userId: drift.Value(user?.id),
        ),
      );
      
      // Create order lines and update stock
      final orderLines = <SalesOrderLine>[];
      for (final item in cart) {
        final lineId = await db.into(db.salesOrderLines).insert(
          SalesOrderLinesCompanion.insert(
            orderId: orderId,
            productId: item.product.id,
            quantity: item.quantity,
            unitPrice: item.product.salePrice,
            discount: drift.Value(item.discount),
            tax: drift.Value(item.taxAmount),
            subtotal: item.subtotal,
          ),
        );
        
        // Fetch the created line to use in accounting
        final line = await (db.select(db.salesOrderLines)..where((l) => l.id.equals(lineId))).getSingle();
        orderLines.add(line);
        
        // Update product stock
        await (db.update(db.products)..where((p) => p.id.equals(item.product.id))).write(
          ProductsCompanion(
            stockQty: drift.Value(item.product.stockQty - item.quantity),
          ),
        );
        
        // Create stock move
        await db.into(db.stockMoves).insert(
          StockMovesCompanion.insert(
            productId: item.product.id,
            moveType: 'out',
            reference: drift.Value(orderNumber),
            quantity: item.quantity,
            userId: drift.Value(user?.id),
          ),
        );
      }
      
      // Record payment
      await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          paymentNumber: 'PMT-${orderNumber}',
          partnerId: drift.Value(customer?.id),
          paymentType: 'receive',
          reference: drift.Value(orderNumber),
          amount: total,
          paymentMethod: _paymentMethod,
          userId: drift.Value(user?.id),
        ),
      );

      // Create Accounting Journal Entries
      final order = await (db.select(db.salesOrders)..where((o) => o.id.equals(orderId))).getSingle();
      await accountingService.createSaleJournalEntry(
        order: order,
        lines: orderLines,
        paymentMethod: _paymentMethod,
      );
      
      // Show Receipt
      if (mounted) {
        await _showReceiptDialog(orderNumber, cart, total, subtotal, taxAmount, _paymentMethod);
      }

      // Clear cart
      ref.read(cartProvider.notifier).state = [];
      ref.read(selectedCustomerProvider.notifier).state = null;
      setState(() {
        _paymentMethod = 'cash';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale completed: $orderNumber'), backgroundColor: Colors.green),
        );
      }
      
      _loadData(); // Refresh products to show updated stock
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showReceiptDialog(String orderNumber, List<CartItem> cart, double total, double subtotal, double tax, String method) async {
    final customer = ref.read(selectedCustomerProvider);
    final orderDate = DateTime.now();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.store, size: 48),
                    const SizedBox(height: 8),
                    const Text('MY STORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(DateTime.now().toString().substring(0, 16)),
                  ],
                ),
              ),
              const Divider(height: 32),
              Text('Order: $orderNumber'),
              if (customer != null) Text('Customer: ${customer.name}'),
              Text('Method: ${method.toUpperCase()}'),
              const SizedBox(height: 16),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.quantity.toInt()}x ${item.product.name}')),
                          Text('\$${item.total.toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('\$${subtotal.toStringAsFixed(2)}')]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tax'), Text('\$${tax.toStringAsFixed(2)}')]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 24),
              const Center(child: Text('Thank you for shopping!', style: TextStyle(fontStyle: FontStyle.italic))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await ReceiptService.shareReceipt(
                  orderNumber: orderNumber,
                  orderDate: orderDate,
                  items: cart,
                  subtotal: subtotal,
                  tax: tax,
                  total: total,
                  paymentMethod: method,
                  customerName: customer?.name,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to share receipt: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share PDF'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ReceiptService.printReceipt(
                  orderNumber: orderNumber,
                  orderDate: orderDate,
                  items: cart,
                  subtotal: subtotal,
                  tax: tax,
                  total: total,
                  paymentMethod: method,
                  customerName: customer?.name,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to print receipt: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _SummaryRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Theme.of(context).colorScheme.onSurface : Colors.grey[600],
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Theme.of(context).colorScheme.primary : Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
