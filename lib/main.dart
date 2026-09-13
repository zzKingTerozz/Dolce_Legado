import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const DolceLegadoApp());
}

class DolceLegadoApp extends StatelessWidget {
  const DolceLegadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dolce Legado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}