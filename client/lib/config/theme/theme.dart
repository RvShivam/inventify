import 'package:flutter/material.dart';

// Light Theme Colors
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF2A59C3),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF2A9D8F),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFB00020),
  onError: Color(0xFFFFFFFF),
  background: Color(0xFFF8F9FA),
  onBackground: Color(0xFF212529),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF212529),
);

// Dark Theme Colors
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF4C82F7),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF48B5A7),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFCF6679),
  onError: Color(0xFF000000),
  background: Color(0xFF121212),
  onBackground: Color(0xFFE1E1E1),
  surface: Color(0xFF1E1E1E),
  onSurface: Color(0xFFE1E1E1),
);

// Light ThemeData
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,
  appBarTheme: AppBarTheme(
    backgroundColor: lightColorScheme.surface,
    foregroundColor: lightColorScheme.onSurface,
    elevation: 0.5,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lightColorScheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: lightColorScheme.primary, width: 2.0),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: lightColorScheme.secondary,
    foregroundColor: lightColorScheme.onSecondary,
  ),
);

// Dark ThemeData
final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: darkColorScheme,
  appBarTheme: AppBarTheme(
    backgroundColor: darkColorScheme.surface,
    foregroundColor: darkColorScheme.onSurface,
    elevation: 0.5,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkColorScheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade800, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: darkColorScheme.primary, width: 2.0),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: darkColorScheme.secondary,
    foregroundColor: darkColorScheme.onSecondary,
  ),
);