/// Human-readable label for a call peer (username, display name, or id fallback).
String formatCallPeerLabel({
  required String userId,
  String? username,
  String? displayName,
}) {
  final handle = username?.trim();
  if (handle != null && handle.isNotEmpty) {
    return '@$handle';
  }
  final name = displayName?.trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }
  return userId;
}
