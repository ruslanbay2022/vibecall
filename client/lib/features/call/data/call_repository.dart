import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/call/data/call_invitation_dto.dart';
import 'package:vibecall/features/call/data/call_token.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';

part 'call_repository.g.dart';

class CallBusyException implements Exception {
  final String message;
  CallBusyException([this.message = 'User is busy']);

  @override
  String toString() => 'CallBusyException: $message';
}

class CallRepositoryException implements Exception {
  final String message;
  final int? statusCode;
  CallRepositoryException(this.message, {this.statusCode});

  @override
  String toString() => 'CallRepositoryException($statusCode): $message';
}

abstract class CallRepository {
  String get currentUserId;
  Future<CallToken> startCall(String receiverId, {required bool hasVideo});
  Future<CallToken> acceptCall(String invitationId);
  Future<void> rejectCall(String invitationId);
  Future<void> cancelCall(String invitationId);
  Future<void> endCall(String invitationId, int durationSec);
  Stream<CallInvitation> incomingCallStream();
  Stream<CallInvitation> outgoingCallUpdates(String invitationId);
}

class SupabaseCallRepository implements CallRepository {
  final SupabaseClient _client;
  StreamController<CallInvitation>? _incomingController;
  RealtimeChannel? _incomingChannel;
  final Map<String, StreamController<CallInvitation>> _updateControllers = {};
  final Map<String, RealtimeChannel> _updateChannels = {};

  SupabaseCallRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  String get currentUserId => _client.auth.currentUser!.id;

  Future<CallToken> _invoke(String name, Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(name, body: body);
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw CallRepositoryException('Empty response');
      return CallToken.fromEdgeFunctionResponse(data);
    } on FunctionException catch (e) {
      if (e.status == 409) {
        final details = e.details is Map ? e.details as Map : {};
        throw CallBusyException(
          details['error'] as String? ?? 'User is busy',
        );
      }
      throw CallRepositoryException(
        e.reasonPhrase ?? 'Function error',
        statusCode: e.status,
      );
    }
  }

  @override
  Future<CallToken> startCall(String receiverId, {required bool hasVideo}) async {
    return _invoke('generate-call-token', {
      'receiverId': receiverId,
      'hasVideo': hasVideo,
    });
  }

  @override
  Future<CallToken> acceptCall(String invitationId) async {
    return _invoke('accept-call', {'invitationId': invitationId});
  }

  @override
  Future<void> rejectCall(String invitationId) async {
    try {
      await _client.functions.invoke(
        'reject-call',
        body: {'invitationId': invitationId},
      );
    } on FunctionException catch (e) {
      throw CallRepositoryException(
        e.reasonPhrase ?? 'Function error',
        statusCode: e.status,
      );
    }
  }

  @override
  Future<void> cancelCall(String invitationId) async {
    await _client
        .from('call_invitations')
        .update({'state': 'cancelled'})
        .eq('id', invitationId);
  }

  @override
  Future<void> endCall(String invitationId, int durationSec) async {
    try {
      await _client.functions.invoke(
        'end-call',
        body: {'invitationId': invitationId, 'durationSec': durationSec},
      );
    } on FunctionException catch (e) {
      throw CallRepositoryException(
        e.reasonPhrase ?? 'Function error',
        statusCode: e.status,
      );
    }
  }

  @override
  Stream<CallInvitation> incomingCallStream() {
    _incomingController?.close();
    _incomingChannel?.unsubscribe();

    final controller = StreamController<CallInvitation>.broadcast(
      onCancel: () {
        _incomingChannel?.unsubscribe();
        _incomingChannel = null;
        _incomingController = null;
      },
    );
    _incomingController = controller;

    final channel = _client.channel('calls:incoming:$currentUserId');
    _incomingChannel = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_invitations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final dto = CallInvitationDto.fromJson(
              Map<String, dynamic>.from(payload.newRecord),
            );
            controller.add(CallInvitation.fromDto(dto));
          },
        )
        .subscribe();

    return controller.stream;
  }

  @override
  Stream<CallInvitation> outgoingCallUpdates(String invitationId) {
    _updateControllers[invitationId]?.close();
    _updateChannels[invitationId]?.unsubscribe();

    final controller = StreamController<CallInvitation>.broadcast(
      onCancel: () {
        _updateChannels[invitationId]?.unsubscribe();
        _updateChannels.remove(invitationId);
        _updateControllers.remove(invitationId);
      },
    );
    _updateControllers[invitationId] = controller;

    final channel = _client.channel('calls:update:$invitationId');
    _updateChannels[invitationId] = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'call_invitations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: invitationId,
          ),
          callback: (payload) {
            final dto = CallInvitationDto.fromJson(
              Map<String, dynamic>.from(payload.newRecord),
            );
            controller.add(CallInvitation.fromDto(dto));
          },
        )
        .subscribe();

    return controller.stream;
  }
}

@Riverpod(keepAlive: true)
CallRepository callRepository(Ref ref) {
  return SupabaseCallRepository();
}
