// lib/core/app_theme.dart - Complete Theme with Light and Dark Mode
import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8A50);
  static const Color lightOrange = Color(0xFFFFF4F1);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkSurface = Color(0xFF333333);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFB0B0B0);
  static const Color darkTertiaryText = Color(0xFF808080);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightText = Color(0xFF212121);
  static const Color lightSecondaryText = Color(0xFF757575);
  static const Color lightTertiaryText = Color(0xFF9E9E9E);
  
  // Dynamic colors based on theme (for backward compatibility)
  static Color lightGrey = darkBackground; // Will be updated by theme provider
  static Color white = darkCard;
  static Color black = darkText;
  static Color mediumGrey = darkTertiaryText;
  static Color primaryText = darkText;
  static Color secondaryText = darkSecondaryText;
  static Color tertiaryText = darkTertiaryText;
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, secondaryOrange],
  );

  // Update colors based on theme
  static void updateColorsForTheme(bool isDark) {
    if (isDark) {
      lightGrey = darkBackground;
      white = darkCard;
      black = darkText;
      mediumGrey = darkTertiaryText;
      primaryText = darkText;
      secondaryText = darkSecondaryText;
      tertiaryText = darkTertiaryText;
    } else {
      lightGrey = lightBackground;
      white = lightCard;
      black = lightText;
      mediumGrey = lightTertiaryText;
      primaryText = lightText;
      secondaryText = lightSecondaryText;
      tertiaryText = lightTertiaryText;
    }
  }

  // Text Styles
  static TextStyle get heading1 => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );
  
  static TextStyle get heading2 => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );
  
  static TextStyle get heading3 => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );
  
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: primaryText,
  );
  
  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryText,
  );
  
  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: tertiaryText,
  );

  // Dynamic Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: mediumGrey.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get darkCardDecoration => BoxDecoration(
    color: darkCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: darkBorder, width: 1),
  );

  // Dynamic Input Decoration
  static InputDecoration inputDecoration(String label, {IconData? prefixIcon, String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryOrange) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: mediumGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: mediumGrey.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      filled: true,
      fillColor: white,
      labelStyle: TextStyle(color: secondaryText),
      hintStyle: TextStyle(color: tertiaryText),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryOrange,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: white,
    foregroundColor: primaryText,
    elevation: 0,
    side: BorderSide(color: mediumGrey, width: 1),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  // Light Theme Data
  static ThemeData get lightThemeData {
    updateColorsForTheme(false);
    return ThemeData.light().copyWith(
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: lightCard,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        iconTheme: IconThemeData(color: lightText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: primaryOrange,
        unselectedItemColor: lightTertiaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: lightCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      dividerColor: lightBorder,
      brightness: Brightness.light,
    );
  }

  // Dark Theme Data
  static ThemeData get darkThemeData {
    updateColorsForTheme(true);
    return ThemeData.dark().copyWith(
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        iconTheme: IconThemeData(color: darkText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryOrange,
        unselectedItemColor: darkTertiaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      dividerColor: darkBorder,
      brightness: Brightness.dark,
    );
  }

  // Backward compatibility
  static ThemeData get themeData => darkThemeData;
  static AppBarTheme get appBarTheme => darkThemeData.appBarTheme;
  static BottomNavigationBarThemeData get bottomNavTheme => darkThemeData.bottomNavigationBarTheme;
  static AppBarTheme get darkAppBarTheme => darkThemeData.appBarTheme;
  static BottomNavigationBarThemeData get darkBottomNavTheme => darkThemeData.bottomNavigationBarTheme;

  // Helper method to create MaterialColor
  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}