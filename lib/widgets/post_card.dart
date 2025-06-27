import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grin_rea_app/services/auth_service.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onRefresh;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final profile = post['profiles'] as Map<String, dynamic>?;
    final likes = post['post_likes'] as List<dynamic>? ?? [];
    final isLiked = likes.any((like) => like['user_id'] == AuthService.currentUser?.id);
    final createdAt = DateTime.parse(post['created_at']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          ListTile(
            leading: CircleAvatar(
              backgroundImage: profile?['avatar_url'] != null
                  ? CachedNetworkImageProvider(profile!['avatar_url'])
                  : null,
              child: profile?['avatar_url'] == null
                  ? Text(profile?['full_name']?[0]?.toUpperCase() ?? 'U')
                  : null,
            ),
            title: Text(
              profile?['full_name'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('@${profile?['username'] ?? 'unknown'}'),
            trailing: Text(
              timeago.format(createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          
          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              post['content'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          
          // Images (if any)
          if (post['image_urls'] != null && (post['image_urls'] as List).isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: PageView.builder(
                itemCount: (post['image_urls'] as List).length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: (post['image_urls'] as List)[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
          
          // Location (if any)
          if (post['location_name'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    post['location_name'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                ),
                Text('${likes.length}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onComment,
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                ),
                Text('${post['post_comments']?.length ?? 0}'),
                const Spacer(),
                if (post['user_id'] == AuthService.currentUser?.id)
                  IconButton(
                    onPressed: () => _showDeleteDialog(context),
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context) async {
    try {
      // TODO: Implement delete functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete functionality coming soon!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }
}