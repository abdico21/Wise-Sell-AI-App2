import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory')),
        body: const Center(child: Text('Sign in to manage your products.')),
      );
    }
    final products = FirebaseFirestore.instance.collection('products')
        .where('uid', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Product inventory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductEditor(context, user.uid),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: products.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load inventory. Check Firestore rules.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final at = a.data()['updatedAt'] as Timestamp?;
              final bt = b.data()['updatedAt'] as Timestamp?;
              return (bt?.millisecondsSinceEpoch ?? 0)
                  .compareTo(at?.millisecondsSinceEpoch ?? 0);
            });
          final totalUnits = docs.fold<int>(
            0, (sum, doc) => sum + ((doc.data()['quantity'] as num?)?.toInt() ?? 0));
          final inventoryValue = docs.fold<double>(0, (sum, doc) {
            final data = doc.data();
            return sum + ((data['price'] as num?)?.toDouble() ?? 0) *
                ((data['quantity'] as num?)?.toInt() ?? 0);
          });

          if (docs.isEmpty) {
            return _emptyState(context);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Row(children: [
                Expanded(child: _summaryCard('Products', '${docs.length}', Icons.inventory_2_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _summaryCard('Units in stock', '$totalUnits', Icons.warehouse_outlined)),
              ]),
              const SizedBox(height: 10),
              _summaryCard('Stock value', '${inventoryValue.toStringAsFixed(2)}', Icons.payments_outlined),
              const SizedBox(height: 18),
              const Text('Your products', style: TextStyle(
                color: AppTheme.navy, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...docs.map((doc) {
                final data = doc.data();
                final name = data['name'] as String? ?? 'Unnamed product';
                final sku = data['sku'] as String? ?? '';
                final category = data['category'] as String? ?? '';
                final price = (data['price'] as num?)?.toDouble() ?? 0;
                final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
                final lowStock = quantity <= 5;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lowStock ? Colors.orange.shade50 : Colors.blue.shade50,
                      child: Icon(Icons.inventory_2_outlined,
                        color: lowStock ? Colors.deepOrange : AppTheme.blue),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${category.isEmpty ? 'General' : category}'
                      '${sku.isEmpty ? '' : ' • $sku'}\n'
                      'ETB ${price.toStringAsFixed(2)}  •  $quantity in stock',
                      maxLines: 2),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showProductEditor(context, user.uid, docId: doc.id, initial: data);
                        } else if (value == 'delete') {
                          _confirmDelete(context, doc.reference);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inventory_2_outlined, size: 58, color: AppTheme.blue),
        const SizedBox(height: 14),
        const Text('Your inventory is ready',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.navy)),
        const SizedBox(height: 8),
        const Text('Add your first product to track prices and stock levels.',
          textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _showProductEditor(context, FirebaseAuth.instance.currentUser!.uid),
          icon: const Icon(Icons.add), label: const Text('Add first product')),
      ]),
    ),
  );

  Widget _summaryCard(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(children: [
        Icon(icon, color: AppTheme.blue, size: 25),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        ])),
      ]),
    ),
  );

  Future<void> _showProductEditor(
    BuildContext context,
    String uid, {
    String? docId,
    Map<String, dynamic>? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: initial?['name'] as String? ?? '');
    final sku = TextEditingController(text: initial?['sku'] as String? ?? '');
    final category = TextEditingController(text: initial?['category'] as String? ?? '');
    final price = TextEditingController(text: initial?['price']?.toString() ?? '');
    final quantity = TextEditingController(text: initial?['quantity']?.toString() ?? '0');
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(docId == null ? 'Add product' : 'Edit product'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _input(name, 'Product name'),
                _input(sku, 'SKU / product code', required: false),
                _input(category, 'Category', required: false),
                _input(price, 'Selling price (ETB)', numeric: true),
                _input(quantity, 'Quantity in stock', numeric: true, integer: true),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => saving = true);
                try {
                  final ref = FirebaseFirestore.instance.collection('products');
                  final payload = <String, dynamic>{
                    'uid': uid,
                    'name': name.text.trim(),
                    'sku': sku.text.trim(),
                    'category': category.text.trim(),
                    'price': double.parse(price.text.trim()),
                    'quantity': int.parse(quantity.text.trim()),
                    'updatedAt': FieldValue.serverTimestamp(),
                    if (docId == null) 'createdAt': FieldValue.serverTimestamp(),
                  };
                  if (docId == null) {
                    await ref.add(payload);
                  } else {
                    await ref.doc(docId).update(payload);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(docId == null ? 'Product added.' : 'Product updated.')));
                  }
                } catch (_) {
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not save product. Check your connection and Firestore rules.')));
                }
              },
              child: Text(saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
    name.dispose(); sku.dispose(); category.dispose(); price.dispose(); quantity.dispose();
  }

  Widget _input(TextEditingController controller, String label,
      {bool required = true, bool numeric = false, bool integer = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return 'Required field';
          if (numeric && text.isNotEmpty) {
            final parsed = integer ? int.tryParse(text) : double.tryParse(text);
            if (parsed == null || parsed < 0) return 'Enter a valid non-negative number';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      DocumentReference<Map<String, dynamic>> reference) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text('This removes the product from your inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await reference.delete();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete product. Check Firestore rules.')));
        }
      }
    }
  }
}
