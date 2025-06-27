// lib/main.dart
import 'package:flutter/material.dart';
import 'package:grin_rea_app/core/supabase_config.dart';
import 'package:grin_rea_app/core/app_theme.dart';
import 'package:grin_rea_app/core/restart_widget.dart';
import 'package:grin_rea_app/screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseConfig.initialize();
    runApp(const BikerApp());
  } catch (e) {
    print('Error initializing Supabase: $e');
    runApp(const BikerAppError());
  }
}

class BikerApp extends StatelessWidget {
  const BikerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RestartWidget(
      child: MaterialApp(
        title: 'Grin REA',
        theme: AppTheme.themeData,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class BikerAppError extends StatelessWidget {
  const BikerAppError({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.cardDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initialization Failed',
                  style: AppTheme.heading2.copyWith(color: AppTheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to initialize app.\nCheck your Supabase configuration.',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}