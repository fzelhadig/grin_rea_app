// lib/screens/feed/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:grin_rea_app/core/app_theme.dart';
import 'package:grin_rea_app/services/post_service.dart';
import 'package:grin_rea_app/screens/feed/create_post_screen.dart';
import 'package:grin_rea_app/widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  late AnimationController _emergencyAnimationController;
  late Animation<double> _emergencyAnimation;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _emergencyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _emergencyAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _emergencyAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emergencyAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await PostService.getFeedPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error loading posts: $e')),
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

  Future<void> _refreshPosts() async {
    setState(() => _isRefreshing = true);
    await _loadPosts();
    setState(() => _isRefreshing = false);
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emergency, color: AppTheme.error, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Emergency Alert'),
            ],
          ),
          content: const Text(
            'This will send an emergency alert to nearby bikers. Use only in real emergencies.',
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
                _sendEmergencyAlert();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  void _sendEmergencyAlert() {
    // TODO: Implement emergency alert functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Emergency alert sent to nearby bikers!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.motorcycle, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Feed'),
          ],
        ),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const CreatePostScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(0.0, 1.0), end: Offset.zero),
                      ),
                      child: child,
                    );
                  },
                ),
              );
              if (result == true) {
                _refreshPosts();
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? _buildLoadingState()
              : RefreshIndicator(
                  onRefresh: _refreshPosts,
                  color: AppTheme.primaryOrange,
                  child: _posts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 100),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: PostCard(
                                post: _posts[index],
                                onLike: () => _handleLike(_posts[index]['id']),
                                onComment: () => _handleComment(_posts[index]),
                                onRefresh: _refreshPosts,
                              ),
                            );
                          },
                        ),
                ),
          
          // Emergency Button
          Positioned(
            bottom: 24,
            right: 24,
            child: AnimatedBuilder(
              animation: _emergencyAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _emergencyAnimation.value,
                  child: FloatingActionButton.extended(
                    onPressed: _showEmergencyDialog,
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    icon: const Icon(Icons.emergency, size: 24),
                    label: const Text(
                      'Emergency',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: AppTheme.primaryOrange,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your feed...',
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.post_add,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No posts yet',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 12),
            Text(
              'Follow other bikers or create your first post to get started!',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
                if (result == true) {
                  _refreshPosts();
                }
              },
              style: AppTheme.primaryButtonStyle,
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLike(String postId) async {
    try {
      await PostService.toggleLike(postId);
      _refreshPosts(); // Refresh to update like count
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
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

  void _handleComment(Map<String, dynamic> post) {
    // TODO: Navigate to comments screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Comments feature coming soon!'),
          ],
        ),
        backgroundColor: AppTheme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}