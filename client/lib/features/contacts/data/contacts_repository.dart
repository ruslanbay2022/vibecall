import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'contacts_repository.g.dart';

class ContactDto {
  final String id;
  final String userId;
  final String contactId;
  final String status;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  ContactDto({
    required this.id,
    required this.userId,
    required this.contactId,
    required this.status,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory ContactDto.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ContactDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contactId: json['contact_id'] as String,
      status: json['status'] as String,
      username: profile?['username'] as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}

abstract class ContactsRepository {
  Future<List<ContactDto>> listAccepted();
  Future<List<ContactDto>> listIncomingRequests();
  Future<List<ContactDto>> listOutgoingRequests();
  Future<void> sendRequest(String contactId);
  Future<void> acceptRequest(String id, String otherUserId);
  Future<void> rejectRequest(String id);
  Future<void> remove(String id, String otherUserId);
  Future<void> block(String id);
  String get currentUserId;
}

class SupabaseContactsRepository implements ContactsRepository {
  final SupabaseClient _client;

  SupabaseContactsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  String get currentUserId => _client.auth.currentUser!.id;

  @override
  Future<List<ContactDto>> listAccepted() async {
    final response = await _client
        .from('contacts')
        .select(
            'id, user_id, contact_id, status, created_at, profiles!contacts_contact_id_fkey(username, display_name, avatar_url)')
        .eq('user_id', currentUserId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => ContactDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ContactDto>> listIncomingRequests() async {
    final response = await _client
        .from('contacts')
        .select(
            'id, user_id, contact_id, status, created_at, profiles!contacts_user_id_fkey(username, display_name, avatar_url)')
        .eq('contact_id', currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => ContactDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ContactDto>> listOutgoingRequests() async {
    final response = await _client
        .from('contacts')
        .select(
            'id, user_id, contact_id, status, created_at, profiles!contacts_contact_id_fkey(username, display_name, avatar_url)')
        .eq('user_id', currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => ContactDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> sendRequest(String contactId) async {
    await _client.from('contacts').insert({
      'user_id': currentUserId,
      'contact_id': contactId,
      'status': 'pending',
    });
  }

  @override
  Future<void> acceptRequest(String id, String otherUserId) async {
    await _client
        .from('contacts')
        .update({'status': 'accepted'}).eq('id', id);
    final existing = await _client
        .from('contacts')
        .select('id')
        .eq('user_id', currentUserId)
        .eq('contact_id', otherUserId)
        .maybeSingle();
    if (existing == null) {
      await _client.from('contacts').insert({
        'user_id': currentUserId,
        'contact_id': otherUserId,
        'status': 'accepted',
      });
    }
  }

  @override
  Future<void> rejectRequest(String id) async {
    await _client.from('contacts').delete().eq('id', id);
  }

  @override
  Future<void> remove(String id, String otherUserId) async {
    await _client.from('contacts').delete().eq('id', id);
    await _client
        .from('contacts')
        .delete()
        .eq('user_id', currentUserId)
        .eq('contact_id', otherUserId);
  }

  @override
  Future<void> block(String id) async {
    await _client
        .from('contacts')
        .update({'status': 'blocked'}).eq('id', id);
  }
}

@Riverpod(keepAlive: true)
ContactsRepository contactsRepository(Ref ref) {
  return SupabaseContactsRepository();
}
