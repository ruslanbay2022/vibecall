import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/call/data/call_history_dto.dart';
import 'package:vibecall/features/call/data/call_invitation_dto.dart';
import 'package:vibecall/features/call/data/call_token.dart';
import 'package:vibecall/features/call/domain/call_history_entry.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';

part 'call_repository.g.dart';

enum CallHistoryFilter { all, missed }

const incomingMissedHistoryOutcomes = ['missed', 'timeout', 'cancelled'];

/// Invitation states that should dismiss callee incoming UI (not [accepted]).
const incomingCallDismissStates = {
  'cancelled',
  'rejected',
  'missed',
  'timeout',
  'busy',
};

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
  Stream<String> incomingCallDismissStream();
  Stream<CallInvitation> outgoingCallUpdates(String invitationId);
  Future<List<CallHistoryEntry>> fetchCallHistory({
    CallHistoryFilter filter = CallHistoryFilter.all,
  });
}

class SupabaseCallRepository implements CallRepository {
  final SupabaseClient _client;
  StreamController<CallInvitation>? _incomingController;
  RealtimeChannel? _incomingChannel;
  StreamController<String>? _incomingDismissController;
  RealtimeChannel? _incomingDismissChannel;
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
  Future<List<CallHistoryEntry>> fetchCallHistory({
    CallHistoryFilter filter = CallHistoryFilter.all,
  }) async {
    final userId = currentUserId;
    final columns = 'id, room_name, caller_id, receiver_id, outcome, '
        'has_video, duration_sec, started_at, ended_at, '
        'caller:profiles!call_history_caller_id_fkey('
        'username, display_name, avatar_url), '
        'receiver:profiles!call_history_receiver_id_fkey('
        'username, display_name, avatar_url)';

    var query = _client.from('call_history').select(columns);

    if (filter == CallHistoryFilter.missed) {
      query = query
          .eq('receiver_id', userId)
          .inFilter('outcome', incomingMissedHistoryOutcomes);
    } else {
      query = query.or('caller_id.eq.$userId,receiver_id.eq.$userId');
    }

    final response = await query.order('started_at', ascending: false);
    final list = response as List;
    return list
        .map((e) =>
            CallHistoryDto.fromJson(e as Map<String, dynamic>).toDomain(
              currentUserId: userId,
            ))
        .toList();
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
            final dto = CallInvitationDto.fromRealtime(
              Map<String, dynamic>.from(payload.newRecord),
            );
            controller.add(CallInvitation.fromDto(dto));
          },
        )
        .subscribe();

    return controller.stream;
  }

  @override
  Stream<String> incomingCallDismissStream() {
    _incomingDismissController?.close();
    _incomingDismissChannel?.unsubscribe();

    final controller = StreamController<String>.broadcast(
      onCancel: () {
        _incomingDismissChannel?.unsubscribe();
        _incomingDismissChannel = null;
        _incomingDismissController = null;
      },
    );
    _incomingDismissController = controller;

    final channel = _client.channel('calls:incoming-dismiss:$currentUserId');
    _incomingDismissChannel = channel;

    void emitDismiss(String? id) {
      if (id != null && id.isNotEmpty) controller.add(id);
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'call_invitations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final record = Map<String, dynamic>.from(payload.newRecord);
            final state = record['state'] as String?;
            if (state != null && incomingCallDismissStates.contains(state)) {
              emitDismiss(record['id'] as String?);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'call_invitations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final record = Map<String, dynamic>.from(payload.oldRecord);
            emitDismiss(record['id'] as String?);
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

    void emitInvitation(Map<String, dynamic> record) {
      try {
        final dto = CallInvitationDto.fromRealtime(record);
        controller.add(CallInvitation.fromDto(dto));
      } catch (_) {
        // Malformed or incomplete Realtime payload — safe to ignore.
      }
    }

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
            emitInvitation(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'call_invitations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: invitationId,
          ),
          callback: (payload) {
            final record = Map<String, dynamic>.from(payload.oldRecord);
            record['id'] ??= invitationId;
            // Some Realtime DELETE payloads omit state; row was removed after terminal UPDATE.
            record['state'] ??= 'cancelled';
            emitInvitation(record);
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
