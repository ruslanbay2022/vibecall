import 'package:flutter/material.dart';
import 'package:vibecall/l10n/app_localizations.dart';

String formatUnreadChatCount(int count) => count > 9 ? '9+' : '$count';

class ChatUnreadCountLabel extends StatelessWidget {
  final int count;

  const ChatUnreadCountLabel({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.chatUnreadBadge(count),
      child: CircleAvatar(
        radius: 10,
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          formatUnreadChatCount(count),
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ChatUnreadBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const ChatUnreadBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    final l10n = AppLocalizations.of(context);

    return Badge(
      label: Text(formatUnreadChatCount(count)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
      child: Semantics(
        label: l10n.chatUnreadBadge(count),
        child: child,
      ),
    );
  }
}
