import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class MarketingWorkspaceScreen extends StatefulWidget {
  const MarketingWorkspaceScreen({super.key});

  @override
  State<MarketingWorkspaceScreen> createState() => _MarketingWorkspaceScreenState();
}

class _MarketingWorkspaceScreenState extends State<MarketingWorkspaceScreen> {
  final _name = TextEditingController();
  final _product = TextEditingController();
  final _goal = TextEditingController();
  final _budget = TextEditingController();
  final _audience = TextEditingController();
  String _channel = 'Facebook';
  bool _saving = false;

  static const _channels = ['Facebook', 'Instagram', 'TikTok', 'Telegram', 'WhatsApp', 'LinkedIn'];

  @override
  void dispose() {
    _name.dispose();
    _product.dispose();
    _goal.dispose();
    _budget.dispose();
    _audience.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Marketing workspace')),
        body: const Center(child: Text('Sign in to create and save marketing campaigns.')),
      );
    }
    final campaigns = FirebaseFirestore.instance.collection('marketing_campaigns')
        .where('uid', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Marketing workspace')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.blue, AppTheme.orange]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.campaign_outlined, color: Colors.white, size: 32),
              SizedBox(height: 10),
              Text('Plan, prepare and track campaigns',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('Create campaign briefs and save content plans before publishing.',
                style: TextStyle(color: Colors.white70, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('New campaign draft', style: TextStyle(
            color: AppTheme.navy, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _input(_name, 'Campaign name'),
          _input(_product, 'Product or service'),
          _input(_goal, 'Campaign goal (e.g. get 50 new customers)'),
          _input(_audience, 'Target audience', required: false),
          _input(_budget, 'Planned budget (ETB)', numeric: true, required: false),
          DropdownButtonFormField<String>(
            value: _channel,
            decoration: const InputDecoration(labelText: 'Primary channel', border: OutlineInputBorder()),
            items: _channels.map((channel) => DropdownMenuItem(value: channel, child: Text(channel))).toList(),
            onChanged: (value) => setState(() => _channel = value ?? 'Facebook'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : () => _saveCampaign(user.uid),
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving…' : 'Save campaign draft'),
          ),
          const SizedBox(height: 22),
          const Text('Your campaigns', style: TextStyle(
            color: AppTheme.navy, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: campaigns.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text('Could not load campaigns. Check Firestore rules.');
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) => (b.data()['createdAt'] as Timestamp?)?.compareTo(
                  (a.data()['createdAt'] as Timestamp?) ?? Timestamp(0, 0)) ?? 0);
              if (docs.isEmpty) return const Text('Your saved campaign drafts will appear here.');
              return Column(children: docs.map((doc) {
                final data = doc.data();
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
                    title: Text(data['name'] as String? ?? 'Campaign'),
                    subtitle: Text('${data['product'] ?? ''} · ${data['channel'] ?? ''}\nStatus: Draft',
                      maxLines: 2),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Delete draft',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => doc.reference.delete(),
                    ),
                  ),
                );
              }).toList());
            },
          ),
          const SizedBox(height: 16),
          const Text('Publishing status: Draft only. Connect official platform accounts and approve permissions before enabling automatic publishing.',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.4)),
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String label,
      {bool required = true, bool numeric = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    ),
  );

  Future<void> _saveCampaign(String uid) async {
    if (_name.text.trim().isEmpty || _product.text.trim().isEmpty || _goal.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a campaign name, product and goal.')),
      );
      return;
    }
    final budgetText = _budget.text.trim();
    final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);
    if (budgetText.isNotEmpty && (budget == null || budget < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid non-negative budget.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('marketing_campaigns').add({
        'uid': uid,
        'name': _name.text.trim(),
        'product': _product.text.trim(),
        'goal': _goal.text.trim(),
        'audience': _audience.text.trim(),
        'budgetETB': budget,
        'channel': _channel,
        'status': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _name.clear();
      _product.clear();
      _goal.clear();
      _audience.clear();
      _budget.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign draft saved.')),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save campaign. Check Firestore rules and connection.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
