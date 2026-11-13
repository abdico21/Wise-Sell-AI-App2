import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: AppTheme.blue),
            SizedBox(width: 10),
            Text('WiseSell AI', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.navy, AppTheme.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR BUSINESS,\nSMARTER', style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  )),
                  SizedBox(height: 10),
                  Text(
                    'Manage sales, customers and social commerce from one place.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text('Business workspace', style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy,
            )),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FeatureTile(icon: Icons.auto_awesome, title: 'AI Assistant', detail: 'Business insights'),
                _FeatureTile(icon: Icons.shopping_bag_outlined, title: 'Marketplace', detail: 'Products & orders'),
                _FeatureTile(icon: Icons.campaign_outlined, title: 'Marketing', detail: 'Social campaigns'),
                _FeatureTile(icon: Icons.inventory_2_outlined, title: 'Inventory', detail: 'Stock management'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Getting started', style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy,
            )),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch_outlined, color: AppTheme.teal, size: 30),
                    SizedBox(width: 14),
                    Expanded(child: Text(
                      'Your mobile foundation is ready. Connect your account to unlock your workspace.',
                      style: TextStyle(height: 1.4),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Market'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'AI Studio'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.blue, size: 27),
              const SizedBox(height: 13),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(detail, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
