import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.marketplace)),
        body: Center(child: Text(l.signInManageProducts)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.marketplace),
          bottom: TabBar(tabs: [
            Tab(text: l.marketplaceBrowse),
            Tab(text: l.marketplaceMyOrders),
            Tab(text: l.marketplaceSellerDesk),
          ]),
        ),
        body: TabBarView(children: [
          _BrowseTab(uid: user.uid),
          _BuyerOrdersTab(uid: user.uid),
          _SellerDeskTab(uid: user.uid),
        ]),
      ),
    );
  }
}

class _BrowseTab extends StatelessWidget {
  const _BrowseTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final query = FirebaseFirestore.instance
        .collection('marketplace_listings')
        .where('isActive', isEqualTo: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(l.marketplaceLoadFailed));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final listings = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final at = a.data()['createdAt'] as Timestamp?;
            final bt = b.data()['createdAt'] as Timestamp?;
            return (bt?.millisecondsSinceEpoch ?? 0)
                .compareTo(at?.millisecondsSinceEpoch ?? 0);
          });
        if (listings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 58, color: AppTheme.blue),
                  const SizedBox(height: 14),
                  Text(l.marketplaceNoListings,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(l.marketplacePublishHint, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: listings.map((doc) {
            final data = doc.data();
            final sellerUid = data['sellerUid'] as String? ?? '';
            final name = data['productName'] as String? ?? l.product;
            final seller = data['sellerBusinessName'] as String? ??
                l.marketplaceSeller;
            final category = data['category'] as String? ?? '';
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            final quantity = (data['quantityAvailable'] as num?)?.toInt() ?? 0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const CircleAvatar(
                        child: Icon(Icons.inventory_2_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                            Text(seller, style: TextStyle(
                              color: Colors.blueGrey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ]),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(category),
                    ],
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Text(
                        'ETB ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.navy, fontSize: 17,
                          fontWeight: FontWeight.w800))),
                      Text(l.marketplaceStock.replaceAll(
                          'COUNT_VALUE', quantity.toString())),
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: sellerUid == uid || quantity < 1
                            ? null
                            : () => _placeOrder(context, doc.id, data),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: Text(sellerUid == uid
                            ? l.marketplaceYourListing
                            : l.marketplacePlaceOrder),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _placeOrder(
    BuildContext context,
    String listingId,
    Map<String, dynamic> listing,
  ) async {
    final l = AppLocalizations.of(context)!;
    final quantityController = TextEditingController(text: '1');
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.marketplacePlaceOrder),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(listing['productName'] as String? ?? l.product),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.marketplaceQuantity,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final amount = int.tryParse(value?.trim() ?? '');
                    final stock =
                        (listing['quantityAvailable'] as num?)?.toInt() ?? 0;
                    if (amount == null || amount < 1 || amount > stock) {
                      return l.marketplaceInvalidQuantity;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l.marketplaceNote,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: sending ? null : () async {
                if (!formKey.currentState!.validate()) return;
                final amount = int.parse(quantityController.text.trim());
                setDialogState(() => sending = true);
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final price = (listing['price'] as num).toDouble();
                  await FirebaseFirestore.instance
                      .collection('marketplace_orders')
                      .add({
                    'buyerUid': user.uid,
                    'buyerName': user.displayName ?? user.email ?? l.marketplaceBuyer,
                    'sellerUid': listing['sellerUid'],
                    'listingId': listingId,
                    'productName': listing['productName'],
                    'quantity': amount,
                    'unitPrice': price,
                    'total': price * amount,
                    'note': noteController.text.trim(),
                    'status': 'requested',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.marketplaceRequestSent)));
                  }
                } catch (_) {
                  setDialogState(() => sending = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.marketplaceActionFailed)));
                }
              },
              child: Text(sending ? l.saving : l.marketplaceSendRequest),
            ),
          ],
        ),
      ),
    );
    quantityController.dispose();
    noteController.dispose();
  }
}

class _BuyerOrdersTab extends StatelessWidget {
  const _BuyerOrdersTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stream = FirebaseFirestore.instance
        .collection('marketplace_orders')
        .where('buyerUid', isEqualTo: uid)
        .snapshots();

    return _OrdersList(stream: stream, emptyText: l.marketplaceNoBuyerOrders);
  }
}

