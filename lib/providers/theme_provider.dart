import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _kKey = 'accent_color';

  static const List<({String name, Color color})> accents = [
    (name: 'Vibe Green', color: Color(0xFF1DB954)),
    (name: 'Purple', color: Color(0xFF9C27B0)),
    (name: 'Ocean Blue', color: Color(0xFF2196F3)),
    (name: 'Sunset Orange', color: Color(0xFFFF6B35)),
    (name: 'Neon Pink', color: Color(0xFFE91E8C)),
    (name: 'Arctic Teal', color: Color(0xFF00BCD4)),
  ];

  Color _accent = accents.first.color;
  Color get accent => _accent;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_kKey);
    if (value != null) {
      _accent = Color(value);
      notifyListeners();
    }
  }

  Future<void> setAccent(Color color) async {
    if (_accent == color) return;
    _accent = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kKey, color.toARGB32());
  }
}
