import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'search_repository.g.dart';

class SearchUserDto {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  SearchUserDto({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory SearchUserDto.fromJson(Map<String, dynamic> json) {
    return SearchUserDto(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

abstract class SearchRepository {
  Future<List<SearchUserDto>> searchUsers(String q);
}

class SupabaseSearchRepository implements SearchRepository {
  final SupabaseClient _client;

  SupabaseSearchRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<SearchUserDto>> searchUsers(String q) async {
    final response = await _client.rpc('search_users', params: {'q': q});
    return (response as List)
        .map((e) => SearchUserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

@Riverpod(keepAlive: true)
SearchRepository searchRepository(Ref ref) {
  return SupabaseSearchRepository();
}
