import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final listings = FirebaseFirestore.instance.collection('product_listings')
        .where('status', isEqualTo: 'active');

    return Scaffold(
      appBar: AppBar(
        title: const Text('WiseSell Marketplace'),
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Create listing',
              onPressed: () => _createListing(context, user.uid),
              icon: const Icon(Icons.add_business_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products or categories',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: listings.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text(
                    'Marketplace could not load. Check your internet connection and Firestore rules.',
                    textAlign: TextAlign.center,
                  ));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final term = _search.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final text = '${data['title'] ?? ''} ${data['category'] ?? ''} ${data['city'] ?? ''}'.toLowerCase();
                  return term.isEmpty || text.contains(term);
                }).toList();
                if (docs.isEmpty) {
                  return _empty(context, user?.uid);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final price = (data['price'] as num?)?.toDouble() ?? 0;
                    final owner = data['sellerUid'] as String? ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFFE8F1FF),
                                child: Icon(Icons.shopping_bag_outlined, color: AppTheme.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['title'] as String? ?? 'Product',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  Text('${data['category'] ?? 'General'} · ${data['city'] ?? 'Ethiopia'}',
                                    style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                                ],
                              )),
                              Text('ETB ${price.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.blue)),
                            ]),
                            if ((data['description'] as String? ?? '').isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(data['description'] as String),
                            ],
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: Text('Seller: ${data['sellerName'] ?? 'WiseSell seller'}',
                                style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
                              if (user != null && user.uid != owner)
                                FilledButton.tonal(
                                  onPressed: () => _sendEnquiry(doc.id, data, user.uid),
                                  child: const Text('Contact seller'),
                                ),
                              if (user != null && user.uid == owner)
                                const Chip(label: Text('Your listing')),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createListing(context, user.uid),
              icon: const Icon(Icons.add),
              label: const Text('Sell a product'),
            ),
    );
  }

  Widget _empty(BuildContext context, String? uid) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.storefront_outlined, size: 56, color: AppTheme.blue),
        const SizedBox(height: 12),
        const Text('Marketplace is ready for listings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.navy)),
        const SizedBox(height: 8),
        const Text('No matching products yet. Sellers can publish a listing to get started.',
          textAlign: TextAlign.center),
        if (uid != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _createListing(context, uid),
            icon: const Icon(Icons.add),
            label: const Text('Create first listing'),
          ),
        ],
      ]),
    ),
  );

  Future<void> _createListing(BuildContext context, String uid) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final category = TextEditingController();
    final price = TextEditingController();
    final city = TextEditingController(text: 'Jimma');
    final seller = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? '');
    final key = GlobalKey<FormState>();
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create marketplace listing'),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(title, 'Product or service title'),
                _field(description, 'Description', required: false, lines: 3),
                _field(category, 'Category'),
                _field(price, 'Price in ETB', numeric: true),
                _field(city, 'City / location'),
                _field(seller, 'Seller or business name'),
                const SizedBox(height: 4),
                const Text('Publishing makes this listing visible to signed-in WiseSell users.',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (!key.currentState!.validate()) return;
                setDialogState(() => saving = true);
                try {
                  await FirebaseFirestore.instance.collection('product_listings').add({
                    'sellerUid': uid,
                    'sellerName': seller.text.trim(),
                    'title': title.text.trim(),
                    'description': description.text.trim(),
                    'category': category.text.trim(),
                    'price': double.parse(price.text.trim()),
                    'city': city.text.trim(),
                    'status': 'active',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (_) {
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not publish listing. Check Firestore rules and connection.')),
                  );
                }
              },
              child: Text(saving ? 'Publishing…' : 'Publish listing'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    category.dispose();
    price.dispose();
    city.dispose();
    seller.dispose();
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = true, bool numeric = false, int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'Required';
        if (numeric && (double.tryParse(text) == null || double.parse(text) < 0)) return 'Enter a valid price';
        return null;
      },
    ),
  );

  Future<void> _sendEnquiry(String listingId, Map<String, dynamic> listing, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('marketplace_enquiries').add({
        'listingId': listingId,
        'sellerUid': listing['sellerUid'],
        'buyerUid': uid,
        'listingTitle': listing['title'],
        'message': 'I am interested in this listing. Please contact me.',
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enquiry sent to the seller.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send enquiry. Please try again.')),
        );
      }
    }
  }
}
