import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  bool _isLogin = true;

  // RECUPERAR CONTRASEÑA ---
  void _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escribe tu correo para recuperar la contraseña"),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Correo Enviado"),
          content: Text(
            "Hemos enviado un enlace de recuperación a ${_emailController.text}. Revisa tu bandeja.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Aceptar"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
  // -------------------------------------------

  void _submit() async {
    setState(() => _isLoading = true);
    String? error;

    // Pequeña validación local
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor llena todos los campos")));
      return;
    }

    if (_isLogin) {
      error = await _auth.signIn(
          _emailController.text.trim(), _passwordController.text.trim());
    } else {
      error = await _auth.signUp(_emailController.text.trim(),
          _passwordController.text.trim(), "Usuario Nuevo");
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      // Si hubo error, lo mostramos y nos quedamos aquí
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else {
      // --- 2. AQUÍ ESTÁ EL ARREGLO ---
      // Si NO hubo error (éxito), forzamos la navegación al Portero (AuthWrapper)
      // para que él decida si mandarnos al Home o al Dashboard.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthWrapper()),
        (route) => false,
      );
    }
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor llena todos los campos")));
      return;
    }

    if (_isLogin) {
      error = await _auth.signIn(
          _emailController.text.trim(), _passwordController.text.trim());
    } else {
      error = await _auth.signUp(_emailController.text.trim(),
          _passwordController.text.trim(), "Usuario Nuevo");
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      // Si hubo error, lo mostramos y nos quedamos aquí
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else {
      // --- 2. AQUÍ ESTÁ EL ARREGLO ---
      // Si NO hubo error (éxito), forzamos la navegación al Portero (AuthWrapper)
      // para que él decida si mandarnos al Home o al Dashboard.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 150,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported,
                        size: 80, color: Colors.grey);
                  },
                ),
              ),
              const Text(
                "R Piñatas",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isLogin ? "Bienvenido de nuevo" : "Crea tu cuenta",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo Electrónico",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),

              // --- BOTÓN OLVIDÉ CONTRASEÑA (Solo en Login) ---
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(color: Colors.pink),
                    ),
                  ),
                ),

              // -----------------------------------------------
              const SizedBox(height: 24),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _isLogin ? "INGRESAR" : "REGISTRARSE",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? "¿No tienes cuenta?" : "¿Ya tienes cuenta?"),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? "Regístrate aquí" : "Inicia sesión"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
