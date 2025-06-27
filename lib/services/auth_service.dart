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
      rethrow;
    }
  }
  
  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  // Check if user has profile
  static Future<bool> hasProfile() async {
    final profile = await getUserProfile();
    return profile != null;
  }
  
  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}