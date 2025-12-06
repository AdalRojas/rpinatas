import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para escuchar cambios de sesión en tiempo real
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // LOGIN
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Null significa éxito
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Error desconocido en Login";
    } catch (e) {
      return "Error: $e";
    }
  }

  // REGISTRO
  Future<String?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento de usuario en Firestore
      await _db.collection('users').doc(result.user!.uid).set({
        'email': email,
        'fullName': name,
        'role': 'client', // Por defecto todos son clientes
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Error al registrarse";
    }
  }

  // CERRAR SESIÓN
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- NUEVA FUNCIÓN: OBTENER ROL ---
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc =
            await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          // Devuelve el campo 'role' o 'client' si no existe
          return doc.get('role') ?? 'client';
        }
      } catch (e) {
        print("Error obteniendo rol: $e");
      }
    }
    return 'client';
  }
}
