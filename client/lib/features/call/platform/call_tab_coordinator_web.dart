import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';

abstract class CallTabCoordinator {
  bool get isLeader;

  Future<bool> tryBecomeLeader(String invitationId);

  void postDismiss(String invitationId);

  Stream<String> get onDismiss;

  void dispose();
}

@JS('BroadcastChannel')
@staticInterop
class JsBroadcastChannel {
  external factory JsBroadcastChannel(String name);
}

extension JsBroadcastChannelExt on JsBroadcastChannel {
  external void postMessage(JSAny? message);
  external void close();
  external void addEventListener(JSString type, JSFunction listener);
}

@JS()
@staticInterop
class JsMessageEvent {}

extension JsMessageEventExt on JsMessageEvent {
  external JSAny? get data;
}

class _ElectionState {
  final List<Map<String, dynamic>> claims = [];
  bool externalRing = false;
}

class WebCallTabCoordinator implements CallTabCoordinator {
  final String _tabId;
  final JsBroadcastChannel _channel;
  final _dismissController = StreamController<String>.broadcast();
  final _pendingElections = <String, _ElectionState>{};
  bool _isLeader = false;
  String? _activeInvitationId;

  WebCallTabCoordinator()
      : _tabId = _generateTabId(),
        _channel = JsBroadcastChannel('vibecall-call') {
    _channel.addEventListener('message'.toJS, _onMessage.toJS);
  }

  static String _generateTabId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';

  @override
  bool get isLeader => _isLeader;

  @override
  Future<bool> tryBecomeLeader(String invitationId) async {
    if (_isLeader && _activeInvitationId == invitationId) return true;

    final election = _ElectionState();
    _pendingElections[invitationId] = election;

    _postMsg({
      'type': 'claim',
      'invitationId': invitationId,
      'tabId': _tabId,
      'ts': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    await Future.delayed(const Duration(milliseconds: 200));

    _pendingElections.remove(invitationId);

    if (election.externalRing) return false;

    election.claims.add({
      'tabId': _tabId,
      'ts': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final unique = <String, Map<String, dynamic>>{};
    for (final c in election.claims) {
      unique[c['tabId'] as String] = c;
    }
    final sorted = unique.values.toList()
      ..sort((a, b) => (a['tabId'] as String).compareTo(b['tabId'] as String));

    if (sorted.isEmpty || sorted.first['tabId'] != _tabId) return false;

    _isLeader = true;
    _activeInvitationId = invitationId;

    _postMsg({
      'type': 'ring',
      'invitationId': invitationId,
      'tabId': _tabId,
    });

    return true;
  }

  @override
  Stream<String> get onDismiss => _dismissController.stream;

  @override
  void postDismiss(String invitationId) {
    _postMsg({'type': 'dismiss', 'invitationId': invitationId});
  }

  void _onMessage(JSAny? rawEvent) {
    if (rawEvent == null) return;
    final evt = rawEvent as JsMessageEvent;
    final raw = evt.data;
    final str = raw?.dartify();
    if (str is! String) return;
    final parsed = jsonDecode(str) as Map<String, dynamic>;

    final type = parsed['type'] as String?;
    final invId = parsed['invitationId'] as String?;
    final tabId = parsed['tabId'] as String?;

    if (type == null || invId == null) return;

    if (type == 'claim' && tabId != null) {
      _pendingElections[invId]?.claims.add(parsed);
      return;
    }

    if (type == 'ring' && tabId != null && tabId != _tabId) {
      _pendingElections[invId]?.externalRing = true;
      if (_isLeader && _activeInvitationId == invId) {
        _isLeader = false;
        _activeInvitationId = null;
      }
      return;
    }

    if (type == 'dismiss') {
      _dismissController.add(invId);
      if (_activeInvitationId == invId) {
        _isLeader = false;
        _activeInvitationId = null;
      }
    }
  }

  void _postMsg(Map<String, dynamic> data) {
    _channel.postMessage(jsonEncode(data).toJS);
  }

  @override
  void dispose() {
    _channel.close();
    _dismissController.close();
  }
}

CallTabCoordinator createCallTabCoordinator() => WebCallTabCoordinator();
