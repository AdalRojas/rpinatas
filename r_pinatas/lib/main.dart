import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INICIALIZACIÓN DE FIREBASE
  // Si estás en WEB y te da error, intenta quitar "options: ..." solo para probar,
  // pero lo correcto es correr esto en un EMULADOR ANDROID.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(RPinatasApp());
}

class RPinatasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: MaterialApp(
        title: 'R Piñatas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.pink, useMaterial3: true),
        // ESTO CONTROLA SI VAS AL LOGIN O AL HOME
        home: StreamBuilder(
          stream: AuthService().authStateChanges,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasData) {
              return HomeScreen(); // Si hay usuario, vamos al catálogo
            }
            return LoginScreen(); // Si no, al login
          },
        ),
      ),
    );
  }
}
