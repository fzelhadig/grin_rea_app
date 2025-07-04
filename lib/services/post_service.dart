// lib/services/post_service.dart - Fixed Version
import 'dart:math' show sin, cos, sqrt, atan2, pi;
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

  // Get feed posts (from followed users + own posts)
  static Future<List<Map<String, dynamic>>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    if (AuthService.currentUser == null) {
      print('No authenticated user for feed');
      return [];
    }

    print('Loading feed posts...');
    
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            profiles:user_id (
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('Loaded ${response.length} posts from database');

      // Add like count and user liked status to each post
      List<Map<String, dynamic>> postsWithCounts = [];
      
      for (var post in response) {
        final postData = Map<String, dynamic>.from(post);
        
        // Get like count and check if current user liked
        final likeCount = await getLikeCount(post['id']);
        final isLiked = await isPostLikedByUser(post['id']);
        final commentCount = await getCommentCount(post['id']);
        
        postData['like_count'] = likeCount;
        postData['is_liked'] = isLiked;
        postData['comment_count'] = commentCount;
        
        print('Post ${post['id']}: likes=$likeCount, comments=$commentCount, isLiked=$isLiked');
        
        postsWithCounts.add(postData);
      }

      print('Returning ${postsWithCounts.length} posts with counts');
      return postsWithCounts;
    } catch (e) {
      print('Error loading feed posts: $e');
      rethrow;
    }
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
          )
        ''')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    // Add like count and user liked status to each post
    List<Map<String, dynamic>> postsWithCounts = [];
    
    for (var post in response) {
      final postData = Map<String, dynamic>.from(post);
      
      final likeCount = await getLikeCount(post['id']);
      final isLiked = await isPostLikedByUser(post['id']);
      final commentCount = await getCommentCount(post['id']);
      
      postData['like_count'] = likeCount;
      postData['is_liked'] = isLiked;
      postData['comment_count'] = commentCount;
      
      postsWithCounts.add(postData);
    }

    return postsWithCounts;
  }

  // Like/unlike a post
  static Future<void> toggleLike(String postId) async {
    if (AuthService.currentUser == null) {
      print('Error: No authenticated user');
      throw Exception('User not authenticated');
    }

    final userId = AuthService.currentUser!.id;
    print('Toggle like - User: $userId, Post: $postId');
    
    try {
      // Check if already liked
      print('Checking if post is already liked...');
      final existing = await _client
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      print('Existing like: ${existing != null ? 'found' : 'not found'}');

      if (existing != null) {
        // Unlike
        print('Removing like...');
        await _client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        print('Like removed successfully');
      } else {
        // Like
        print('Adding like...');
        await _client.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
        print('Like added successfully');
      }
    } catch (e) {
      print('Error in toggleLike: $e');
      rethrow;
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

  // Get like count for a post
  static Future<int> getLikeCount(String postId) async {
    try {
      final response = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId);

      return response.length;
    } catch (e) {
      print('Error getting like count for post $postId: $e');
      return 0;
    }
  }

  // Check if current user liked a post
  static Future<bool> isPostLikedByUser(String postId) async {
    if (AuthService.currentUser == null) return false;

    try {
      final response = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', AuthService.currentUser!.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if user liked post $postId: $e');
      return false;
    }
  }

  // Get comment count for a post
  static Future<int> getCommentCount(String postId) async {
    try {
      final response = await _client
          .from('post_comments')
          .select('id')
          .eq('post_id', postId);

      return response.length;
    } catch (e) {
      print('Error getting comment count for post $postId: $e');
      return 0;
    }
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

  // Search posts by content or location
  static Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            profiles:user_id (
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .or('content.ilike.%$query%,location_name.ilike.%$query%')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(20);

      // Add like count and user liked status to each post
      List<Map<String, dynamic>> postsWithCounts = [];
      
      for (var post in response) {
        final postData = Map<String, dynamic>.from(post);
        
        final likeCount = await getLikeCount(post['id']);
        final isLiked = await isPostLikedByUser(post['id']);
        final commentCount = await getCommentCount(post['id']);
        
        postData['like_count'] = likeCount;
        postData['is_liked'] = isLiked;
        postData['comment_count'] = commentCount;
        
        postsWithCounts.add(postData);
      }

      return postsWithCounts;
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }

  // Get posts near a location
  static Future<List<Map<String, dynamic>>> getPostsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    // This is a simplified version. For production, you'd want to use PostGIS functions
    final response = await _client
        .from('posts')
        .select('''
          *,
          profiles:user_id (
            id,
            username,
            full_name,
            avatar_url
          )
        ''')
        .not('location_lat', 'is', null)
        .not('location_lng', 'is', null)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    // Filter by distance (simplified calculation)
    List<Map<String, dynamic>> nearbyPosts = [];
    for (var post in response) {
      if (post['location_lat'] != null && post['location_lng'] != null) {
        double distance = _calculateDistance(
          latitude,
          longitude,
          post['location_lat'].toDouble(),
          post['location_lng'].toDouble(),
        );
        
        if (distance <= radiusKm) {
          final postData = Map<String, dynamic>.from(post);
          
          // Add counts
          final likeCount = await getLikeCount(post['id']);
          final isLiked = await isPostLikedByUser(post['id']);
          final commentCount = await getCommentCount(post['id']);
          
          postData['like_count'] = likeCount;
          postData['is_liked'] = isLiked;
          postData['comment_count'] = commentCount;
          postData['distance_km'] = distance;
          
          nearbyPosts.add(postData);
        }
      }
    }

    // Sort by distance
    nearbyPosts.sort((a, b) => a['distance_km'].compareTo(b['distance_km']));
    return nearbyPosts;
  }

  // Calculate distance between two points (Haversine formula)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180);
  }
}