class _SellerDeskTab extends StatelessWidget {
  const _SellerDeskTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final listings = FirebaseFirestore.instance
        .collection('marketplace_listings')
        .where('sellerUid', isEqualTo: uid)
        .snapshots();
    final orders = FirebaseFirestore.instance
        .collection('marketplace_orders')
        .where('sellerUid', isEqualTo: uid)
        .snapshots();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _publishProduct(context, uid),
            icon: const Icon(Icons.add_business),
            label: Text(l.marketplacePublishProduct),
          ),
        ),
        const SizedBox(height: 16),
        Text(l.marketplaceMyListings, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.navy)),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: listings,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(l.marketplaceLoadFailed);
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l.marketplaceNoSellerListings),
              );
            }
            return Column(children: snapshot.data!.docs.map((doc) {
              final data = doc.data();
              final active = data['isActive'] == true;
              return Card(
                child: SwitchListTile(
                  title: Text(data['productName'] as String? ?? l.product),
                  subtitle: Text(active
                      ? l.marketplaceListingActive
                      : l.marketplaceListingPaused),
                  value: active,
                  onChanged: (value) async {
                    try {
                      await doc.reference.update({
                        'isActive': value,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.marketplaceActionFailed)));
                      }
                    }
                  },
                ),
              );
            }).toList());
          },
        ),
        const SizedBox(height: 20),
        Text(l.marketplaceIncomingOrders, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.navy)),
        _OrdersList(stream: orders, emptyText: l.marketplaceNoSellerOrders,
          sellerActions: true),
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.stream,
    required this.emptyText,
    this.sellerActions = false,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyText;
  final bool sellerActions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(l.marketplaceLoadFailed);
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final at = a.data()['createdAt'] as Timestamp?;
            final bt = b.data()['createdAt'] as Timestamp?;
            return (bt?.millisecondsSinceEpoch ?? 0)
                .compareTo(at?.millisecondsSinceEpoch ?? 0);
          });
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(emptyText),
          );
        }
        return Column(children: docs.map((doc) {
          final data = doc.data();
          final status = data['status'] as String? ?? 'requested';
          final total = (data['total'] as num?)?.toDouble() ?? 0;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['productName'] as String? ?? l.product,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${l.marketplaceQuantity}: ${data['quantity'] ?? 0}'),
                  Text('ETB ${total.toStringAsFixed(2)}'),
                  if ((data['note'] as String? ?? '').isNotEmpty)
                    Text(data['note'] as String),
                  const SizedBox(height: 6),
                  Text('${l.marketplaceOrderStatus}: ${_statusLabel(status, l)}'),
                  if (sellerActions && status == 'requested') ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      OutlinedButton(
                        onPressed: () => _updateStatus(context, doc.reference, 'rejected'),
                        child: Text(l.marketplaceReject),
                      ),
                      FilledButton(
                        onPressed: () => _updateStatus(context, doc.reference, 'accepted'),
                        child: Text(l.marketplaceAccept),
                      ),
                    ]),
                  ],
                  if (sellerActions && status == 'accepted')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _updateStatus(
                            context, doc.reference, 'completed'),
                        child: Text(l.marketplaceMarkCompleted),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList());
      },
    );
  }

  String _statusLabel(String status, AppLocalizations l) {
    switch (status) {
      case 'accepted': return l.marketplaceAccepted;
      case 'rejected': return l.marketplaceRejected;
      case 'completed': return l.marketplaceCompleted;
      default: return l.marketplaceRequested;
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    String status,
  ) async {
    final l = AppLocalizations.of(context)!;
    try {
      await reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.marketplaceActionFailed)));
      }
    }
  }
}

Future<void> _publishProduct(BuildContext context, String uid) async {
  final l = AppLocalizations.of(context)!;
  final firestore = FirebaseFirestore.instance;
  final products = await firestore.collection('products')
      .where('uid', isEqualTo: uid).get();
  if (!context.mounted) return;
  final available = products.docs.where((doc) {
    return ((doc.data()['quantity'] as num?)?.toInt() ?? 0) > 0;
  }).toList();
  if (available.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.marketplaceAddStockFirst)));
    return;
  }

  String selectedId = available.first.id;
  var saving = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final selected = available.firstWhere((doc) => doc.id == selectedId);
        final data = selected.data();
        return AlertDialog(
          title: Text(l.marketplacePublishProduct),
          content: DropdownButtonFormField<String>(
            value: selectedId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.product,
              border: const OutlineInputBorder()),
            items: available.map((doc) {
              final item = doc.data();
              final stock = (item['quantity'] as num?)?.toInt() ?? 0;
              return DropdownMenuItem(
                value: doc.id,
                child: Text('${item['name'] ?? l.product} ($stock)'),
              );
            }).toList(),
            onChanged: saving ? null : (value) {
              if (value != null) setDialogState(() => selectedId = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  final fresh = await firestore.collection('products')
                      .doc(selectedId).get();
                  if (!fresh.exists || fresh.data()?['uid'] != uid) {
                    throw StateError('Product ownership changed.');
                  }
                  final current = fresh.data()!;
                  final profile = await firestore
                      .collection('business_profiles').doc(uid).get();
                  final businessName =
                      profile.data()?['businessName'] as String? ??
                      FirebaseAuth.instance.currentUser?.displayName ??
                      l.marketplaceSeller;
                  final listingRef =
                      firestore.collection('marketplace_listings').doc();
                  await listingRef.set({
                    'sellerUid': uid,
                    'sellerBusinessName': businessName,
                    'productId': selectedId,
                    'productName': current['name'] as String? ?? l.product,
                    'category': current['category'] as String? ?? '',
                    'price': (current['price'] as num?)?.toDouble() ?? 0,
                    'quantityAvailable':
                        (current['quantity'] as num?)?.toInt() ?? 0,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.marketplaceListingPublished)));
                  }
                } catch (_) {
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.marketplaceActionFailed)));
                }
              },
              child: Text(saving ? l.saving : l.marketplacePublish),
            ),
          ],
        );
      },
    ),
  );
}
