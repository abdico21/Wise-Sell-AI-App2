import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onLocaleChanged, super.key});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: AppTheme.blue),
            const SizedBox(width: 10),
            Text(l.appTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          PopupMenuButton<Locale>(
            tooltip: l.language,
            icon: const Icon(Icons.language_rounded),
            onSelected: onLocaleChanged,
            itemBuilder: (context) => [
              PopupMenuItem(value: const Locale('en'), child: Text(l.english)),
              PopupMenuItem(value: const Locale('am'), child: Text(l.amharic)),
              PopupMenuItem(value: const Locale('om'), child: Text(l.afaanOromo)),
              PopupMenuItem(value: const Locale('ti'), child: Text(l.tigrinya)),
              PopupMenuItem(value: const Locale('so'), child: Text(l.somali)),
            ],
          ),
          IconButton(
            tooltip: l.notifications,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.yourBusinessSmarter, style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  )),
                  const SizedBox(height: 10),
                  Text(l.heroDescription,
                    style: const TextStyle(color: Colors.white70, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(l.businessWorkspace, style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy,
            )),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FeatureTile(icon: Icons.auto_awesome, title: l.aiAssistant, detail: l.businessInsights),
                _FeatureTile(icon: Icons.shopping_bag_outlined, title: l.marketplace, detail: l.productsOrders),
                _FeatureTile(icon: Icons.campaign_outlined, title: l.marketing, detail: l.socialCampaigns),
                _FeatureTile(icon: Icons.inventory_2_outlined, title: l.inventory, detail: l.stockManagement),
              ],
            ),
            const SizedBox(height: 24),
            Text(l.gettingStarted, style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy,
            )),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch_outlined, color: AppTheme.teal, size: 30),
                    const SizedBox(width: 14),
                    Expanded(child: Text(l.foundationReady,
                      style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: l.home),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined), label: l.market),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: l.aiStudio),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l.profile),
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
