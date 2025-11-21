import 'package:flutter/material.dart';
import 'package:inventify/config/theme/theme.dart';
import 'package:inventify/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:inventify/providers/product_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Inventify',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const LoginScreen(), 
      ),
    );
  }
}