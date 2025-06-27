import 'package:grin_rea_app/core/supabase_config.dart';
import 'package:grin_rea_app/services/auth_service.dart';

class PostService {
  static final _client = SupabaseConfig.client;

  // Create a new post
  static Future<Map<String, dynamic>> createPost({
    required String content,
    List<String>? imageUrls,
    double? locationLat,
    double? locationLng,
    String? locationName,
  }) async {
    if (AuthService.currentUser == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client.from('posts').insert({
      'user_id': AuthService.currentUser!.id,
      'content': content,
      'image_urls': imageUrls,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_name': locationName,
    }).select().single();

    return response;
  }

  // Get feed posts (from followed users + own posts)
  static Future<List<Map<String, dynamic>>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    if (AuthService.currentUser == null) return [];

    final response = await _client
        .from('posts')
        .select('''
          *,
          profiles:user_id (
            id,
            username,
            full_name,
            avatar_url
          ),
          post_likes (
            user_id
          ),
          post_comments (
            count
          )
        ''')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get user's own posts
  static Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    final response = await _client
        .from('posts')
        .select('''
          *,
          profiles:user_id (
            id,
            username,
            full_name,
            avatar_url
          ),
          post_likes (
            user_id
          ),
          post_comments (
            count
          )
        ''')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Like/unlike a post
  static Future<void> toggleLike(String postId) async {
    if (AuthService.currentUser == null) return;

    final userId = AuthService.currentUser!.id;
    
    // Check if already liked
    final existing = await _client
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      // Like
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  // Add comment to post
  static Future<Map<String, dynamic>> addComment(String postId, String content) async {
    if (AuthService.currentUser == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client.from('post_comments').insert({
      'post_id': postId,
      'user_id': AuthService.currentUser!.id,
      'content': content,
    }).select('''
      *,
      profiles:user_id (
        id,
        username,
        full_name,
        avatar_url
      )
    ''').single();

    return response;
  }

  // Get comments for a post
  static Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    final response = await _client
        .from('post_comments')
        .select('''
          *,
          profiles:user_id (
            id,
            username,
            full_name,
            avatar_url
          )
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Delete post
  static Future<void> deletePost(String postId) async {
    if (AuthService.currentUser == null) return;

    await _client
        .from('posts')
        .update({'is_active': false})
        .eq('id', postId)
        .eq('user_id', AuthService.currentUser!.id);
  }
}