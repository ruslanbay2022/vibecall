abstract class CallTabCoordinator {
  bool get isLeader;

  Future<bool> tryBecomeLeader(String invitationId);

  void postDismiss(String invitationId);

  Stream<String> get onDismiss;

  void dispose();
}

class StubCallTabCoordinator implements CallTabCoordinator {
  @override
  bool get isLeader => true;

  @override
  Future<bool> tryBecomeLeader(String invitationId) async => true;

  @override
  void postDismiss(String invitationId) {}

  @override
  Stream<String> get onDismiss => const Stream.empty();

  @override
  void dispose() {}
}

CallTabCoordinator createCallTabCoordinator() => StubCallTabCoordinator();
