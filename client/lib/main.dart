import 'package:flutter/material.dart';
import 'package:inventify/screens/signup.dart';


void main() {
  runApp(const ShopApp());
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        // Define a light ColorScheme for consistency using new hex codes
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2A59C3), // Primary Blue
          secondary: Color(0xFF2A9D8F), // Secondary Teal
          background: Color(0xFFF8F9FA), // Background
          surface: Color(0xFFFFFFFF), // Surface (Input Fields)
          onBackground: Color(0xFF212529), // Primary Text
          onSurface: Color(0xFF212529), // Primary Text on Surface
        ),
        
       
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), 

        // AppBar Theme for Light Mode
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF212529)), // text_primary
          titleTextStyle: TextStyle(
            color: Color(0xFF212529), // text_primary
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Input Field Theme for Light Mode (White fields, subtle styling)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF), // surface
          hintStyle: const TextStyle(color: Color(0xFF6C757D)), // text_secondary
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF2A59C3), width: 2.0), // primary color
          ),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4C82F7), // Primary Blue
          secondary: Color(0xFF48B5A7), // Secondary Teal
          background: Color(0xFF121212), // Dark background
          surface: Color(0xFF1E1E1E), // Dark surface for cards/fields
          onBackground: Color(0xFFE1E1E1), // Primary text
          onSurface: Color(0xFFE1E1E1), // Primary text on surface
        ),
        
        // Use the defined color scheme values
        scaffoldBackgroundColor: const Color(0xFF121212), // background
        cardColor: const Color(0xFF1E1E1E), // surface

        // AppBar Theme for Dark Mode
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFE1E1E1)), // text_primary
          titleTextStyle: TextStyle(
            color: Color(0xFFE1E1E1), // text_primary
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Input Field Theme for Dark Mode (Dark fields on dark background)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E), // surface
          hintStyle: const TextStyle(color: Color(0xFFA8A8A8)), // text_secondary
          
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF4C82F7), width: 2.0), // primary color
          ),
        ),
      ),
      
      themeMode: ThemeMode.system, // Uses the system setting (e.g., phone settings)

      home: const SignupScreen(), 
      
    );
  }
}
