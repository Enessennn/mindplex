import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- ANLIK VERİ AKIŞI ---
  Stream<DocumentSnapshot> getUserStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  // --- PUAN EKLEME / ÇIKARMA ---
  Future<void> addScore(int newPoints) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'score': FieldValue.increment(newPoints),
    });
  }

  // --- SATIN ALMA (GÜNCELLENDİ) ---
  Future<bool> purchaseItem(int cost, String itemId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentReference userRef = _firestore.collection('users').doc(user.uid);
    DocumentSnapshot snapshot = await userRef.get();
    
    if (!snapshot.exists) return false;
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    
    int currentScore = data['score'] ?? 0;
    List<dynamic> inventory = data['inventory'] ?? [];

    if (currentScore < cost) return false; // Para yetmiyor

    // ÖZEL DURUM: İpucu Paketi (Sürekli alınabilir)
    if (itemId == 'hint_pack') {
      await userRef.update({
        'score': FieldValue.increment(-cost),
        'free_hints': FieldValue.increment(5), // 5 tane hak ekle
      });
      return true;
    }

    // NORMAL EŞYA (1 kere alınabilir)
    if (inventory.contains(itemId)) return true; // Zaten var

    await userRef.update({
      'score': FieldValue.increment(-cost),
      'inventory': FieldValue.arrayUnion([itemId]),
    });

    return true;
  }

  // --- ÜCRETSİZ İPUCU KULLAN ---
  Future<void> useFreeHint() async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).update({
      'free_hints': FieldValue.increment(-1),
    });
  }

  
}