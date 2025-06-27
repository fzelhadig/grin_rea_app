import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grin_rea_app/core/supabase_config.dart';
import 'package:grin_rea_app/services/auth_service.dart';

class FollowService {
  static final _client = SupabaseConfig.client;

  // Follow a user
  static Future<void> followUser(String userId) async {
    if (AuthService.currentUser == null) return;
    
    await _client.from('follows').insert({
      'follower_id': AuthService.currentUser!.id,
      'following_id': userId,
    });
  }

  // Unfollow a user
  static Future<void> unfollowUser(String userId) async {
    if (AuthService.currentUser == null) return;
    
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', AuthService.currentUser!.id)
        .eq('following_id', userId);
  }

  // Check if following a user
  static Future<bool> isFollowing(String userId) async {
    if (AuthService.currentUser == null) return false;
    
    final result = await _client
        .from('follows')
        .select()
        .eq('follower_id', AuthService.currentUser!.id)
        .eq('following_id', userId)
        .maybeSingle();
    
    return result != null;
  }

  // Get followers of a user
  static Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final response = await _client
        .from('follows')
        .select('''
          follower_id,
          profiles:follower_id (
            id,
            username,
            full_name,
            avatar_url
          )
        ''')
        .eq('following_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get users that a user is following
  static Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final response = await _client
        .from('follows')
        .select('''
          following_id,
          profiles:following_id (
            id,
            username,
            full_name,
            avatar_url
          )
        ''')
        .eq('follower_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get follower/following counts
  static Future<Map<String, int>> getFollowCounts(String userId) async {
    final followers = await _client
        .from('follows')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('following_id', userId);

    final following = await _client
        .from('follows')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('follower_id', userId);

    return {
      'followers': followers.count ?? 0,
      'following': following.count ?? 0,
    };
  }

  // Search users
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final response = await _client
        .from('profiles')
        .select('id, username, full_name, avatar_url')
        .or('username.ilike.%$query%,full_name.ilike.%$query%')
        .eq('is_active', true)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }
}