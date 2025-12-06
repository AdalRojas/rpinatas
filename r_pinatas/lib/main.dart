import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth_wrapper.dart'; // <--- IMPORT NUEVO
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFFCC2F6E),
            primary: Color(0xFFCC2F6E),
            secondary: Color(0xFF3FAAA9),
            tertiary: Color(0xFFF1BA25),
            background: Color(0xFFF7FBF9),
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: Color(0xFFF7FBF9),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFFCC2F6E),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFCC2F6E),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: AuthWrapper(), // Usamos el widget importado
      ),
    );
  }
}
