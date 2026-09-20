import 'package:dolce_legado/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

// Falta importar la ruta de tu archivo SplashScreen. 
// Para que VS Code lo haga solo, haz clic sobre la palabra "SplashScreen" más abajo, presiona "Ctrl + ." y selecciona "Import library..."

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Cambio de MyApp() por DolceLegadoApp()
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