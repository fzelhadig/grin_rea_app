// lib/screens/feed/comments_screen.dart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:grin_rea_app/core/app_theme.dart';
import 'package:grin_rea_app/services/post_service.dart';

class CommentsScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const CommentsScreen({
    super.key,
    required this.post,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isAddingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await PostService.getPostComments(widget.post['id']);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading comments: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isAddingComment = true);

    try {
      final newComment = await PostService.addComment(
        widget.post['id'],
        _commentController.text.trim(),
      );
      
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });

      // Scroll to bottom to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comment added!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isAddingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.post['profiles'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Original Post
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post header
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                    backgroundImage: profile?['avatar_url'] != null
                        ? NetworkImage(profile!['avatar_url'])
                        : null,
                    child: profile?['avatar_url'] == null
                        ? Text(
                            profile?['full_name']?[0]?.toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    profile?['full_name'] ?? 'Unknown User',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '@${profile?['username'] ?? 'unknown'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Text(
                    timeago.format(DateTime.parse(widget.post['created_at'])),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                
                // Post content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    widget.post['content'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ),
                
                // Location if available
                if (widget.post['location_name'] != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.primaryOrange,
                          ),
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
              ],
            ),
          ),
          
          // Comments header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Comments (${_comments.length})',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Comments list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 64,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final commentProfile = comment['profiles'] as Map<String, dynamic>?;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                                backgroundImage: commentProfile?['avatar_url'] != null
                                    ? NetworkImage(commentProfile!['avatar_url'])
                                    : null,
                                child: commentProfile?['avatar_url'] == null
                                    ? Text(
                                        commentProfile?['full_name']?[0]?.toUpperCase() ?? 'U',
                                        style: const TextStyle(
                                          color: AppTheme.primaryOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        commentProfile?['full_name'] ?? 'Unknown User',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeago.format(DateTime.parse(comment['created_at'])),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment['content'],
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isAddingComment ? null : _addComment,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: _isAddingComment
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}