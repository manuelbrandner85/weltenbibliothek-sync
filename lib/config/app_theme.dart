import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Farben - Mystisches Dark Theme
  static const Color primaryPurple = Color(0xFF6B46C1); // Mystisches Violett
  static const Color secondaryGold = Color(0xFFD4AF37);  // Edles Gold
  static const Color backgroundDark = Color(0xFF1a1a2e); // Kosmisches Dunkelblau-Schwarz
  static const Color surfaceDark = Color(0xFF16213e);    // Strukturierendes Dunkelblau
  static const Color errorRed = Color(0xFFFF6B6B);       // Klares Warnsignal-Rot
  static const Color textWhite = Color(0xFFFFFFFF);      // Maximale Lesbarkeit
  
  // Event-Kategorie-Farben
  static const Color lostCivilizations = Color(0xFFFF8C42);  // Orange
  static const Color alienContact = Color(0xFF4ADE80);       // Grün
  static const Color secretSocieties = Color(0xFFEF4444);    // Rot
  static const Color techMysteries = Color(0xFF06B6D4);      // Cyan
  static const Color dimensionalAnomalies = Color(0xFF8B5CF6); // Violett
  static const Color occultEvents = Color(0xFFEC4899);       // Magenta
  static const Color forbiddenKnowledge = Color(0xFF92400E); // Braun
  static const Color ufoFleets = Color(0xFF3B82F6);          // Blau
  static const Color energyPhenomena = Color(0xFFFBBF24);    // Gelb
  static const Color globalConspiracies = Color(0xFF991B1B); // Dunkelrot

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryPurple,
        secondary: secondaryGold,
        surface: surfaceDark,
        error: errorRed,
        onPrimary: textWhite,
        onSecondary: backgroundDark,
        onSurface: textWhite,
        onError: textWhite,
      ),
      scaffoldBackgroundColor: backgroundDark,
      
      // Typografie
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cinzel(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: secondaryGold,
        ),
        displayMedium: GoogleFonts.cinzel(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        headlineMedium: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 16,
          color: textWhite,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14,
          color: textWhite.withValues(alpha: 0.9),
        ),
        bodySmall: GoogleFonts.lato(
          fontSize: 12,
          color: textWhite.withValues(alpha: 0.7),
        ),
      ),
      
      // Karten-Design
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Button-Design
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      
      // Icon-Theme
      iconTheme: const IconThemeData(
        color: secondaryGold,
        size: 24,
      ),
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: secondaryGold,
        ),
        iconTheme: const IconThemeData(
          color: secondaryGold,
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: secondaryGold,
        unselectedItemColor: textWhite,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
  
  // Gradient-Effekte
  static const LinearGradient purpleGoldGradient = LinearGradient(
    colors: [primaryPurple, secondaryGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [backgroundDark, surfaceDark, primaryPurple],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
