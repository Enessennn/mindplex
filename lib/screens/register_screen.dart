import 'package:flutter/material.dart';
import 'package:mindeplex/screens/verify_email_screen.dart';
import '../service/auth_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;

  void _kayitOl() async {
    // 1. Basit Kontrol: Alanlar boş mu?
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun")));
       return;
    }
    
    setState(() { isLoading = true; });

    try {
      // 2. Firebase'e kayıt isteği at
      await _authService.signUp(
        _emailController.text.trim(), 
        _passwordController.text.trim()
      );
      
      // 3. Başarılıysa: Geçmişi sil ve Ana Ekrana git (Geri tuşu login'e dönmesin diye)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const VerifyEmailScreen()), 
          (route) => false
        );
      }
    } catch (e) {
      // Hata varsa göster
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kayıt Hatası: ${e.toString()}"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body:Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Yeni Hesap Oluştur",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26,fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            isLoading?const Center(child: CircularProgressIndicator())
            :ElevatedButton(
              onPressed: _kayitOl,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

              ),
              child: Text("Kayıt Ol",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
            ),
          ],
        ),
      )
    );
  }
}