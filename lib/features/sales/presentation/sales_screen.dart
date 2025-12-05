import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/app_providers.dart';

// Sales Orders Provider
final salesOrdersProvider = StreamProvider<List<SalesOrder>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.salesOrders).watch();
});

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Orders'),
      ),
      body: salesAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No sales orders yet'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Order #')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Paid')),
                  DataColumn(label: Text('Balance')),
                ],
                rows: orders.map((order) {
                  final balance = order.total - order.paidAmount;
                  return DataRow(cells: [
                    DataCell(Text(order.orderNumber)),
                    DataCell(Text(DateFormat('yyyy-MM-dd').format(order.orderDate))),
                    DataCell(Text(order.customerId?.toString() ?? '-')),
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
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
