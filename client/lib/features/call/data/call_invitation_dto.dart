class CallInvitationDto {
  final String id;
  final String roomName;
  final String callerId;
  final String receiverId;
  final bool hasVideo;
  final String state;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? endedAt;

  CallInvitationDto({
    required this.id,
    required this.roomName,
    required this.callerId,
    required this.receiverId,
    required this.hasVideo,
    required this.state,
    required this.createdAt,
    required this.expiresAt,
    this.endedAt,
  });

  factory CallInvitationDto.fromJson(Map<String, dynamic> json) {
    return CallInvitationDto(
      id: json['id'] as String,
      roomName: json['room_name'] as String,
      callerId: json['caller_id'] as String,
      receiverId: json['receiver_id'] as String,
      hasVideo: json['has_video'] as bool,
      state: json['state'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }

  /// Realtime DELETE [oldRecord] may omit non-key columns even with REPLICA IDENTITY FULL.
  factory CallInvitationDto.fromRealtime(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final state = json['state'] as String?;
    if (id == null || state == null) {
      throw FormatException('invitation realtime payload missing id or state');
    }
    final createdAt = json['created_at'] as String?;
    final expiresAt = json['expires_at'] as String?;
    return CallInvitationDto(
      id: id,
      roomName: json['room_name'] as String? ?? '',
      callerId: json['caller_id'] as String? ?? '',
      receiverId: json['receiver_id'] as String? ?? '',
      hasVideo: json['has_video'] as bool? ?? false,
      state: state,
      createdAt:
          createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
      expiresAt:
          expiresAt != null ? DateTime.parse(expiresAt) : DateTime.now(),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }
}
