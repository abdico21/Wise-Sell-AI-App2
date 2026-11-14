import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AgentHubScreen extends StatelessWidget {
  const AgentHubScreen({super.key});

  static const _agents = <_AgentInfo>[
    _AgentInfo(Icons.business_center_outlined, 'Business Assistant', 'Coordinates the other agents, answers business questions and turns results into an action plan.'),
    _AgentInfo(Icons.campaign_outlined, 'Digital Marketing', 'Plans campaigns, audiences, budgets and channel performance.'),
    _AgentInfo(Icons.edit_note_rounded, 'Content Marketing', 'Creates product descriptions, articles, captions, calendars and localized content.'),
    _AgentInfo(Icons.search_rounded, 'SEO', 'Keyword research, technical checks, on-page recommendations and search performance.'),
    _AgentInfo(Icons.share_outlined, 'Social Media Marketing', 'Plans channel-specific posts, publishing schedules, community replies and analytics.'),
    _AgentInfo(Icons.movie_creation_outlined, 'Video & Audio Marketing', 'Creates scripts, storyboards, voice-over briefs, short-video concepts and audio campaigns.'),
    _AgentInfo(Icons.inventory_2_outlined, 'Inventory Management', 'Tracks stock, low-stock risks, product movement and replenishment suggestions.'),
  ];

  static const _channels = <String>[
    'WhatsApp', 'Telegram', 'Facebook', 'Instagram', 'TikTok', 'LinkedIn', 'YouTube',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiseSell AI Agent Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.blue, AppTheme.orange]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('One connected business team', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text('Agents share approved business context and hand work to one another. The Business Assistant coordinates tasks and brings the results together.', style: TextStyle(color: Colors.white, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Your AI agents', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy)),
          const SizedBox(height: 10),
          ..._agents.map((agent) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              leading: CircleAvatar(backgroundColor: AppTheme.blue.withValues(alpha: .10), child: Icon(agent.icon, color: AppTheme.blue)),
              title: Text(agent.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(agent.description)),
              trailing: const Icon(Icons.lock_clock_outlined, color: AppTheme.orange),
            ),
          )),
          const SizedBox(height: 18),
          const Text('Social and video channels', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _channels.map((name) => Chip(
            avatar: const Icon(Icons.link_rounded, size: 16),
            label: Text(name),
            side: BorderSide(color: AppTheme.blue.withValues(alpha: .25)),
          )).toList()),
          const SizedBox(height: 8),
          const Text('Channel connections require each platform’s approved API, account authorization and permissions. This screen is a roadmap; it does not publish posts or send messages yet.', style: TextStyle(color: Colors.blueGrey, height: 1.4)),
          const SizedBox(height: 18),
          const Text('Ethiopian languages', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy)),
          const SizedBox(height: 8),
          const Text('Language rollout target: Amharic, Afaan Oromo, Tigrinya, Somali, Afar and English. The existing app localization foundation currently includes English, Amharic, Afaan Oromo, Tigrinya and Somali; Afar and complete agent-level language support remain to be added.', style: TextStyle(height: 1.45)),
          const SizedBox(height: 18),
          Card(
            color: AppTheme.orange.withValues(alpha: .08),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: AppTheme.orange),
                SizedBox(width: 10),
                Expanded(child: Text('Agent services, shared orchestration, media generation and social publishing still need secure backend/API implementation. No platform credentials are stored in the mobile app.', style: TextStyle(height: 1.4))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentInfo {
  const _AgentInfo(this.icon, this.name, this.description);
  final IconData icon;
  final String name;
  final String description;
}
