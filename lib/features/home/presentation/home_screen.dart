import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../business/presentation/business_workspace_screen.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../sales/presentation/sales_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'feature_status_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.onLocaleChanged, super.key});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pages = <Widget>[
      _buildHome(context, l),
      const FeatureStatusScreen(
        title: 'Marketplace',
        description: 'Product discovery, buyer and seller storefronts, and marketplace orders.',
        plannedItems: ['Seller storefronts', 'Product listings and search', 'Buyer enquiries and orders'],
      ),
      const FeatureStatusScreen(
        title: 'AI Studio',
        description: 'The AI assistant experience is not connected in this mobile foundation yet.',
        plannedItems: ['Business questions and insights', 'Sales and expense analysis', 'AI-generated business recommendations'],
      ),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SvgPicture.asset('assets/branding/wisesell_app_icon.svg', width: 38, height: 38),
                  ),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.appTitle, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                      const Text('Sell Smarter · Grow Bigger', style: TextStyle(fontSize: 9, color: AppTheme.orange, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Account',
                  onPressed: () => _open(const AuthScreen()),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
                PopupMenuButton<Locale>(
                  tooltip: l.language,
                  icon: const Icon(Icons.language_rounded),
                  onSelected: widget.onLocaleChanged,
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
                  onPressed: () => _open(const FeatureStatusScreen(
                    title: 'Notifications',
                    description: 'Notifications are not configured in this foundation build.',
                    plannedItems: ['Order updates', 'Low-stock alerts', 'Business reminders'],
                  )),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          pages[0],
          pages[1],
          pages[2],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            _open(const AuthScreen());
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: l.home),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined), label: l.market),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: l.aiStudio),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l.profile),
        ],
      ),
    );
  }

  Widget _buildHome(BuildContext context, AppLocalizations l) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.navy, AppTheme.blue, AppTheme.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.yourBusinessSmarter, style: const TextStyle(
                  color: Colors.white, fontSize: 25, height: 1.15,
                  fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 10),
                Text(l.heroDescription, style: const TextStyle(color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(children: [
              Expanded(child: Container(height: 5, color: AppTheme.green)),
              Expanded(child: Container(height: 5, color: AppTheme.yellow)),
              Expanded(child: Container(height: 5, color: AppTheme.red)),
            ]),
          ),
          const SizedBox(height: 20),
          Text(l.businessWorkspace, style: const TextStyle(
            fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy,
          )),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FeatureTile(icon: Icons.auto_awesome, title: l.aiAssistant,
                detail: l.businessInsights, onTap: () => _open(const FeatureStatusScreen(
                  title: 'AI Business Assistant',
                  description: 'The AI assistant is not yet connected to an AI service in this build.',
                  plannedItems: ['Ask business questions', 'Analyze sales and expenses', 'Get business recommendations'],
                ))),
              _FeatureTile(icon: Icons.shopping_bag_outlined, title: l.marketplace,
                detail: l.productsOrders, onTap: () => setState(() => _selectedIndex = 1)),
              _FeatureTile(icon: Icons.campaign_outlined, title: l.marketing,
                detail: l.socialCampaigns, onTap: () => _open(const FeatureStatusScreen(
                  title: 'Sales and Marketing',
                  description: 'Campaign creation and social-network publishing are not active in this build.',
                  plannedItems: ['Product descriptions and ad copy', 'Campaign planning', 'Social channel integrations'],
                ))),
              _FeatureTile(icon: Icons.inventory_2_outlined, title: l.inventory,
                detail: l.stockManagement, onTap: () => _open(const InventoryScreen())),
              _FeatureTile(icon: Icons.point_of_sale_outlined, title: 'Sales',
                detail: 'Record sales and view revenue', onTap: () => _open(const SalesScreen())),
              _FeatureTile(icon: Icons.people_outline, title: 'Customers',
                detail: 'Manage your customer list', onTap: () => _open(const CustomersScreen())),
              _FeatureTile(icon: Icons.business_outlined, title: 'Business profile',
                detail: 'Set up your business workspace', onTap: () => _open(const BusinessWorkspaceScreen())),
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
                  const Icon(Icons.rocket_launch_outlined, color: AppTheme.orange, size: 30),
                  const SizedBox(width: 14),
                  Expanded(child: Text(
                    'Your mobile foundation is connected. Open the available business tools below; AI, marketplace and marketing services still need implementation.',
                    style: const TextStyle(height: 1.4),
                  )),
                ],
              ),
            ),
          ),
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.blue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
