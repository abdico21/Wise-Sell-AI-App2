import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/business_profile_service.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../sales/presentation/sales_screen.dart';

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
