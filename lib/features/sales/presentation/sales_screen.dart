import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales')),
        body: const Center(child: Text('Sign in to record sales.')),
      );
    }

    final salesQuery = FirebaseFirestore.instance
        .collection('sales')
        .where('uid', isEqualTo: user.uid);
    return Scaffold(
      appBar: AppBar(title: const Text('Sales management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordSale(context, user.uid),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Record sale'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: salesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load sales. Check Firestore rules.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              return (bTime?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
            });
          final totalRevenue = docs.fold<double>(
            0,
            (sum, doc) =>
                sum + ((doc.data()['total'] as num?)?.toDouble() ?? 0),
          );
          final unitsSold = docs.fold<int>(
            0,
            (sum, doc) =>
                sum + ((doc.data()['quantity'] as num?)?.toInt() ?? 0),
          );

          if (docs.isEmpty) {
            return _emptyState(context, user.uid);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      'Sales recorded',
                      '${docs.length}',
                      Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      'Units sold',
                      '$unitsSold',
                      Icons.shopping_bag_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _metricCard(
                'Recorded revenue',
                'ETB ${totalRevenue.toStringAsFixed(2)}',
                Icons.payments_outlined,
              ),
              const SizedBox(height: 18),
              const Text(
                'Recent sales',
                style: TextStyle(
                  color: AppTheme.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...docs.map((doc) {
                final data = doc.data();
                final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
                final unitPrice =
                    (data['unitPrice'] as num?)?.toDouble() ?? 0;
                final total = (data['total'] as num?)?.toDouble() ??
                    quantity * unitPrice;
                final timestamp = data['createdAt'] as Timestamp?;
                final date = timestamp == null
                    ? 'Just recorded'
                    : _formatDate(timestamp.toDate());
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F1FF),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: AppTheme.blue,
                      ),
                    ),
                    title: Text(
                      data['productName'] as String? ?? 'Product',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        '$quantity × ETB ${unitPrice.toStringAsFixed(2)}',
                        if ((data['customerName'] as String? ?? '').isNotEmpty)
                          'Customer: ${data['customerName']}',
                        date,
                      ].join(' • '),
                    ),
                    trailing: Text(
                      'ETB ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800,
                      ),
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

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  Widget _metricCard(String label, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.blue, size: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _emptyState(BuildContext context, String uid) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.point_of_sale_outlined,
                size: 58,
                color: AppTheme.blue,
              ),
              const SizedBox(height: 14),
              const Text(
                'Start recording sales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an inventory product, enter the quantity sold, and WiseSell will update your stock.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _showRecordSale(context, uid),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Record first sale'),
              ),
            ],
          ),
        ),
      );

  Future<void> _showRecordSale(BuildContext context, String uid) async {
    final productsRef = FirebaseFirestore.instance.collection('products');
    final productsSnapshot = await productsRef.where('uid', isEqualTo: uid).get();
    if (!context.mounted) return;

    final products = productsSnapshot.docs;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a product to inventory before recording a sale.')),
      );
      return;
    }

    final available = products.where((doc) {
      return ((doc.data()['quantity'] as num?)?.toInt() ?? 0) > 0;
    }).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products are currently in stock.')),
      );
      return;
    }

    final customersSnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('uid', isEqualTo: uid)
        .get();
    if (!context.mounted) return;
    final customers = customersSnapshot.docs;

    String selectedId = available.first.id;
    String? selectedCustomerId;
    final quantityController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selected = available.firstWhere((doc) => doc.id == selectedId);
          final selectedData = selected.data();
          final stock =
              (selectedData['quantity'] as num?)?.toInt() ?? 0;
          final price = (selectedData['price'] as num?)?.toDouble() ?? 0;
          return AlertDialog(
            title: const Text('Record a sale'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(),
                    ),
                    items: available.map((doc) {
                      final data = doc.data();
                      final name = data['name'] as String? ?? 'Product';
                      final count =
                          (data['quantity'] as num?)?.toInt() ?? 0;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text('$name ($count in stock)',
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setDialogState(() => selectedId = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedCustomerId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Customer (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Walk-in / no customer'),
                      ),
                      ...customers.map((doc) => DropdownMenuItem<String?>(
                            value: doc.id,
                            child: Text(
                              doc.data()['name'] as String? ?? 'Customer',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: saving
                        ? null
                        : (value) => setDialogState(
                              () => selectedCustomerId = value,
                            ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity sold',
                      helperText: 'Available stock: $stock',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final quantity = int.tryParse(value?.trim() ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Enter a quantity greater than zero';
                      }
                      if (quantity > stock) return 'Not enough stock available';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Unit selling price: ETB ${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final quantity =
                            int.parse(quantityController.text.trim());
                        setDialogState(() => saving = true);
                        try {
                          final productRef = productsRef.doc(selectedId);
                          final saleRef =
                              FirebaseFirestore.instance.collection('sales').doc();
                          await FirebaseFirestore.instance
                              .runTransaction((transaction) async {
                            final freshProduct =
                                await transaction.get(productRef);
                            final customerRef = selectedCustomerId == null
                                ? null
                                : FirebaseFirestore.instance
                                    .collection('customers')
                                    .doc(selectedCustomerId);
                            final freshCustomer = customerRef == null
                                ? null
                                : await transaction.get(customerRef);
                            if (customerRef != null &&
                                (freshCustomer == null ||
                                    !freshCustomer.exists ||
                                    freshCustomer.data()?['uid'] != uid)) {
                              throw StateError('Selected customer is unavailable.');
                            }
                            if (!freshProduct.exists) {
                              throw StateError('Product no longer exists.');
                            }
                            final data = freshProduct.data()!;
                            if (data['uid'] != uid) {
                              throw StateError('Product access denied.');
                            }
                            final currentStock =
                                (data['quantity'] as num?)?.toInt() ?? 0;
                            if (currentStock < quantity) {
                              throw StateError('Insufficient stock.');
                            }
                            final currentPrice =
                                (data['price'] as num?)?.toDouble() ?? 0;
                            final productName =
                                data['name'] as String? ?? 'Product';
                            final total = currentPrice * quantity;
                            transaction.update(productRef, {
                              'quantity': currentStock - quantity,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                            transaction.set(saleRef, {
                              'uid': uid,
                              'productId': selectedId,
                              'productName': productName,
                              if (freshCustomer != null)
                                'customerId': selectedCustomerId,
                              if (freshCustomer != null)
                                'customerName': freshCustomer.data()?['name'] as String? ?? 'Customer',
                              'quantity': quantity,
                              'unitPrice': currentPrice,
                              'total': total,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          });
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sale recorded and stock updated.'),
                              ),
                            );
                          }
                        } catch (error) {
                          setDialogState(() => saving = false);
                          final message = error is StateError
                              ? error.message
                              : 'Could not record sale. Check your connection and Firestore rules.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                      },
                child: Text(saving ? 'Recording...' : 'Confirm sale'),
              ),
            ],
          );
        },
      ),
    );
    quantityController.dispose();
  }
}
