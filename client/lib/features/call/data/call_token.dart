import 'package:vibecall/app/env.dart';

class CallToken {
  final String token;
  final String wsUrl;
  final String roomName;

  CallToken({
    required this.token,
    required this.wsUrl,
    required this.roomName,
  });

  factory CallToken.fromEdgeFunctionResponse(Map<String, dynamic> json) =>
      CallToken(
        token: json['token'] as String,
        wsUrl: json['wsUrl'] as String? ?? Env.livekitWsUrl,
        roomName: json['roomName'] as String,
      );
}
