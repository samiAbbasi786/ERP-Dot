import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/providers/app_providers.dart';

// Products Provider
final productsProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.products).watch();
});

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No products yet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Image')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Brand')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: products.map((product) {
                    final isLowStock = product.stockQty <= product.minStockLevel;
                    return DataRow(
                      cells: [
                        DataCell(
                          product.imagePath != null
                              ? CircleAvatar(backgroundImage: NetworkImage(product.imagePath!))
                              : const CircleAvatar(child: Icon(Icons.image)),
                        ),
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(product.barcode ?? '-', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        )),
                        DataCell(Text(product.brand ?? '-')),
                        DataCell(Text(product.sku ?? '-')),
                        DataCell(Text('\$${product.salePrice.toStringAsFixed(2)}')),
                        DataCell(Text(
                          '${product.stockQty.toStringAsFixed(0)} ${product.unit}',
                          style: TextStyle(
                            color: isLowStock ? Colors.red : null,
                            fontWeight: isLowStock ? FontWeight.bold : null,
                          ),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                            color: isLowStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isLowStock ? 'Low Stock' : 'In Stock',
                            style: TextStyle(
                              color: isLowStock ? Colors.red : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showProductDialog(product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteProduct(product.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final skuController = TextEditingController(text: product?.sku ?? '');
    final brandController = TextEditingController(text: product?.brand ?? '');
    final imageController = TextEditingController(text: product?.imagePath ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final costController = TextEditingController(text: product?.costPrice.toString() ?? '0');
    final saleController = TextEditingController(text: product?.salePrice.toString() ?? '0');
    final stockController = TextEditingController(text: product?.stockQty.toString() ?? '0');
    final minStockController = TextEditingController(text: product?.minStockLevel.toString() ?? '5');
    final unitController = TextEditingController(text: product?.unit ?? 'pcs');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Product Name *'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'Brand'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(labelText: 'Barcode'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: skuController,
                        decoration: const InputDecoration(labelText: 'SKU'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costController,
                        decoration: const InputDecoration(labelText: 'Cost Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: saleController,
                        decoration: const InputDecoration(labelText: 'Sale Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        decoration: const InputDecoration(labelText: 'Current Stock'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: minStockController,
                        decoration: const InputDecoration(labelText: 'Min Stock Level'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
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
              _saveProduct(
                product?.id,
                nameController.text,
                barcodeController.text.isEmpty ? null : barcodeController.text,
                skuController.text.isEmpty ? null : skuController.text,
                brandController.text.isEmpty ? null : brandController.text,
                imageController.text.isEmpty ? null : imageController.text,
                descController.text.isEmpty ? null : descController.text,
                double.tryParse(costController.text) ?? 0,
                double.tryParse(saleController.text) ?? 0,
                double.tryParse(stockController.text) ?? 0,
                double.tryParse(minStockController.text) ?? 0,
                unitController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct(
    int? id,
    String name,
    String? barcode,
    String? sku,
    String? brand,
    String? imagePath,
    String? description,
    double costPrice,
    double salePrice,
    double stockQty,
    double minStockLevel,
    String unit,
  ) async {
    final db = ref.read(databaseProvider);

    if (id == null) {
      // Insert
      await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: name,
              barcode: drift.Value(barcode),
              sku: drift.Value(sku),
              brand: drift.Value(brand),
              imagePath: drift.Value(imagePath),
              description: drift.Value(description),
              costPrice: drift.Value(costPrice),
              salePrice: drift.Value(salePrice),
              stockQty: drift.Value(stockQty),
              minStockLevel: drift.Value(minStockLevel),
              unit: drift.Value(unit),
            ),
          );
    } else {
      // Update
      await (db.update(db.products)..where((p) => p.id.equals(id))).write(
        ProductsCompanion(
          name: drift.Value(name),
          barcode: drift.Value(barcode),
          sku: drift.Value(sku),
          brand: drift.Value(brand),
          imagePath: drift.Value(imagePath),
          description: drift.Value(description),
          costPrice: drift.Value(costPrice),
          salePrice: drift.Value(salePrice),
          stockQty: drift.Value(stockQty),
          minStockLevel: drift.Value(minStockLevel),
          unit: drift.Value(unit),
        ),
      );
    }
  }

  Future<void> _deleteProduct(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.products)..where((p) => p.id.equals(id))).go();
    }
  }
}
