import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';

void main() {
  test('ContactDto.fromJson parses profile data correctly', () {
    final json = {
      'id': 'contact-id-1',
      'user_id': 'user-a',
      'contact_id': 'user-b',
      'status': 'accepted',
      'profiles': {
        'username': 'alice',
        'display_name': 'Alice Smith',
        'avatar_url': 'https://example.com/avatar.jpg',
      },
    };

    final dto = ContactDto.fromJson(json);

    expect(dto.id, 'contact-id-1');
    expect(dto.userId, 'user-a');
    expect(dto.contactId, 'user-b');
    expect(dto.status, 'accepted');
    expect(dto.username, 'alice');
    expect(dto.displayName, 'Alice Smith');
    expect(dto.avatarUrl, 'https://example.com/avatar.jpg');
  });

  test('ContactDto.fromJson handles null profile', () {
    final json = {
      'id': 'contact-id-2',
      'user_id': 'user-a',
      'contact_id': 'user-b',
      'status': 'pending',
    };

    final dto = ContactDto.fromJson(json);

    expect(dto.id, 'contact-id-2');
    expect(dto.status, 'pending');
    expect(dto.username, isNull);
    expect(dto.displayName, isNull);
    expect(dto.avatarUrl, isNull);
  });
}
