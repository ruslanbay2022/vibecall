import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/call/presentation/providers/call_peer_display_name.dart';

/// Resolves [userId] to @username / display name for call UI strings.
class CallPeerNameText extends ConsumerWidget {
  const CallPeerNameText({
    super.key,
    required this.userId,
    required this.labelBuilder,
    this.style,
    this.textAlign,
  });

  final String userId;
  final String Function(String peerLabel) labelBuilder;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(callPeerDisplayNameProvider(userId));

    return nameAsync.when(
      data: (name) => Text(
        labelBuilder(name),
        style: style,
        textAlign: textAlign,
      ),
      loading: () => Text(
        labelBuilder('…'),
        style: style,
        textAlign: textAlign,
      ),
      error: (error, _) => Text(
        labelBuilder(userId),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
