import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/domain/call_history_entry.dart';
import 'package:vibecall/features/call/domain/call_outcome.dart';
import 'package:vibecall/features/call/presentation/providers/call_history_controller.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  CallHistoryFilter _filter = CallHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncEntries = ref.watch(callHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.callHistoryTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<CallHistoryFilter>(
              segments: [
                ButtonSegment(
                  value: CallHistoryFilter.all,
                  label: Text(l10n.callHistoryTabAll),
                  icon: const Icon(Icons.list),
                ),
                ButtonSegment(
                  value: CallHistoryFilter.missed,
                  label: Text(l10n.callHistoryTabMissed),
                  icon: const Icon(Icons.phone_missed),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                final newFilter = selection.first;
                setState(() => _filter = newFilter);
                ref
                    .read(callHistoryControllerProvider.notifier)
                    .setFilter(newFilter);
              },
            ),
          ),
          Expanded(
            child: asyncEntries.when(
              data: (entries) => _buildList(context, entries, _filter),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, st) => _buildError(context, e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<CallHistoryEntry> entries,
    CallHistoryFilter filter,
  ) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Text(
          filter == CallHistoryFilter.missed
              ? l10n.callHistoryMissedEmpty
              : l10n.callHistoryEmpty,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(callHistoryControllerProvider.notifier).refresh(),
      child: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _CallHistoryTile(entry: entry);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.callHistoryError),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () =>
                ref.read(callHistoryControllerProvider.notifier).refresh(),
            child: Text(l10n.callHistoryRetry),
          ),
        ],
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  final CallHistoryEntry entry;
  const _CallHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final outcomeStyle = _outcomeStyle(context, entry.outcome);
    final directionIcon = entry.isOutgoing
        ? const Icon(Icons.call_made, size: 14)
        : const Icon(Icons.call_received, size: 14);
    final typeIcon = entry.hasVideo
        ? const Icon(Icons.videocam, size: 14)
        : const Icon(Icons.phone, size: 14);
    final timeText = _formatTime(context, entry.startedAt);
    final subtitleParts = <String>[
      '${entry.outcome.label(l10n)} \u00b7 $timeText',
    ];
    if (entry.outcome == CallOutcome.accepted) {
      subtitleParts.add(
        l10n.callHistoryDuration(_two(entry.durationSec ~/ 60), _two(entry.durationSec % 60)),
      );
    }

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          entry.peer.avatarUrl != null
              ? CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(entry.peer.avatarUrl!),
                )
              : const CircleAvatar(child: Icon(Icons.person)),
          Positioned(
            bottom: -2,
            right: -2,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: theme.colorScheme.surface,
              child: Icon(
                outcomeStyle.icon,
                size: 14,
                color: outcomeStyle.color,
              ),
            ),
          ),
        ],
      ),
      title: Text(entry.displayName.isEmpty ? entry.peer.id : entry.displayName),
      subtitle: Text(subtitleParts.join(' \u00b7 ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          directionIcon,
          const SizedBox(width: 4),
          typeIcon,
        ],
      ),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  String _formatTime(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final mo = _two(local.month);
    final d = _two(local.day);
    final h = _two(local.hour);
    final mi = _two(local.minute);
    return '$y-$mo-$d $h:$mi';
  }

  _OutcomeStyle _outcomeStyle(BuildContext context, CallOutcome outcome) {
    final scheme = Theme.of(context).colorScheme;
    switch (outcome) {
      case CallOutcome.accepted:
        return const _OutcomeStyle(Icons.call, Colors.green);
      case CallOutcome.missed:
      case CallOutcome.timeout:
        return const _OutcomeStyle(Icons.phone_missed, Colors.red);
      case CallOutcome.rejected:
        return const _OutcomeStyle(Icons.call_end, Colors.orange);
      case CallOutcome.cancelled:
        return _OutcomeStyle(Icons.phone_disabled, scheme.outline);
      case CallOutcome.busy:
        return const _OutcomeStyle(Icons.phone_locked, Colors.amber);
    }
  }
}

class _OutcomeStyle {
  final IconData icon;
  final Color color;
  const _OutcomeStyle(this.icon, this.color);
}

extension _OutcomeLabel on CallOutcome {
  String label(AppLocalizations l10n) {
    switch (this) {
      case CallOutcome.accepted:
        return l10n.callOutcomeAccepted;
      case CallOutcome.missed:
        return l10n.callOutcomeMissed;
      case CallOutcome.rejected:
        return l10n.callOutcomeRejected;
      case CallOutcome.cancelled:
        return l10n.callOutcomeCancelled;
      case CallOutcome.busy:
        return l10n.callOutcomeBusy;
      case CallOutcome.timeout:
        return l10n.callOutcomeTimeout;
    }
  }
}
