import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeVariant {
  midnightGold,
  royalNavy,
  deepOnyx,
  deepBurgundy,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeVariant _variant = AppThemeVariant.midnightGold;
  double _fontSize = 18.0;

  AppThemeVariant get variant => _variant;
  double get fontSize => _fontSize;

  ThemeProvider() {
    loadPreferences();
  }

  void setThemeVariant(AppThemeVariant variant) async {
    _variant = variant;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeVariant', variant.index);
  }

  void setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontSize', size);
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final variantIndex = prefs.getInt('themeVariant') ?? 0;
    if (variantIndex < AppThemeVariant.values.length) {
      _variant = AppThemeVariant.values[variantIndex];
    }
    _fontSize = prefs.getDouble('fontSize') ?? 18.0;
    notifyListeners();
  }

  ThemeData get currentTheme {
    Color bgColor;
    Color surfaceColor;
    Color primaryColor = const Color(0xFFFFC453); // Standard Gold

    switch (_variant) {
      case AppThemeVariant.midnightGold:
        bgColor = const Color(0xFF100F0D);
        surfaceColor = const Color(0xFF1C1B19);
        break;
      case AppThemeVariant.royalNavy:
        bgColor = const Color(0xFF0B101A);
        surfaceColor = const Color(0xFF141C2B);
        break;
      case AppThemeVariant.deepOnyx:
        bgColor = const Color(0xFF0D0D0D);
        surfaceColor = const Color(0xFF171717);
        break;
      case AppThemeVariant.deepBurgundy:
        bgColor = const Color(0xFF1A0D0D);
        surfaceColor = const Color(0xFF291616);
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceColor,
        brightness: Brightness.dark,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'BelaHidase', color: Color(0xFFEAD6A8)),
        displayMedium: TextStyle(fontFamily: 'BelaHidase', color: Color(0xFFEAD6A8)),
        displaySmall: TextStyle(fontFamily: 'BelaHidase', color: Color(0xFFEAD6A8)),
        headlineMedium: TextStyle(fontFamily: 'Loga', fontWeight: FontWeight.w500, color: Color(0xFFEAD6A8)),
        bodyLarge: TextStyle(fontFamily: 'Loga', fontWeight: FontWeight.normal, color: Color(0xFFEAD6A8)),
        bodyMedium: TextStyle(fontFamily: 'Loga', fontWeight: FontWeight.normal, color: Color(0xFFEAD6A8)),
      ),
    );
  }
}