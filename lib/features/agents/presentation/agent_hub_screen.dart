import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/wisesell_ai_service.dart';

class AgentHubScreen extends StatefulWidget {
  const AgentHubScreen({super.key});

  @override
  State<AgentHubScreen> createState() => _AgentHubScreenState();
}

class _AgentHubScreenState extends State<AgentHubScreen> {
  static const _apiBaseUrl = String.fromEnvironment(
    'WISESELL_API_BASE_URL',
    defaultValue: 'https://wise-sell-ai-app2.abdico-veiws22.workers.dev',
  );

  static const _agents = <_AgentInfo>[
    _AgentInfo(Icons.business_center_outlined, 'Business Assistant', 'business', 'Coordinates specialist agents and turns advice into a business action plan.'),
    _AgentInfo(Icons.campaign_outlined, 'Digital Marketing', 'marketing', 'Campaign plans, audiences, budgets and measurable KPIs.'),
    _AgentInfo(Icons.edit_note_rounded, 'Content Marketing', 'content', 'Product descriptions, articles, captions and content calendars.'),
    _AgentInfo(Icons.search_rounded, 'SEO', 'seo', 'Keyword themes, search intent and practical website SEO advice.'),
    _AgentInfo(Icons.share_outlined, 'Social Media Marketing', 'social', 'Channel-specific post drafts, replies and publishing calendars.'),
    _AgentInfo(Icons.movie_creation_outlined, 'Video & Audio Marketing', 'video', 'Scripts, storyboards, voice-over copy and audio concepts.'),
    _AgentInfo(Icons.inventory_2_outlined, 'Inventory Management', 'inventory', 'Stock analysis and replenishment suggestions from supplied data.'),
  ];

  static const _languages = <String>[
    'English', 'Amharic', 'Afaan Oromo', 'Tigrinya', 'Somali'
  ];

  final _promptController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  String _selectedAgent = 'business';
  String _language = 'English';
  bool _busy = false;

  _AgentInfo get _agent => _agents.firstWhere((agent) => agent.id == _selectedAgent);

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final prompt = _promptController.text.trim();
    if (prompt.length < 3 || _busy) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before using WiseSell AI.')),
      );
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(prompt, true));
      _busy = true;
    });
    _promptController.clear();
    _scrollToBottom();

    try {
      final answer = await WiseSellAiService.generate(
        agent: _selectedAgent,
        prompt: prompt,
        language: _language,
      );
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(answer, false)));
    } on WiseSellAiException catch (error) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(error.message, false)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.add(const _ChatMessage(
        'Could not connect to WiseSell AI. Check your internet connection and try again.',
        false,
      )));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiseSell AI Agent Workspace')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.navy, AppTheme.blue, AppTheme.orange],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your connected AI business team',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Choose an agent, describe your business task and get an actionable response.',
                      style: TextStyle(color: Colors.white, height: 1.4)),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: _agents.map((agent) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    avatar: Icon(agent.icon, size: 17),
                    label: Text(agent.name),
                    selected: _selectedAgent == agent.id,
                    onSelected: _busy ? null : (_) => setState(() => _selectedAgent = agent.id),
                  ),
                )).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(child: Text(_agent.description, style: const TextStyle(color: Colors.blueGrey, fontSize: 12))),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: _languages.map((language) => DropdownMenuItem(
                      value: language, child: Text(language, style: const TextStyle(fontSize: 12)),
                    )).toList(),
                    onChanged: _busy ? null : (value) {
                      if (value != null) setState(() => _language = value);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_busy ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 10),
                                Text('WiseSell AI is thinking…'),
                              ]),
                            ),
                          );
                        }
                        return _MessageBubble(message: _messages[index]);
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 8, offset: const Offset(0, -2)),
              ]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask your business question…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.blue, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('AI drafts and recommendations · Cloudflare AI free-plan limits apply',
                  style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: AppTheme.orange),
            const SizedBox(height: 12),
            const Text('What would you like to grow today?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.navy)),
            const SizedBox(height: 8),
            const Text('Try one of these prompts. Include accurate business details for more useful advice.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 18),
            _suggestion('Create a 7-day marketing plan for my shop.'),
            _suggestion('Write an Amharic and English product description.'),
            _suggestion('How can I improve my website SEO?'),
            _suggestion('Review my stock list and identify items to reorder.'),
          ],
        ),
      ),
    );
  }

  Widget _suggestion(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ActionChip(
      label: Text(value),
      onPressed: _busy ? null : () {
        _promptController.text = value;
        _promptController.selection = TextSelection.collapsed(offset: value.length);
      },
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .86),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: user ? AppTheme.blue : const Color(0xFFF0F3F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(color: user ? Colors.white : AppTheme.navy, height: 1.4),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class _AgentInfo {
  const _AgentInfo(this.icon, this.name, this.id, this.description);
  final IconData icon;
  final String name;
  final String id;
  final String description;
}

