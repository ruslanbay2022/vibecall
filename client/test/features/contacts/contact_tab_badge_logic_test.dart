import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';
import 'package:vibecall/features/contacts/domain/contact_lists.dart';

ContactDto contact({
  required String id,
  required String userId,
  required String contactId,
  required String status,
}) {
  return ContactDto(
    id: id,
    userId: userId,
    contactId: contactId,
    status: status,
  );
}

void main() {
  const me = 'user-a';

  group('partitionContacts', () {
    test('splits accepted, incoming and outgoing', () {
      final all = [
        contact(
          id: '1',
          userId: me,
          contactId: 'b',
          status: 'accepted',
        ),
        contact(
          id: '2',
          userId: 'c',
          contactId: me,
          status: 'pending',
        ),
        contact(
          id: '3',
          userId: me,
          contactId: 'd',
          status: 'pending',
        ),
      ];
      final partitioned = partitionContacts(all, me);
      expect(partitioned.accepted.map((c) => c.id), ['1']);
      expect(partitioned.incoming.map((c) => c.id), ['2']);
      expect(partitioned.outgoing.map((c) => c.id), ['3']);
    });
  });

  group('unseenContactCount', () {
    test('counts only ids not in seen set', () {
      final contacts = [
        contact(
          id: '1',
          userId: me,
          contactId: 'b',
          status: 'pending',
        ),
        contact(
          id: '2',
          userId: me,
          contactId: 'c',
          status: 'pending',
        ),
      ];
      expect(unseenContactCount(contacts, {'1'}), 1);
      expect(unseenContactCount(contacts, {'1', '2'}), 0);
      expect(unseenContactCount(contacts, {}), 2);
    });
  });
}
