import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/providers/app_providers.dart';

// Vendors Provider (Partners who are vendors)
final vendorsProvider = StreamProvider<List<Partner>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.partners)
        ..where((p) => p.type.equals('vendor') | p.type.equals('both')))
      .watch();
});

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const VendorDialog(),
              );
            },
          ),
        ],
      ),
      body: vendorsAsync.when(
        data: (vendors) {
          if (vendors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No vendors yet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const VendorDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vendor'),
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
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Balance')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: vendors.map((vendor) {
                  return DataRow(cells: [
                    DataCell(Text(vendor.name)),
                    DataCell(Text(vendor.email ?? '-')),
                    DataCell(Text(vendor.phone ?? '-')),
                    DataCell(
                      Chip(
                        label: Text(vendor.type),
                        backgroundColor: _getTypeColor(vendor.type),
                      ),
                    ),
                    DataCell(
                      Chip(
                        label: Text(vendor.isActive ? 'Active' : 'Inactive'),
                        backgroundColor:
                            vendor.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    DataCell(Text('\$${vendor.balance.toStringAsFixed(2)}')),
                    DataCell(
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Edit'),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      VendorDialog(vendor: vendor),
                                );
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () {
                              _showDeleteConfirmation(context, ref, vendor);
                            },
                          ),
                        ],
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'vendor':
        return Colors.blue;
      case 'customer':
        return Colors.orange;
      case 'both':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Partner vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Are you sure you want to delete ${vendor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              try {
                await (db.delete(db.partners)..where((p) => p.id.equals(vendor.id)))
                    .go();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vendor deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class VendorDialog extends ConsumerStatefulWidget {
  final Partner? vendor;

  const VendorDialog({super.key, this.vendor});

  @override
  ConsumerState<VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends ConsumerState<VendorDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController balanceController;
  String selectedType = 'vendor';
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      nameController = TextEditingController(text: widget.vendor!.name);
      emailController = TextEditingController(text: widget.vendor!.email ?? '');
      phoneController = TextEditingController(text: widget.vendor!.phone ?? '');
      addressController = TextEditingController(text: widget.vendor!.address ?? '');
      balanceController =
          TextEditingController(text: widget.vendor!.balance.toStringAsFixed(2));
      selectedType = widget.vendor!.type;
      isActive = widget.vendor!.isActive;
    } else {
      nameController = TextEditingController();
      emailController = TextEditingController();
      phoneController = TextEditingController();
      addressController = TextEditingController();
      balanceController = TextEditingController(text: '0');
      selectedType = 'vendor';
      isActive = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.vendor == null ? 'Add Vendor' : 'Edit Vendor',
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
              // Vendor Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              // Email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Phone
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Address
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Type
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'both', child: Text('Both Vendor & Customer')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Balance
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Status Toggle
              Row(
                children: [
                  const Text('Status: '),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Switch(
                      value: isActive,
                      onChanged: (value) {
                        setState(() => isActive = value);
                      },
                    ),
                  ),
                  Text(isActive ? 'Active' : 'Inactive'),
                ],
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveVendor,
                    child: Text(widget.vendor == null ? 'Add Vendor' : 'Update Vendor'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveVendor() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter vendor name')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final balance = double.tryParse(balanceController.text) ?? 0.0;

    try {
      if (widget.vendor == null) {
        // Add new vendor
        await db.into(db.partners).insert(
              PartnersCompanion.insert(
                name: nameController.text,
                type: selectedType,
                email: drift.Value(emailController.text.isNotEmpty ? emailController.text : null),
                phone: drift.Value(phoneController.text.isNotEmpty ? phoneController.text : null),
                address: drift.Value(addressController.text.isNotEmpty ? addressController.text : null),
                balance: drift.Value(balance),
                isActive: drift.Value(isActive),
              ),
            );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor added successfully')),
          );
        }
      } else {
        // Update existing vendor
        await (db.update(db.partners)
              ..where((p) => p.id.equals(widget.vendor!.id)))
            .write(
          PartnersCompanion(
            name: drift.Value(nameController.text),
            type: drift.Value(selectedType),
            email: drift.Value(emailController.text.isNotEmpty ? emailController.text : null),
            phone: drift.Value(phoneController.text.isNotEmpty ? phoneController.text : null),
            address: drift.Value(addressController.text.isNotEmpty ? addressController.text : null),
            balance: drift.Value(balance),
            isActive: drift.Value(isActive),
          ),
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
