// lib/screens/auth/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grin_rea_app/core/app_theme.dart';
import 'package:grin_rea_app/services/auth_service.dart';
import 'package:grin_rea_app/screens/auth/login_screen.dart';
import 'package:grin_rea_app/screens/home/home_screen.dart';
import 'package:grin_rea_app/screens/auth/profile_setup_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        print('AuthGate StreamBuilder - Connection: ${snapshot.connectionState}');
        print('AuthGate StreamBuilder - Has data: ${snapshot.hasData}');
        
        // Show loading while waiting for initial auth state
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildLoadingScreen();
        }

        // Check if user is logged in
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        if (session?.user == null) {
          print('No session, showing login screen');
          return const LoginScreen();
        }

        print('User logged in: ${session!.user!.id}');
        
        // User is logged in, check if they have a profile
        return FutureBuilder<bool>(
          future: AuthService.hasProfile(),
          builder: (context, profileSnapshot) {
            // Don't show loading for profile check, just use previous state
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              // Return a minimal loading indicator or the current screen
              return Scaffold(
                backgroundColor: AppTheme.lightGrey,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryOrange,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final hasProfile = profileSnapshot.data ?? false;
            print('User has profile: $hasProfile');

            if (!hasProfile) {
              return const ProfileSetupScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: Center(
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
                Icons.motorcycle,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Grin REA',
              style: AppTheme.heading1.copyWith(
                fontSize: 32,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              color: AppTheme.primaryOrange,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}