// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grin_rea_app/core/supabase_config.dart';

class AuthService {
  static final _client = SupabaseConfig.client;
  
  // Get current user
  static User? get currentUser => _client.auth.currentUser;
  
  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;
  
  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
        },
      );
      
      return response;
    } catch (e) {
      print('SignUp error: $e');
      rethrow;
    }
  }
  
  // Create profile after email confirmation
  static Future<void> createProfile({
    required String username,
    required String fullName,
  }) async {
    if (currentUser == null) throw Exception('No authenticated user');
    
    try {
      await _client.from('profiles').insert({
        'id': currentUser!.id,
        'username': username,
        'full_name': fullName,
        'email': currentUser!.email,
      });
    } catch (e) {
      print('Create profile error: $e');
      rethrow;
    }
  }
  
  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('Sign in successful: ${response.user?.id}');
      return response;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    try {
      print('Signing out user: ${currentUser?.id}');
      await _client.auth.signOut();
      print('Sign out successful');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
  
  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) {
      print('No current user for profile fetch');
      return null;
    }
    
    try {
      print('Fetching profile for user: ${currentUser!.id}');
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      print('Profile fetch result: ${response != null ? 'found' : 'not found'}');
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  // Check if user has profile
  static Future<bool> hasProfile() async {
    try {
      final profile = await getUserProfile();
      final hasProfile = profile != null;
      print('User has profile: $hasProfile');
      return hasProfile;
    } catch (e) {
      print('Error checking if user has profile: $e');
      return false;
    }
  }
  
  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}