import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- GİRİŞ YAP ---
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow; // Hatayı ekrana göstermek için UI'a gönder
    }
  }

  // --- KAYIT OL ---
  Future<User?> signUp(String email, String password) async {
    try {
      // 1. Kullanıcıyı oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // 2. Veritabanında (Firestore) onun için bir puan tablosu aç
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'score': 0,    // Başlangıç puanı
        'level': 1,    // Başlangıç leveli
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // --- ÇIKIŞ YAP ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}