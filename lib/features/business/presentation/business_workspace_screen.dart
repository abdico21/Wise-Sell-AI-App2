import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/business_profile_service.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../sales/presentation/sales_screen.dart';
import '../../customers/presentation/customers_screen.dart';

class BusinessWorkspaceScreen extends StatefulWidget {
  const BusinessWorkspaceScreen({super.key});

  @override
  State<BusinessWorkspaceScreen> createState() => _BusinessWorkspaceScreenState();
}

class _BusinessWorkspaceScreenState extends State<BusinessWorkspaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BusinessProfileService();
  final _businessName = TextEditingController();
  final _ownerName = TextEditingController();
  final _businessType = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController(text: 'Addis Ababa');
  final _country = TextEditingController(text: 'Ethiopia');

  bool _saving = false;
  bool _loaded = false;
  String? _error;

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _businessType.dispose();
    _phone.dispose();
    _city.dispose();
    _country.dispose();
    super.dispose();
  }

  void _loadProfile(BusinessProfile? profile) {
    if (_loaded || profile == null) return;
    _businessName.text = profile.businessName;
    _ownerName.text = profile.ownerName;
    _businessType.text = profile.businessType;
    _phone.text = profile.phone;
    _city.text = profile.city;
    _country.text = profile.country;
    _loaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.saveMyProfile(BusinessProfile(
        businessName: _businessName.text.trim(),
        ownerName: _ownerName.text.trim(),
        businessType: _businessType.text.trim(),
        phone: _phone.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile saved securely.')),
        );
      }
    } catch (_) {
      setState(() => _error =
          'Could not save your profile. Check your connection and Firestore rules.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business workspace')),
      body: StreamBuilder<BusinessProfile?>(
        stream: _service.watchMyProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load your business profile.'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          _loadProfile(snapshot.data);
          final hasProfile = snapshot.data != null;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 32),
                    SizedBox(height: 12),
                    Text('Your business, connected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        )),
                    SizedBox(height: 6),
                    Text(
                      'Save your business details to personalize your WiseSell workspace.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasProfile ? 'Edit business details' : 'Set up your business',
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(_businessName, 'Business name',
                        Icons.business_outlined),
                    _field(_ownerName, 'Owner / contact person',
                        Icons.person_outline),
                    _field(_businessType, 'Business type / industry',
                        Icons.category_outlined),
                    _field(_phone, 'Phone number', Icons.phone_outlined,
                        keyboard: TextInputType.phone),
                    _field(_city, 'City', Icons.location_city_outlined),
                    _field(_country, 'Country', Icons.public_outlined),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save business profile'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const BusinessDashboardScreen()),
                ),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Business performance dashboard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const InventoryScreen()),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Manage product inventory'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SalesScreen()),
                ),
                icon: const Icon(Icons.point_of_sale_outlined),
                label: const Text('Manage sales and orders'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CustomersScreen()),
                ),
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Manage customers (CRM)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your profile is stored under your signed-in account. Only that account should be allowed to read or edit it.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required field' : null,
      ),
    );
  }
}


