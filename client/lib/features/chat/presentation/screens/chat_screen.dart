import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_controller.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_message_sound.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? peerName;
  final String? peerAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.peerName,
    this.peerAvatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loadOlderInFlight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadOlderInFlight) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 100) return;
    _loadOlderInFlight = true;
    ref
        .read(chatControllerProvider(widget.conversationId).notifier)
        .loadOlder()
        .whenComplete(() {
      if (mounted) _loadOlderInFlight = false;
    });
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final body = _inputController.text.trim();
    if (body.isEmpty) return;
    _inputController.clear();
    try {
      await ref
          .read(chatControllerProvider(widget.conversationId).notifier)
          .sendMessage(body);
    } catch (_) {
      if (!mounted) return;
      _inputController.text = body;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatSendError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncMessages = ref.watch(chatControllerProvider(widget.conversationId));
    final isTyping = ref.watch(chatTypingIndicatorProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName ?? widget.conversationId),
      ),
      body: Column(
        children: [
          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.chatTyping(widget.peerName ?? ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ),
          Expanded(
            child: asyncMessages.when(
              data: (messages) => _buildMessages(context, messages, l10n),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => _buildError(context, e, l10n),
            ),
          ),
          _buildInputBar(context, l10n),
        ],
      ),
    );
  }

  Widget _buildMessages(
      BuildContext context, List<Message> messages, AppLocalizations l10n) {
    if (messages.isEmpty) {
      return Center(child: Text(l10n.chatEmpty));
    }
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _MessageBubble(message: message);
      },
    );
  }

  Widget _buildError(
      BuildContext context, Object error, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.chatLoadError),
          const SizedBox(height: 8),
          Text(error.toString(), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => ref.invalidate(
              chatControllerProvider(widget.conversationId),
            ),
            child: Text(l10n.chatRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.chatAttachStub)),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                onTap: () {
                  unawaited(
                    ref
                        .read(chatMessageSoundProvider.notifier)
                        .unlockForNextSound(),
                  );
                },
                onChanged: (_) {
                  ref
                      .read(
                          chatControllerProvider(widget.conversationId).notifier)
                      .onTextChanged();
                },
                decoration: InputDecoration(
                  hintText: l10n.chatInputHint,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.chatVoiceStub)),
                );
              },
            ),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: _send,
              tooltip: l10n.chatSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.isFromMe;
    final bgColor = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fgColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.body,
          style: TextStyle(color: fgColor),
        ),
      ),
    );
  }
}
