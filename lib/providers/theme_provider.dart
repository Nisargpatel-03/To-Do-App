import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add to pubspec.yaml

// Add shared_preferences to your pubspec.yaml
// dependencies:
//   shared_preferences: ^2.x.x

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) { // Default to dark as per image
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default to true for dark mode
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    state = isOn ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('isDarkMode', isOn);
  }
}