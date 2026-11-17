import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class AgentHubScreen extends StatefulWidget {
  const AgentHubScreen({required this.onLocaleChanged, super.key});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<AgentHubScreen> createState() => _AgentHubScreenState();
}

class _AgentHubScreenState extends State<AgentHubScreen> {
  static const _apiBaseUrl = String.fromEnvironment(
    'WISESELL_API_BASE_URL',
    defaultValue: 'https://wisesell-ai-api.iamabdu3.workers.dev',
  );

  static const _agents = <_AgentInfo>[
    _AgentInfo(Icons.business_center_outlined, 'business'),
    _AgentInfo(Icons.campaign_outlined, 'marketing'),
    _AgentInfo(Icons.edit_note_rounded, 'content'),
    _AgentInfo(Icons.search_rounded, 'seo'),
    _AgentInfo(Icons.share_outlined, 'social'),
    _AgentInfo(Icons.movie_creation_outlined, 'video'),
    _AgentInfo(Icons.inventory_2_outlined, 'inventory'),
  ];

  final _promptController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  String _selectedAgent = 'business';
  bool _busy = false;

  _AgentInfo get _agent => _agents.firstWhere((agent) => agent.id == _selectedAgent);

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    final requestLanguage = _languageForCode(Localizations.localeOf(context).languageCode);
    final prompt = _promptController.text.trim();
    if (prompt.length < 3 || _busy) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.agentPleaseSignIn)),
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
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw _AgentRequestException(l.agentSessionExpired);
      }
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/v1/agent'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'agent': _selectedAgent,
          'prompt': prompt,
          'language': requestLanguage,
        }),
      ).timeout(const Duration(seconds: 50));

      Map<String, dynamic> data = {};
      try {
        data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      } catch (_) {
        throw _AgentRequestException(l.agentUnreadableResponse);
      }

      if (response.statusCode == 200) {
        final answer = data['answer'] as String? ?? l.agentNoAnswer;
        if (!mounted) return;
        setState(() => _messages.add(_ChatMessage(answer, false)));
      } else {
        final message = data['error'] as String? ?? l.agentRequestFailed;
        throw _AgentRequestException(
          response.statusCode == 401
              ? l.agentSignInAgain
              : response.statusCode == 503
                  ? l.agentCapacityUnavailable
                  : message,
        );
      }
    } on _AgentRequestException catch (error) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(error.message, false)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(
        l.agentConnectionError,
        false,
      )));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToBottom();
      }
    }
  }

  String _languageForCode(String code) => switch (code) {
    'am' => 'Amharic',
    'om' => 'Afaan Oromo',
    'ti' => 'Tigrinya',
    'so' => 'Somali',
    _ => 'English',
  };

  String _agentName(String id, AppLocalizations l) => switch (id) {
    'marketing' => l.agentDigitalMarketing,
    'content' => l.agentContentMarketing,
    'seo' => l.agentSeo,
    'social' => l.agentSocialMediaMarketing,
    'video' => l.agentVideoAudioMarketing,
    'inventory' => l.agentInventoryManagement,
    _ => l.agentBusinessAssistant,
  };

  String _agentDescription(String id, AppLocalizations l) => switch (id) {
    'marketing' => l.agentDigitalMarketingDescription,
    'content' => l.agentContentMarketingDescription,
    'seo' => l.agentSeoDescription,
    'social' => l.agentSocialMediaDescription,
    'video' => l.agentVideoAudioDescription,
    'inventory' => l.agentInventoryDescription,
    _ => l.agentBusinessAssistantDescription,
  };

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
    final l = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l.agentWorkspaceTitle)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.agentHeroTitle,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text(l.agentHeroDescription,
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
                    label: Text(_agentName(agent.id, l)),
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
                  Expanded(child: Text(_agentDescription(_agent.id, l), style: const TextStyle(color: Colors.blueGrey, fontSize: 12))),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: localeCode,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(l.english, style: const TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'am', child: Text(l.amharic, style: const TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'om', child: Text(l.afaanOromo, style: const TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'ti', child: Text(l.tigrinya, style: const TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'so', child: Text(l.somali, style: const TextStyle(fontSize: 12))),
                    ],
                    onChanged: _busy ? null : (value) {
                      if (value != null) widget.onLocaleChanged(Locale(value));
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcome(l)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_busy ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                const SizedBox(width: 10),
                                Text(l.agentThinking),
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
                      decoration: InputDecoration(
                        hintText: l.agentPromptHint,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l.agentFooter,
                  style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(AppLocalizations l) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: AppTheme.orange),
            const SizedBox(height: 12),
            Text(l.agentWelcomeTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.navy)),
            const SizedBox(height: 8),
            Text(l.agentWelcomeDescription,
                textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 18),
            _suggestion(l.agentSuggestionMarketing),
            _suggestion(l.agentSuggestionProduct),
            _suggestion(l.agentSuggestionSeo),
            _suggestion(l.agentSuggestionInventory),
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
  const _AgentInfo(this.icon, this.id);
  final IconData icon;
  final String id;
}

class _AgentRequestException implements Exception {
  const _AgentRequestException(this.message);
  final String message;
}
