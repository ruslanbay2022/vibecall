import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_controller.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class InCallChatSheet extends ConsumerStatefulWidget {
  final String conversationId;

  const InCallChatSheet({super.key, required this.conversationId});

  @override
  ConsumerState<InCallChatSheet> createState() => _InCallChatSheetState();
}

class _InCallChatSheetState extends ConsumerState<InCallChatSheet> {
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
    _scrollController.removeListener(_onScroll);
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
    final body = _inputController.text.trim();
    if (body.isEmpty) return;
    _inputController.clear();
    try {
      await ref
          .read(chatControllerProvider(widget.conversationId).notifier)
          .sendMessage(body);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncMessages = ref.watch(chatControllerProvider(widget.conversationId));

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(context),
              _buildHeader(context, l10n),
              const Divider(height: 1),
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
      },
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.callOpenChat,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
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
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 4),
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
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
