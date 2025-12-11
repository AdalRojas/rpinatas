import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter para saber si hay usuario activo (Stream)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Getter para obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // 1. INICIAR SESIÓN
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Null significa éxito
    } on FirebaseAuthException catch (e) {
      return e.code; // Devolvemos el código de error
    } catch (e) {
      return "Error desconocido: $e";
    }
  }

  // 2. REGISTRARSE (ACTUALIZADO CON NOMBRE)
  Future<String?> signUp(String email, String password, String fullName) async {
    try {
      // Crear usuario en Auth (Google)
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Guardar datos extra en Firestore (Base de datos)
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'role': 'client', // Por defecto todos son clientes
        'fullName': fullName, // <--- AQUÍ GUARDAMOS EL NOMBRE
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      return "Error desconocido: $e";
    }
  }

  // 3. CERRAR SESIÓN
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. RECUPERAR CONTRASEÑA
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 5. OBTENER ROL DEL USUARIO
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc['role'] ?? 'client';
      }
    }
    return 'client';
  }
}
