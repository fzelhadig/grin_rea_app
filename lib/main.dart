import 'package:flutter/material.dart';
import 'package:grin_rea_app/core/supabase_config.dart';
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
    return MaterialApp(
      title: 'Biker App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BikerAppError extends StatelessWidget {
  const BikerAppError({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize app.\nCheck your Supabase configuration.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      ),
    );
  }
}