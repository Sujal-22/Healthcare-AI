import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final String _sessionId = const Uuid().v4();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _checkingHealth = true;
  String _statusText = 'Connecting…';
  bool _statusOk = false;

  // Bento card suggestions
  static const _suggestions = [
    ('search_insights', 'Analyze new symptoms',
    'What are the symptoms of diabetes?'),
    ('medication', 'Explain my medication',
    'What does ibuprofen do and when should I take it?'),
    ('sync_problem', 'Check drug interactions',
    'Are there interactions between aspirin and blood pressure medication?'),
  ];

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    final h = await _chatService.checkHealth();
    if (!mounted) return;
    setState(() {
      _checkingHealth = false;
      if (h['status'] == 'unreachable') {
        _statusText = 'Backend offline — start FastAPI server';
        _statusOk = false;
      } else if (h['ollama_connected'] == false) {
        _statusText = 'Ollama not running — run: ollama serve';
        _statusOk = false;
      } else if (h['vector_db_ready'] == false) {
        _statusText = 'No data loaded — tap ⚙ to ingest';
        _statusOk = false;
      } else {
        _statusText = 'Secure local processing active';
        _statusOk = true;
      }
    });
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        id: const Uuid().v4(),
        content: text,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _inputCtrl.clear();
    });
    _scrollBottom();

    try {
      final res = await _chatService.sendMessage(
          message: text, sessionId: _sessionId);
      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          content: res['answer'] as String,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          sources: res['sources'] as List<SourceDocument>,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          content: '❌ ${e.toString().replaceAll('Exception: ', '')}',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollBottom();
    }
  }

  void _scrollBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });

  @override
  void dispose() {
    _chatService.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _buildAppBar(cs),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(cs)
                : _buildMessageList(),
          ),
          _buildDisclaimer(cs),
          _buildInputBar(cs),
        ],
      ),
    );
  }

  // ── App bar ──
  PreferredSizeWidget _buildAppBar(ColorScheme cs) => PreferredSize(
    preferredSize: const Size.fromHeight(64),
    child: Container(
      color: cs.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.shield, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              const Text(
                'HealthAI Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              // Status pill
              if (!_checkingHealth)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _statusOk
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _statusOk ? 'Secure · Local' : 'Setup needed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  context.watch<ThemeProvider>().isDarkMode? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
                  color: Colors.white,
                  size: 22,),
                  onPressed: () =>
                  context.read<ThemeProvider>().toggleTheme(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  ),
            ],
          ),
        ),
      ),
    ),
  );

  // ── Empty / home state with bento cards ──
  Widget _buildEmptyState(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Column(
        children: [
          // Hero icon + title
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
            ),
            child: Icon(Icons.shield_outlined, size: 36, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Private Health AI Assistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ask questions about symptoms, conditions, and medications.\nAnswers come from your own health data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.outline,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // Status pill
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _statusOk
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _checkingHealth ? 'Connecting…' : _statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Bento cards
          ...List.generate(_suggestions.length, (i) {
            final (icon, title, query) = _suggestions[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BentoCard(
                icon: icon,
                title: title,
                onTap: () => _send(query),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Message list ──
  Widget _buildMessageList() => ListView.builder(
    controller: _scrollCtrl,
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: _messages.length + (_isLoading ? 1 : 0),
    itemBuilder: (_, i) {
      if (i == _messages.length && _isLoading) {
        return const TypingIndicator();
      }
      return MessageBubble(message: _messages[i]);
    },
  );

  // ── Disclaimer bar ──
  Widget _buildDisclaimer(ColorScheme cs) => Container(
    color: const Color(0xFFFFF8E7),
    padding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    child: const Row(
      children: [
        Icon(Icons.lock_outline,
            size: 11, color: Color(0xFF92400E)),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            'For informational use only. Always consult a medical professional.',
            style: TextStyle(
                fontSize: 10,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  // ── Input bar ──
  Widget _buildInputBar(ColorScheme cs) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.9),
          border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -2))
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  onSubmitted: (_) => _send(),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  style:
                      TextStyle(color: cs.onSurface, fontSize: 15, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Ask about symptoms, conditions…',
                    hintStyle: TextStyle(color: cs.outline, fontSize: 15),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 13),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: GestureDetector(
                  onTap: _isLoading ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          _isLoading ? cs.primary.withValues(alpha: 0.4) : cs.primary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: _isLoading
                          ? []
                          : [
                              BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Bento card widget ──
class _BentoCard extends StatefulWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  const _BentoCard(
      {required this.icon, required this.title, required this.onTap});
  @override
  State<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<_BentoCard> {
  bool _hovered = false;

  static IconData _icon(String name) {
    switch (name) {
      case 'search_insights':
        return Icons.search;
      case 'medication':
        return Icons.medication_outlined;
      case 'sync_problem':
        return Icons.warning_amber_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? cs.primary : cs.outlineVariant.withValues(alpha: 0.6),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
              BoxShadow(
                  color: cs.primary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ]
                : [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _hovered
                      ? cs.primary
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon(widget.icon),
                  size: 24,
                  color: _hovered ? Colors.white : cs.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to ask →',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.outline),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

