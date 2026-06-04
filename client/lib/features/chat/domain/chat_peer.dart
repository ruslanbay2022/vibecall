class ChatPeer {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const ChatPeer({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });
}
