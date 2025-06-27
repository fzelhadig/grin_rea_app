import 'package:flutter/material.dart';
import 'package:grin_rea_app/services/auth_service.dart';
import 'package:grin_rea_app/screens/auth/login_screen.dart';
import 'package:grin_rea_app/screens/home/home_screen.dart';
import 'package:grin_rea_app/screens/auth/profile_setup_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _checkInitialState();
  }

  void _setupAuthListener() {
    AuthService.authStateChanges.listen((data) {
      _checkAuthState();
    });
  }

  Future<void> _checkInitialState() async {
    await _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    if (AuthService.isLoggedIn) {
      final hasProfile = await AuthService.hasProfile();
      setState(() {
        _hasProfile = hasProfile;
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasProfile = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!AuthService.isLoggedIn) {
      return const LoginScreen();
    }

    if (!_hasProfile) {
      return const ProfileSetupScreen();
    }

    return const HomeScreen();
  }
}