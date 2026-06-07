import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:vibecall/features/call/domain/call_outcome.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/call/presentation/providers/in_call_conversation_id.dart';
import 'package:vibecall/features/call/presentation/widgets/call_hud.dart';
import 'package:vibecall/features/call/presentation/widgets/call_media_utils.dart';
import 'package:vibecall/features/call/presentation/widgets/in_call_chat_sheet.dart';
import 'package:vibecall/features/chat/presentation/providers/in_call_open_chat.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: switch (callState) {
        CallStateConnecting _ => _ConnectingView(l10n: l10n),
        CallStateOutgoing s => _OutgoingView(
          receiverId: s.receiverId,
          l10n: l10n,
        ),
        CallStateActive s => _ActiveView(state: s),
        CallStateEnded s => _EndedView(state: s, l10n: l10n),
        CallStateError s => _ErrorView(message: s.message, l10n: l10n),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _ConnectingView extends StatelessWidget {
  final AppLocalizations l10n;

  const _ConnectingView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.callConnecting),
        ],
      ),
    );
  }
}

class _OutgoingView extends ConsumerWidget {
  final String receiverId;
  final AppLocalizations l10n;

  const _OutgoingView({required this.receiverId, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 48,
            child: Icon(Icons.person, size: 48),
          ),
          const SizedBox(height: 16),
          Text(l10n.callOutgoing(receiverId)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ref.read(callControllerProvider.notifier).cancel(),
            icon: const Icon(Icons.call_end),
            label: Text(l10n.callCancelButton),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ActiveView extends ConsumerStatefulWidget {
  final CallStateActive state;

  const _ActiveView({required this.state});

  @override
  ConsumerState<_ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends ConsumerState<_ActiveView> {
  final List<CancelListenFunc> _mediaListeners = [];
  bool _chatOpen = false;

  @override
  void initState() {
    super.initState();
    _subscribeRoomMedia(widget.state.room);
  }

  @override
  void didUpdateWidget(covariant _ActiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state.room, widget.state.room)) {
      _unsubscribeRoomMedia();
      _subscribeRoomMedia(widget.state.room);
    } else if (oldWidget.state.mediaTick != widget.state.mediaTick) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _unsubscribeRoomMedia();
    super.dispose();
  }

  void _subscribeRoomMedia(Room room) {
    void refresh(_) {
      if (mounted) setState(() {});
    }

    _mediaListeners.addAll([
      room.events.on<LocalTrackPublishedEvent>(refresh),
      room.events.on<LocalTrackUnpublishedEvent>(refresh),
      room.events.on<TrackPublishedEvent>(refresh),
      room.events.on<TrackUnpublishedEvent>(refresh),
      room.events.on<TrackMutedEvent>(refresh),
      room.events.on<TrackUnmutedEvent>(refresh),
    ]);
  }

  void _unsubscribeRoomMedia() {
    for (final cancel in _mediaListeners) {
      cancel();
    }
    _mediaListeners.clear();
  }

  void _toggleChat(String conversationId) {
    final opening = !_chatOpen;
    setState(() => _chatOpen = opening);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (opening) {
        ref.read(inCallOpenChatProvider.notifier).set(conversationId);
        ref
            .read(unreadCountsControllerProvider.notifier)
            .clearForConversation(conversationId);
      } else {
        ref.read(inCallOpenChatProvider.notifier).set(null);
        unawaited(ref.read(unreadCountsControllerProvider.notifier).refresh());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callControllerProvider);
    final active = callState is CallStateActive ? callState : widget.state;
    final asyncConvId = ref.watch(inCallConversationIdProvider);
    final conversationId = asyncConvId.value;

    final remoteTrack = active.hasVideo
        ? participantCameraTrack(active.peer)
        : null;
    final localTrack = active.hasVideo
        ? participantCameraTrack(active.room.localParticipant)
        : null;

    return Stack(
      children: [
        if (remoteTrack != null)
          Positioned.fill(
            child: VideoTrackRenderer(
              key: ValueKey('remote-${remoteTrack.sid}'),
              remoteTrack,
              fit: VideoViewFit.cover,
            ),
          )
        else
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircleAvatar(
                  radius: 64,
                  child: Icon(Icons.person, size: 64),
                ),
              ),
            ),
          ),
        if (localTrack != null)
          Positioned(
            top: 48,
            right: 16,
            width: 120,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoTrackRenderer(
                key: ValueKey('local-${localTrack.sid}'),
                localTrack,
                fit: VideoViewFit.cover,
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CallHud(
            state: active,
            chatOpen: _chatOpen,
            conversationId: conversationId,
            onToggleChat: conversationId != null
                ? () => _toggleChat(conversationId)
                : null,
          ),
        ),
        if (_chatOpen && conversationId != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: callHudReservedHeight(context),
            child: InCallChatSheet(conversationId: conversationId),
          ),
      ],
    );
  }
}

class _EndedView extends ConsumerWidget {
  final CallStateEnded state;
  final AppLocalizations l10n;

  const _EndedView({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationStr = _formatDuration(state.durationSec);
    final outcomeLabel = _outcomeLabel(state.outcome, l10n);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.call_end, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(outcomeLabel, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            durationStr,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => ref.read(callControllerProvider.notifier).resetToIdle(),
            child: Text(l10n.callEndedClose),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _outcomeLabel(CallOutcome outcome, AppLocalizations l10n) {
    return switch (outcome) {
      CallOutcome.accepted => l10n.callOutcomeAccepted,
      CallOutcome.rejected => l10n.callOutcomeRejected,
      CallOutcome.missed => l10n.callOutcomeMissed,
      CallOutcome.cancelled => l10n.callOutcomeCancelled,
      CallOutcome.busy => l10n.callOutcomeBusy,
      CallOutcome.timeout => l10n.callOutcomeTimeout,
    };
  }
}

class _ErrorView extends ConsumerWidget {
  final String message;
  final AppLocalizations l10n;

  const _ErrorView({required this.message, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(callControllerProvider.notifier).resetToIdle(),
              child: Text(l10n.callEndedClose),
            ),
          ],
        ),
      ),
    );
  }
}