class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business dashboard')),
        body: const Center(child: Text('Sign in to view business performance.')),
      );
    }

    final salesQuery = FirebaseFirestore.instance
        .collection('sales')
        .where('uid', isEqualTo: user.uid);
    final productsQuery = FirebaseFirestore.instance
        .collection('products')
        .where('uid', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Business performance')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: salesQuery.snapshots(),
        builder: (context, salesSnapshot) {
          if (salesSnapshot.hasError) {
            return const Center(child: Text('Could not load sales analytics. Check Firestore rules.'));
          }
          if (!salesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = salesSnapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              return (bTime?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
            });
          final revenue = sales.fold<double>(0, (sum, doc) =>
              sum + ((doc.data()['total'] as num?)?.toDouble() ?? 0));
          final units = sales.fold<int>(0, (sum, doc) =>
              sum + ((doc.data()['quantity'] as num?)?.toInt() ?? 0));
          final averageSale = sales.isEmpty ? 0.0 : revenue / sales.length;
          final now = DateTime.now();
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6));
          final dailyRevenue = List<double>.filled(7, 0);
          final productUnits = <String, int>{};
          for (final sale in sales) {
            final data = sale.data();
            final timestamp = data['createdAt'] as Timestamp?;
            if (timestamp != null) {
              final date = timestamp.toDate();
              final day = DateTime(date.year, date.month, date.day);
              final index = day.difference(weekStart).inDays;
              if (index >= 0 && index < 7) {
                dailyRevenue[index] += (data['total'] as num?)?.toDouble() ?? 0;
              }
            }
            final productName = data['productName'] as String? ?? 'Product';
            productUnits[productName] = (productUnits[productName] ?? 0) +
                ((data['quantity'] as num?)?.toInt() ?? 0);
          }
          final topProducts = productUnits.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final maxDaily = dailyRevenue.fold<double>(0,
              (maxValue, value) => value > maxValue ? value : maxValue);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: productsQuery.snapshots(),
            builder: (context, productsSnapshot) {
              if (productsSnapshot.hasError) {
                return const Center(child: Text('Could not load inventory analytics.'));
              }
              if (!productsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = productsSnapshot.data!.docs;
              final lowStock = products.where((doc) =>
                  ((doc.data()['quantity'] as num?)?.toInt() ?? 0) <= 5).toList();
              final stockUnits = products.fold<int>(0, (sum, doc) =>
                  sum + ((doc.data()['quantity'] as num?)?.toInt() ?? 0));
              final stockValue = products.fold<double>(0, (sum, doc) {
                final data = doc.data();
                return sum +
                    ((data['price'] as num?)?.toDouble() ?? 0) *
                    ((data['quantity'] as num?)?.toInt() ?? 0);
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your business at a glance',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('ETB ${revenue.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 27, fontWeight: FontWeight.w800)),
                        const Text('Total recorded sales revenue',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _dashboardMetric('Sales', '${sales.length}',
                        Icons.receipt_long_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _dashboardMetric('Units sold', '$units',
                        Icons.shopping_bag_outlined)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _dashboardMetric('Average sale',
                        'ETB ${averageSale.toStringAsFixed(0)}',
                        Icons.price_check_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _dashboardMetric('Products', '${products.length}',
                        Icons.inventory_2_outlined)),
                  ]),
                  const SizedBox(height: 10),
                  _dashboardMetric('Stock on hand',
                      '$stockUnits units • ETB ${stockValue.toStringAsFixed(2)}',
                      Icons.warehouse_outlined),
                  const SizedBox(height: 20),
                  const Text('Revenue • last 7 days',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                          color: AppTheme.navy)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) {
                          final day = weekStart.add(Duration(days: index));
                          final value = dailyRevenue[index];
                          final barHeight = maxDaily <= 0 ? 5.0 :
                              (value / maxDaily * 82).clamp(5.0, 82.0);
                          return Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(value == 0 ? '–' : value.toStringAsFixed(0),
                                    style: const TextStyle(fontSize: 9,
                                        color: Colors.blueGrey)),
                                const SizedBox(height: 5),
                                Container(
                                  height: barHeight,
                                  width: 17,
                                  decoration: BoxDecoration(
                                    color: AppTheme.blue,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(const ['M','T','W','T','F','S','S'][day.weekday - 1],
                                    style: const TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Top-selling products',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                          color: AppTheme.navy)),
                  const SizedBox(height: 8),
                  if (topProducts.isEmpty)
                    const Card(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Your top products will appear after you record sales.'),
                    ))
                  else
                    ...topProducts.take(5).map((entry) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.trending_up, color: AppTheme.blue),
                        title: Text(entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: Text('${entry.value} units',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    )),
                  const SizedBox(height: 18),
                  Row(children: [
                    const Expanded(child: Text('Low-stock alerts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppTheme.navy))),
                    if (lowStock.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('${lowStock.length} items',
                            style: TextStyle(color: Colors.orange.shade900,
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  if (lowStock.isEmpty)
                    const Card(child: ListTile(
                      leading: Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text('No low-stock products'),
                      subtitle: Text('All tracked products have more than 5 units.'),
                    ))
                  else
                    ...lowStock.map((doc) {
                      final data = doc.data();
                      final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber_rounded,
                              color: Colors.deepOrange),
                          title: Text(data['name'] as String? ?? 'Product'),
                          trailing: Text('$quantity left',
                              style: const TextStyle(color: Colors.deepOrange,
                                  fontWeight: FontWeight.w800)),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text('Analytics are calculated from your recorded WiseSell sales and inventory. They are not external market forecasts.',
                      style: TextStyle(color: Colors.blueGrey.shade600,
                          fontSize: 12)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _dashboardMetric(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Icon(icon, color: AppTheme.blue, size: 23),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11,
                color: Colors.blueGrey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w800)),
          ])),
      ]),
    ),
  );
}
