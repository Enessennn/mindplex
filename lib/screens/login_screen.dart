import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import 'register_screen.dart'; 
import '../main.dart'; // Ana ekrana gitmek için

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;

  void _girisYap()async{
    if(_emailController.text.isEmpty ||_passwordController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen alanları doldurun")));
      return;
    }

    setState(() {
      isLoading=true;
    });

  try{
    await _authService.signIn(_emailController.text.trim(),_passwordController.text.trim());
    if(mounted){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const MainScreen()));
    }
  }catch(e){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Giriş Hatası"),backgroundColor: Colors.red,));
  }finally{
    if(mounted){
      setState(() {
        isLoading=false;
      });
    }
  }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment:MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_person,size: 100,color: Colors.deepPurple,),
            const SizedBox(height: 20),
            const Text("Hoşgeldiniz",textAlign: TextAlign.center,style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold,color: Colors.deepPurple)),
            const SizedBox(height: 40),

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

            isLoading? const Center(child: CircularProgressIndicator())
            :ElevatedButton(
              onPressed: _girisYap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical:16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: const Text("Giriş Yap",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 16),

            TextButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> const RegisterScreen()));
            }, 
              child: const Text("Hesabın Yok Mu? Kayıt Ol!")
            )
          ],
        ),
        ),
    );
  }
}