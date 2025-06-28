// lib/screens/profile/profile_screen.dart - Fixed Profile Screen with Theme Toggle
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grin_rea_app/core/app_theme.dart';
import 'package:grin_rea_app/providers/theme_provider.dart';
import 'package:grin_rea_app/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!AuthService.isLoggedIn) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final profile = await AuthService.getUserProfile();
      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (isLoading) {
      return _buildLoadingState();
    }

    if (!AuthService.isLoggedIn || userProfile == null) {
      return _buildNotLoggedInView();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    themeProvider.isDarkMode 
                        ? 'Switched to Dark Mode' 
                        : 'Switched to Light Mode',
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).iconTheme.color),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildBikeInfoCard(),
            const SizedBox(height: 20),
            _buildMenuCard(),
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Profile Image and Basic Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryOrange.withOpacity(0.1),
                  Theme.of(context).cardColor,
                ],
              ),
            ),
            child: Column(
              children: [
                // Profile Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryOrange, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 57,
                    backgroundColor: Theme.of(context).cardColor,
                    backgroundImage: userProfile?['avatar_url'] != null 
                        ? NetworkImage(userProfile!['avatar_url'])
                        : null,
                    child: userProfile?['avatar_url'] == null
                        ? Text(
                            userProfile?['full_name']?[0]?.toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Name
                Text(
                  userProfile?['full_name'] ?? 'Unknown User',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 4),
                
                // Bio
                if (userProfile?['bio'] != null && userProfile!['bio'].isNotEmpty)
                  Text(
                    userProfile!['bio'],
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'Passionate about motorcycles\nand open roads.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                
                const SizedBox(height: 8),
                
                // Username
                Text(
                  '@${userProfile?['username'] ?? 'unknown'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Row
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('${userProfile?['total_rides'] ?? 0}', 'Rides'),
                _buildStatDivider(),
                _buildStatItem('${userProfile?['total_distance'] ?? 0}km', 'Distance'),
                _buildStatDivider(),
                _buildStatItem('${userProfile?['total_hours'] ?? 0}h', 'Hours'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBikeInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.motorcycle, color: AppTheme.primaryOrange, size: 24),
              const SizedBox(width: 12),
              Text(
                'My Bike',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (userProfile?['bike_model'] != null && userProfile!['bike_model'].isNotEmpty) ...[
            _buildInfoRow('Model', userProfile!['bike_model']),
            if (userProfile?['bike_year'] != null)
              _buildInfoRow('Year', userProfile!['bike_year'].toString()),
          ] else ...[
            Text(
              'No bike information added yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit bike info coming soon!')),
                );
              },
              icon: const Icon(Icons.add, color: AppTheme.primaryOrange, size: 18),
              label: Text(
                'Add bike information',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    final menuItems = [
      {
        'icon': Icons.edit,
        'title': 'Edit Profile',
        'onTap': () => _showComingSoon('Edit Profile'),
      },
      {
        'icon': themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        'title': themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
        'onTap': () {
          themeProvider.toggleTheme();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                themeProvider.isDarkMode 
                    ? 'Switched to Dark Mode' 
                    : 'Switched to Light Mode',
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      },
      {
        'icon': Icons.route,
        'title': 'My Routes',
        'onTap': () => _showComingSoon('My Routes'),
      },
      {
        'icon': Icons.favorite_outline,
        'title': 'Favorites',
        'onTap': () => _showComingSoon('Favorites'),
      },
      {
        'icon': Icons.group_outlined,
        'title': 'Friends',
        'onTap': () => _showComingSoon('Friends'),
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Settings',
        'onTap': () => _showComingSoon('Settings'),
      },
      {
        'icon': Icons.help_outline,
        'title': 'Help & Support',
        'onTap': () => _showComingSoon('Help & Support'),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Icon(
                  item['icon'] as IconData,
                  color: AppTheme.primaryOrange,
                  size: 22,
                ),
                title: Text(
                  item['title'] as String,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                onTap: item['onTap'] as VoidCallback,
              ),
              if (index < menuItems.length - 1)
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                  indent: 62,
                  endIndent: 20,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryOrange,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(height: 24),
                Text(
                  'Not Logged In',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please log in to view your profile',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to login
                    },
                    style: AppTheme.primaryButtonStyle,
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: Theme.of(context).cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Logout',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                try {
                  await AuthService.signOut();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              style: AppTheme.primaryButtonStyle,
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}