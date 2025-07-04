// lib/widgets/post_card.dart - Fixed Version
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:grin_rea_app/core/app_theme.dart';
import 'package:grin_rea_app/services/auth_service.dart';
import 'package:grin_rea_app/screens/feed/comments_screen.dart';

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
  
  // Local state to track like status for immediate UI feedback
  late int _localLikeCount;
  late bool _localIsLiked;
  late int _localCommentCount;

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
    
    // Initialize local state with widget data
    _localLikeCount = widget.post['like_count'] ?? 0;
    _localIsLiked = widget.post['is_liked'] ?? false;
    _localCommentCount = widget.post['comment_count'] ?? 0;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update local state when widget data changes
    final newLikeCount = widget.post['like_count'] ?? 0;
    final newIsLiked = widget.post['is_liked'] ?? false;
    final newCommentCount = widget.post['comment_count'] ?? 0;
    
    if (_localLikeCount != newLikeCount || 
        _localIsLiked != newIsLiked || 
        _localCommentCount != newCommentCount) {
      setState(() {
        _localLikeCount = newLikeCount;
        _localIsLiked = newIsLiked;
        _localCommentCount = newCommentCount;
      });
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _animatedLike() {
    if (!_isLikeAnimating) {
      setState(() => _isLikeAnimating = true);
      
      // Immediately update local state for instant UI feedback
      setState(() {
        _localIsLiked = !_localIsLiked;
        _localLikeCount = _localIsLiked ? _localLikeCount + 1 : _localLikeCount - 1;
      });
      
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse().then((_) {
          setState(() => _isLikeAnimating = false);
        });
      });
      widget.onLike();
    }
  }

  void _navigateToComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(post: widget.post),
      ),
    ).then((_) {
      // Refresh the post data when returning from comments
      widget.onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.post['profiles'] as Map<String, dynamic>?;
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${profile?['username'] ?? 'unknown'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeago.format(createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (isOwnPost) ...[
                      const SizedBox(height: 4),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert, 
                          color: Theme.of(context).textTheme.bodySmall?.color, 
                          size: 20,
                        ),
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
                  ],
                ),
              ],
            ),
          ),
          
          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
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
                color: Theme.of(context).scaffoldBackgroundColor,
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
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Center(
                          child: Icon(
                            Icons.error, 
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
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
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppTheme.primaryOrange),
                    const SizedBox(width: 4),
                    Text(
                      widget.post['location_name'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                // Like button
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
                            color: _localIsLiked 
                                ? AppTheme.primaryOrange.withOpacity(0.1) 
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _localIsLiked ? Icons.favorite : Icons.favorite_border,
                                color: _localIsLiked ? AppTheme.error : Theme.of(context).textTheme.bodySmall?.color,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_localLikeCount',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _localIsLiked ? AppTheme.error : Theme.of(context).textTheme.bodySmall?.color,
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
                
                // Comment button
                InkWell(
                  onTap: _navigateToComments,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined, 
                          color: Theme.of(context).textTheme.bodySmall?.color, 
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_localCommentCount',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                
                // Share button
                InkWell(
                  onTap: () {
                    // TODO: Share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Share feature coming soon!'),
                        backgroundColor: AppTheme.info,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.share_outlined, 
                      color: Theme.of(context).textTheme.bodySmall?.color, 
                      size: 18,
                    ),
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
        backgroundColor: Theme.of(context).cardColor,
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
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
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
          content: const Text('Delete functionality coming soon!'),
          backgroundColor: AppTheme.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}