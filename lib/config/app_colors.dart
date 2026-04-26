import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1DB954);       // Spotify green
  static const Color primaryDark = Color(0xFF158a3e);
  static const Color background = Color(0xFF121212);    // Deep dark
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceMuted = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFCF6679);
  static const Color upvote = Color(0xFF1DB954);
  static const Color downvote = Color(0xFFCF6679);

  // Mood colors
  static const Map<String, Color> moodColors = {
    'chill': Color(0xFF5E97F6),
    'hype': Color(0xFFFF6B35),
    'sad': Color(0xFF7986CB),
    'focus': Color(0xFF4DB6AC),
    'party': Color(0xFFFFD54F),
    'romantic': Color(0xFFE91E8C),
  };

  static Color moodColor(String mood) =>
      moodColors[mood.toLowerCase()] ?? primary;
}
