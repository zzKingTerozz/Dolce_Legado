import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true; // Variable para controlar la visibilidad

  void _login() async {
    if (_userController.text == 'Miguel' && _passwordController.text == '12345') {
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales incorrectas.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/Logo.png', height: 120),
              const SizedBox(height: 40),
              
              TextField(
                controller: _userController,
                style: const TextStyle(color: Color(0xFF4A2A18)), // Texto marrón oscuro
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF4A2A18)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword, // Vinculado a la variable
                style: const TextStyle(color: Color(0xFF4A2A18)),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF4A2A18)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // Botón del Ojo
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword; // Alterna entre ver y ocultar
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              Theme(
                data: ThemeData(unselectedWidgetColor: Colors.grey),
                child: CheckboxListTile(
                  title: const Text('Recordarme', style: TextStyle(color: Color(0xFF4A2A18))),
                  value: _rememberMe,
                  activeColor: const Color(0xFFE8DAD3),
                  checkColor: const Color(0xFF4A2A18),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (bool? value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8DAD3),
                    foregroundColor: const Color(0xFF4A2A18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _login,
                  child: const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}