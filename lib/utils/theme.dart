import 'package:flutter/material.dart';

class AppTheme {
  // Core palette
  static const Color bgPrimary = Color(0xFF0D0F14);
  static const Color bgCard = Color(0xFF13151D);
  static const Color bgCardBorder = Color(0xFF1E2130);
  static const Color bgHighlight = Color(0xFF1A1D26);

  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFFA0A5BB);
  static const Color textMuted = Color(0xFF555A6B);

  static const Color accentGreen = Color(0xFF3ECF8E);
  static const Color accentRed = Color(0xFFF04C57);
  static const Color accentBlue = Color(0xFF6AB4FF);
  static const Color accentAmber = Color(0xFFF0C040);
  static const Color accentPurple = Color(0xFF4A3FA0);
  static const Color accentPurpleLight = Color(0xFF2A1F5E);

  static const Color divider = Color(0xFF2A2D35);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      fontFamily: 'SF Pro Display',
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentGreen,
        surface: bgCard,
        error: accentRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: bgCardBorder, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgPrimary,
        selectedItemColor: accentBlue,
        unselectedItemColor: textMuted,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textSecondary, fontSize: 14),
        bodyMedium: TextStyle(color: textMuted, fontSize: 12),
        labelSmall: TextStyle(color: textMuted, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }
}

class AppConstants {
  static const String appName = 'Stockfolio';

  // Yahoo Finance base
  static const String yahooBase = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const String yahooQuoteBase = 'https://query1.finance.yahoo.com/v7/finance/quote';

  // Finnhub
  static const String finnhubBase = 'https://finnhub.io/api/v1';

  // Storage keys
  static const String keyWatchlist = 'watchlist_v1';
  static const String keyFinnhubToken = 'finnhub_token';
  static const String keyMarketPref = 'market_preference';

  // Chart colors for compare overlays
  static const List<Color> compareColors = [
    Color(0xFF6AB4FF),
    Color(0xFFF0C040),
    Color(0xFFE07BB5),
  ];

  // Periods
  static const List<Map<String, String>> chartPeriods = [
    {'label': '1D', 'range': '1d', 'interval': '5m'},
    {'label': '1W', 'range': '5d', 'interval': '30m'},
    {'label': '1M', 'range': '1mo', 'interval': '1d'},
    {'label': '3M', 'range': '3mo', 'interval': '1d'},
    {'label': '1Y', 'range': '1y', 'interval': '1wk'},
    {'label': '5Y', 'range': '5y', 'interval': '1mo'},
  ];
}
