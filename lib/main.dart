// lib/main.dart
import 'package:flutter/material.dart';
import 'package:quiz2om/screens/home_screen.dart';
import 'package:quiz2om/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ohoofglcefbpwgnoxjcg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ob29mZ2xjZWZicHdnbm94amNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQzNjM5NTMsImV4cCI6MjA1OTkzOTk1M30.TaTN-hmOPE6kYbmWklsCFMUm4qmTc4ZF_M9Ss4OGJps',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz2OM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
