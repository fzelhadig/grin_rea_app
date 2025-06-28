// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:grin_rea_app/core/app_theme.dart';
import 'package:grin_rea_app/services/auth_service.dart';

class PostCard extends StatefulWidget {
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
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _isLikeAnimating = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _animatedLike() {
    if (!_isLikeAnimating) {
      setState(() => _isLikeAnimating = true);
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse().then((_) {
          setState(() => _isLikeAnimating = false);
        });
      });
      widget.onLike();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.post['profiles'] as Map<String, dynamic>?;
    final likes = widget.post['post_likes'] as List<dynamic>? ?? [];
    final isLiked = likes.any((like) => like['user_id'] == AuthService.currentUser?.id);
    final createdAt = DateTime.parse(widget.post['created_at']);
    final isOwnPost = widget.post['user_id'] == AuthService.currentUser?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: Theme.of(context).brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: profile?['avatar_url'] == null ? AppTheme.primaryGradient : null,
                    border: Border.all(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: profile?['avatar_url'] != null
                      ? ClipOval(
                          child: Image.network(
                            profile!['avatar_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(profile),
                          ),
                        )
                      : _buildAvatarFallback(profile),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?['full_name'] ?? 'Unknown User',
                        style: AppTheme.heading3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${profile?['username'] ?? 'unknown'}',
                        style: AppTheme.bodySmall.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeago.format(createdAt),
                      style: AppTheme.bodySmall,
                    ),
                    if (isOwnPost)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: AppTheme.mediumGrey, size: 20),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: AppTheme.error, size: 18),
                                const SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppTheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:             Text(
              widget.post['content'] ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
          
          // Images (if any)
          if (widget.post['image_urls'] != null && (widget.post['image_urls'] as List).isNotEmpty)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.lightGrey,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PageView.builder(
                  itemCount: (widget.post['image_urls'] as List).length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      (widget.post['image_urls'] as List)[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryOrange,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.lightGrey,
                        child: Center(
                          child: Icon(Icons.error, color: AppTheme.mediumGrey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Location (if any)
          if (widget.post['location_name'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppTheme.primaryOrange),
                    const SizedBox(width: 4),
                    Text(
                      widget.post['location_name'],
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _likeAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _likeAnimation.value,
                      child: InkWell(
                        onTap: _animatedLike,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isLiked ? AppTheme.lightOrange : AppTheme.lightGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? AppTheme.error : AppTheme.mediumGrey,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${likes.length}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: isLiked ? AppTheme.error : AppTheme.mediumGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: widget.onComment,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.comment_outlined, color: AppTheme.mediumGrey, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.post['post_comments']?.length ?? 0}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.mediumGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    // TODO: Share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Share feature coming soon!',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.info,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.share_outlined, color: AppTheme.mediumGrey, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(Map<String, dynamic>? profile) {
    return Center(
      child: Text(
        profile?['full_name']?[0]?.toUpperCase() ?? 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Post'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.mediumGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deletePost() async {
    try {
      // TODO: Implement delete functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('Delete functionality coming soon!'),
            ],
          ),
          backgroundColor: AppTheme.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error deleting post: $e')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}