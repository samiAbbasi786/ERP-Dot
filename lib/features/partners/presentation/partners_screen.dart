import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/providers/app_providers.dart';

// Partners Provider
final partnersProvider = StreamProvider.family<List<Partner>, String>((ref, type) {
  final db = ref.watch(databaseProvider);
  if (type == 'all') {
    return db.select(db.partners).watch();
  }
  return (db.select(db.partners)..where((p) => p.type.equals(type) | p.type.equals('both'))).watch();
});

class PartnersScreen extends ConsumerStatefulWidget {
  const PartnersScreen({super.key});

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Partners'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Customers', icon: Icon(Icons.people)),
              Tab(text: 'Vendors', icon: Icon(Icons.store)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showPartnerDialog(),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _PartnersList(type: 'customer'),
            _PartnersList(type: 'vendor'),
          ],
        ),
      ),
    );
  }

  void _showPartnerDialog({Partner? partner}) {
    final nameController = TextEditingController(text: partner?.name ?? '');
    final emailController = TextEditingController(text: partner?.email ?? '');
    final phoneController = TextEditingController(text: partner?.phone ?? '');
    final addressController = TextEditingController(text: partner?.address ?? '');
    String type = partner?.type ?? 'customer';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(partner == null ? 'Add Partner' : 'Edit Partner'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name *'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'customer', child: Text('Customer')),
                      DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                      DropdownMenuItem(value: 'both', child: Text('Both')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
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
                if (nameController.text.isEmpty) return;
                _savePartner(
                  partner?.id,
                  nameController.text,
                  type,
                  emailController.text.isEmpty ? null : emailController.text,
                  phoneController.text.isEmpty ? null : phoneController.text,
                  addressController.text.isEmpty ? null : addressController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePartner(
    int? id,
    String name,
    String type,
    String? email,
    String? phone,
    String? address,
  ) async {
    final db = ref.read(databaseProvider);

    if (id == null) {
      await db.into(db.partners).insert(
            PartnersCompanion.insert(
              name: name,
              type: type,
              email: drift.Value(email),
              phone: drift.Value(phone),
              address: drift.Value(address),
            ),
          );
    } else {
      await (db.update(db.partners)..where((p) => p.id.equals(id))).write(
        PartnersCompanion(
          name: drift.Value(name),
          type: drift.Value(type),
          email: drift.Value(email),
          phone: drift.Value(phone),
          address: drift.Value(address),
        ),
      );
    }
  }
}

class _PartnersList extends ConsumerWidget {
  final String type;

  const _PartnersList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersProvider(type));

    return partnersAsync.when(
      data: (partners) {
        if (partners.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'customer' ? Icons.people_outline : Icons.store_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text('No ${type}s yet', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: partners.length,
          itemBuilder: (context, index) {
            final partner = partners[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(partner.name[0].toUpperCase()),
                ),
                title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (partner.email != null)
                      Row(children: [
                        const Icon(Icons.email, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(partner.email!),
                      ]),
                    if (partner.phone != null)
                      Row(children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(partner.phone!),
                      ]),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        // Find the parent state to call _showPartnerDialog
                        // This is a bit hacky, better to move dialog to provider or use a global key
                        // For now, we can just cast the context or use a callback
                        // Or better, make _PartnersList stateful or pass the callback
                        context.findAncestorStateOfType<_PartnersScreenState>()?._showPartnerDialog(partner: partner);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deletePartner(context, ref, partner.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Future<void> _deletePartner(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Partner'),
        content: const Text('Are you sure you want to delete this partner?'),
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
      await (db.delete(db.partners)..where((p) => p.id.equals(id))).go();
    }
  }
}
