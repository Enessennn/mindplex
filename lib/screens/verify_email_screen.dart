import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../service/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz kontrol et
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      sendVerificationEmail();
      
      // Her 3 saniyede bir otomatik kontrol et (Kullanıcı linke tıkladı mı diye)
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // Firebase'i yenile ki güncel durumu görsün
    await FirebaseAuth.instance.currentUser?.reload();
    
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      
      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
    } catch (e) {
      // Hata olursa sessiz kal veya logla
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer doğrulandıysa Ana Ekrana gönder
    if (isEmailVerified) {
      return const MainScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Email Doğrulama")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Lütfen Emailini Kontrol Et',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '${FirebaseAuth.instance.currentUser?.email} adresine bir doğrulama linki gönderdik.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(), // Otomatik kontrol edildiğini belli etsin
            const SizedBox(height: 24),
            const Text(
              "Linke tıkladıktan sonra seni otomatik içeri alacağız...",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.email),
              label: const Text("Tekrar Gönder"),
              onPressed: canResendEmail ? sendVerificationEmail : null,
            ),
            const SizedBox(height: 8),
            TextButton(
              child: const Text("Vazgeç / Çıkış Yap"),
              onPressed: () => AuthService().signOut(),
            )
          ],
        ),
      ),
    );
  }
}