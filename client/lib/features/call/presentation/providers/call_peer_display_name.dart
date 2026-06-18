import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/presentation/widgets/call_peer_display.dart';
import 'package:vibecall/features/profile/data/profile_repository.dart';

part 'call_peer_display_name.g.dart';

@riverpod
Future<String> callPeerDisplayName(Ref ref, String userId) async {
  if (userId.isEmpty) return userId;

  final profile = await ProfileRepository().getProfile(userId);
  return formatCallPeerLabel(
    userId: userId,
    username: profile?['username'] as String?,
    displayName: profile?['display_name'] as String?,
  );
}
