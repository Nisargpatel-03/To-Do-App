import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_app/providers/theme_provider.dart';
import 'package:task_manager_app/screens/auth/login_screen.dart';
import 'package:task_manager_app/screens/home/home_screen.dart';
import 'package:task_manager_app/providers/auth_providers.dart';
import 'Theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, // Use the light theme from AppTheme
      darkTheme: AppTheme.dark, // Use the dark theme from AppTheme
      themeMode: themeMode,
      home: authState.when(
        data: (user) => user == null ? const LoginScreen() : const HomeScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Something went wrong: $error')),
        ),
      ),
    );
  }
}