import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth_wrapper.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  // 1. NUEVO CONTROLADOR PARA EL NOMBRE
  final _nameController = TextEditingController();

  final AuthService _auth = AuthService();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose(); // Limpiamos el nuevo controlador
    super.dispose();
  }

  void _submit() async {
    // 1. OCULTAR TECLADO (Para que no tape el mensaje de error)
    FocusScope.of(context).unfocus();

    // Validación básica de campos vacíos
    if (_emailController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Escribe correo y contraseña"),
          backgroundColor: Colors.orange));
      return;
    }

    // 2. VALIDAR QUE ESCRIBIÓ EL NOMBRE (SOLO EN REGISTRO)
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Por favor escribe tu nombre"),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    // DEBUG: Ver qué está pasando
    print("Enviando a Firebase... Correo: ${_emailController.text}");

    String? error;
    try {
      if (_isLogin) {
        // LOGIN
        error = await _auth.signIn(
          _emailController.text.trim(),
          _passController.text.trim(),
        );
      } else {
        // REGISTRO
        error = await _auth.signUp(
            _emailController.text.trim(),
            _passController.text.trim(),
            _nameController.text.trim() // <--- 3. AQUÍ MANDAMOS EL NOMBRE REAL
            );
      }
    } catch (e) {
      error = "Excepción no controlada: $e";
    }

    // DEBUG: Ver si regresó error
    print("Resultado de Firebase (Error): $error");

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      // Manejo de errores traducidos
      String message = "Ocurrió un error";

      if (error.contains('email-already-in-use')) {
        message = "¡ALTO! Este correo YA existe. Intenta iniciar sesión.";
      } else if (error.contains('user-not-found') ||
          error.contains('INVALID_LOGIN_CREDENTIALS')) {
        message = "Credenciales incorrectas.";
      } else if (error.contains('wrong-password')) {
        message = "Contraseña incorrecta.";
      } else if (error.contains('weak-password')) {
        message = "La contraseña es muy débil (mínimo 6 caracteres).";
      } else if (error.contains('invalid-email')) {
        message = "El correo no es válido.";
      } else {
        message = "Error del servidor: $error";
      }

      // Mostrar alerta
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ));
    } else {
      // Éxito -> Ir al AuthWrapper
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthWrapper()),
        (route) => false,
      );
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _emailController.clear();
      _passController.clear();
      _nameController.clear(); // Limpiamos nombre también
    });
  }

  void _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Escribe tu correo arriba primero")));
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Correo enviado. Revisa tu bandeja."),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al enviar correo"),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 150,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) =>
                      Icon(Icons.person_pin, size: 100, color: Colors.pink),
                ),
              ),
              SizedBox(height: 30),
              Text(_isLogin ? "Bienvenido de nuevo" : "Crear Cuenta",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor)),
              SizedBox(height: 20),

              // 4. CAMPO DE NOMBRE (SOLO VISIBLE EN REGISTRO)
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Nombre Completo",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 15),
              ],

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Correo Electrónico",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text("¿Olvidaste tu contraseña?"),
                  ),
                ),

              SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(_isLogin ? "INGRESAR" : "CREAR CUENTA",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              SizedBox(height: 20),

              TextButton(
                onPressed: _toggleMode,
                child: Text(
                  _isLogin
                      ? "¿No tienes cuenta? Regístrate"
                      : "¿Ya tienes cuenta? Ingresa",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
