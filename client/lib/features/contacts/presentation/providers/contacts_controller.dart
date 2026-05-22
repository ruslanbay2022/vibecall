import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';

part 'contacts_controller.g.dart';

@riverpod
class ContactsController extends _$ContactsController {
  RealtimeChannel? _channel;

  @override
  Future<List<ContactDto>> build() async {
    _channel?.unsubscribe();
    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    final repo = ref.watch(contactsRepositoryProvider);
    final userId = repo.currentUserId;
    final accepted = await repo.listAccepted();
    final incoming = await repo.listIncomingRequests();
    final outgoing = await repo.listOutgoingRequests();

    final supabase = Supabase.instance.client;
    _channel = supabase.channel('contacts:$userId');
    _channel!
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'contacts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => ref.invalidateSelf(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'contacts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'contact_id',
          value: userId,
        ),
        callback: (_) => ref.invalidateSelf(),
      )
      .subscribe();

    return [...accepted, ...incoming, ...outgoing];
  }
}
