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

class WebCallTabCoordinator implements CallTabCoordinator {
  final String _tabId;
  final JsBroadcastChannel _channel;
  final _dismissController = StreamController<String>.broadcast();
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

    _postMsg({
      'type': 'claim',
      'invitationId': invitationId,
      'tabId': _tabId,
      'ts': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    await Future.delayed(const Duration(milliseconds: 200));

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

    final type = parsed['type'];
    if (type == 'dismiss' && parsed['invitationId'] is String) {
      final invId = parsed['invitationId'] as String;
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
