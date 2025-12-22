import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth=FirebaseAuth.instance;
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;

//giriş yapma
Future<User?> signIn(String email, String password)async{
  try{
    UserCredential result=await _auth.signInWithEmailAndPassword(email:email,password:password);
    return result.user;
  }catch(e){
    rethrow;
  }
}

Future<User?> signUp(String email,String password)async{
  try{
    UserCredential result=await _auth.createUserWithEmailAndPassword(email:email,password:password);

    await _firestore.collection('users').doc(result.user!.uid).set({
      'email':email,
      'score':0,
      'level':1,
      'createdAt':FieldValue.serverTimestamp(),
    });
    return result.user;
  }catch(e){
    rethrow;
  }
}

Future<void> signOut()async{
  await _auth.signOut();
}
}