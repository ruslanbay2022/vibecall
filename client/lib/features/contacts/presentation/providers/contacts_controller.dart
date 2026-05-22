import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';

part 'contacts_controller.g.dart';

@riverpod
class ContactsController extends _$ContactsController {
  @override
  Future<List<ContactDto>> build() async {
    final repo = ref.watch(contactsRepositoryProvider);
    final accepted = await repo.listAccepted();
    final incoming = await repo.listIncomingRequests();
    final outgoing = await repo.listOutgoingRequests();
    return [...accepted, ...incoming, ...outgoing];
  }
}
