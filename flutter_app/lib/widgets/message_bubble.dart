import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _aiAvatar(cs),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.76,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? cs.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser ? null : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: isUser
                      ? Text(
                    message.content,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                  )
                      : MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      strong: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      code: TextStyle(
                        backgroundColor: cs.surfaceContainerHighest,
                        color: cs.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isUser && message.sources.isNotEmpty)
                  _sources(context, message.sources),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(fontSize: 10, color: cs.outline),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _userAvatar(cs),
        ],
      ),
    );
  }

  Widget _aiAvatar(ColorScheme cs) => CircleAvatar(
    radius: 16,
    backgroundColor: cs.primary,
    child: const Icon(Icons.shield, size: 16, color: Colors.white),
  );

  Widget _userAvatar(ColorScheme cs) => CircleAvatar(
    radius: 16,
    backgroundColor: cs.secondaryContainer,
    child: Icon(Icons.person, size: 16, color: cs.secondary),
  );

  Widget _sources(BuildContext context, List<SourceDocument> sources) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: sources.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 10, color: cs.primary),
              const SizedBox(width: 4),
              Text(s.source,
                  style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
