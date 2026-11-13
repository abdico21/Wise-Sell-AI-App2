import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer CRM')),
        body: const Center(child: Text('Sign in to manage customers.')),
      );
    }

    final customersQuery = FirebaseFirestore.instance
        .collection('customers')
        .where('uid', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer CRM')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerEditor(context, user.uid),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add customer'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: customersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load customers. Check Firestore rules.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allCustomers = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aDate = a.data()['updatedAt'] as Timestamp?;
              final bDate = b.data()['updatedAt'] as Timestamp?;
              return (bDate?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
            });
          final customers = allCustomers.where((doc) {
            if (_search.isEmpty) return true;
            final data = doc.data();
            final searchable = [
              data['name'],
              data['company'],
              data['phone'],
              data['email'],
            ].whereType<String>().join(' ').toLowerCase();
            return searchable.contains(_search);
          }).toList();

          final withEmail =
              allCustomers.where((doc) => (doc.data()['email'] as String? ?? '').isNotEmpty).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Customers',
                      '${allCustomers.length}',
                      Icons.people_alt_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryCard(
                      'With email',
                      '$withEmail',
                      Icons.mark_email_read_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search name, company, phone or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _search.isEmpty ? 'Your customers' : 'Search results',
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (customers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        _search.isEmpty
                            ? Icons.people_outline
                            : Icons.search_off,
                        size: 48,
                        color: AppTheme.blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _search.isEmpty
                            ? 'No customers yet'
                            : 'No matching customers',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _search.isEmpty
                            ? 'Add your first customer to start building relationships.'
                            : 'Try another name, company, phone or email.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...customers.map((doc) {
                  final data = doc.data();
                  final name = data['name'] as String? ?? 'Customer';
                  final company = data['company'] as String? ?? '';
                  final phone = data['phone'] as String? ?? '';
                  final email = data['email'] as String? ?? '';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F1FF),
                        child: Text(
                          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text([
                        if (company.isNotEmpty) company,
                        if (phone.isNotEmpty) phone,
                        if (email.isNotEmpty) email,
                      ].join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
                      isThreeLine: company.isNotEmpty && phone.isNotEmpty && email.isNotEmpty,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showCustomerEditor(
                              context,
                              user.uid,
                              docId: doc.id,
                              initial: data,
                            );
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

  Widget _summaryCard(String label, String value, IconData icon) => Card(
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

  Future<void> _showCustomerEditor(
    BuildContext context,
    String uid, {
    String? docId,
    Map<String, dynamic>? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: initial?['name'] as String? ?? '');
    final company = TextEditingController(text: initial?['company'] as String? ?? '');
    final phone = TextEditingController(text: initial?['phone'] as String? ?? '');
    final email = TextEditingController(text: initial?['email'] as String? ?? '');
    final notes = TextEditingController(text: initial?['notes'] as String? ?? '');
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(docId == null ? 'Add customer' : 'Edit customer'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _editorField(name, 'Customer name', required: true),
                  _editorField(company, 'Company / organization', required: false),
                  _editorField(
                    phone,
                    'Phone number',
                    required: false,
                    keyboard: TextInputType.phone,
                  ),
                  _editorField(
                    email,
                    'Email address',
                    required: false,
                    keyboard: TextInputType.emailAddress,
                  ),
                  _editorField(
                    notes,
                    'Notes',
                    required: false,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        final collection =
                            FirebaseFirestore.instance.collection('customers');
                        final payload = <String, dynamic>{
                          'uid': uid,
                          'name': name.text.trim(),
                          'company': company.text.trim(),
                          'phone': phone.text.trim(),
                          'email': email.text.trim(),
                          'notes': notes.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                          if (docId == null)
                            'createdAt': FieldValue.serverTimestamp(),
                        };
                        if (docId == null) {
                          await collection.add(payload);
                        } else {
                          await collection.doc(docId).update(payload);
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                docId == null
                                    ? 'Customer added.'
                                    : 'Customer updated.',
                              ),
                            ),
                          );
                        }
                      } catch (_) {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not save customer. Check your connection and Firestore rules.',
                            ),
                          ),
                        );
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Save customer'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    company.dispose();
    phone.dispose();
    email.dispose();
    notes.dispose();
  }

  Widget _editorField(
    TextEditingController controller,
    String label, {
    required bool required,
    TextInputType? keyboard,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) return 'Required field';
            if (label == 'Email address' &&
                text.isNotEmpty &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
      );

  Future<void> _confirmDelete(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: const Text('This removes the customer record from your CRM.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await reference.delete();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete customer.')),
          );
        }
      }
    }
  }
}
