import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import '../service/word_service.dart';
import '../service/database_service.dart';

class EnglishGameScreen extends StatefulWidget {
  const EnglishGameScreen({super.key});

  @override
  State<EnglishGameScreen> createState() => _EnglishGameScreenState();
}

class _EnglishGameScreenState extends State<EnglishGameScreen> {
  final WordService _wordService = WordService();
  
  // Değişkenler..
  String soruMetni = "Yükleniyor...";
  String dogruCevap = "";
  List<String> siklar = [];
  bool isLoading = true;
  
  // Bu yerel puan değişkeni sadece oturum takibi için kalsın, 
  // ama ekranda artık veritabanındaki puanı göstereceğiz.
  int sessionPuan = 0; 

  @override
  void initState() {
    super.initState();
    _yeniSoruGetir();
  }

  Future<void> _yeniSoruGetir() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      soruMetni = "Soru hazırlanıyor...";
    });

    var soruPaketi = await _wordService.rastgeleSoruGetir();

    if (soruPaketi != null) {
      String gelenKelime = soruPaketi['kelime']!;
      String gelenTanim = soruPaketi['tanim']!;

      List<String> secenekler = _wordService.yanlisSikGetir(3, gelenKelime);
      secenekler.add(gelenKelime);
      secenekler.shuffle(); // Şıkları karıştır

      if (mounted) {
        setState(() {
          dogruCevap = gelenKelime;
          soruMetni = gelenTanim;
          siklar = secenekler;
          isLoading = false;
        });
      }
    } else {
      // Eğer kelime yüklenemezse tekrar dene
      if (mounted) _yeniSoruGetir();
    }
  }

  void _cevabiKontrolEt(String secilen) {
    bool dogruMu = secilen == dogruCevap;

    if (dogruMu) {
      // Doğruysa veritabanına 10 puan ekle
      DatabaseService().addScore(10);
      setState(() { sessionPuan += 10; });
    } else {
      // Yanlışsa veritabanından 5 puan sil
      DatabaseService().addScore(-5);
      setState(() { sessionPuan -= 5; });
    }

    // Kullanıcıya bilgi ver (SnackBar)
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Varsa eski mesajı sil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          dogruMu ? "Doğru Cevap! (+10 Puan)" : "Yanlış! Doğrusu: $dogruCevap (-5 Puan)",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: dogruMu ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating, 
      ),
    );

    // Yanlış da olsa doğru da olsa 1.2 saniye sonra yeni soruya geç
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _yeniSoruGetir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("English Word Game"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // --- CANLI PUAN GÖSTERGESİ (BURASI DEĞİŞTİ) ---
          StreamBuilder<DocumentSnapshot>(
            stream: DatabaseService().getUserStream(), // Bankacıyı dinliyoruz
            builder: (context, snapshot) {
              // Veri gelene kadar veya hata varsa ... göster
              String displayScore = "...";
              
              if (snapshot.hasData && snapshot.data!.data() != null) {
                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                int currentDbScore = data['score'] ?? 0;
                displayScore = "$currentDbScore";
              }

              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellowAccent, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      displayScore, // Veritabanından gelen canlı puan
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
          // ----------------------------------------------
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- SORU KARTI ---
            Expanded(
              flex: 2,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "DEFINITION",
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        isLoading
                           ? const CircularProgressIndicator()
                            : Container(
                                constraints: const BoxConstraints(maxHeight: 150), 
                                child: SingleChildScrollView( 
                                  child: Text(
                                    soruMetni,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // --- ŞIKLAR ---
            Expanded(
              flex: 3,
              child: isLoading
                  ? const SizedBox()
                  : ListView.builder(
                      itemCount: siklar.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                            ),
                            onPressed: () => _cevabiKontrolEt(siklar[index]),
                            child: Text(
                              siklar[index].toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}