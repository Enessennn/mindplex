import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class WordService {
  List<String> _kelimeListesi = [];

  // 1. JSON dosyasını okuyan fonksiyon
  Future<void> kelimeListesiniYukle() async {
    try {
      // DİKKAT: Burada senin verdiğin yeni dosya ismini kullanıyoruz
      final String response = await rootBundle.loadString('assets/english_words.json');
      
      final List<dynamic> data = json.decode(response);
      _kelimeListesi = data.map((e) => e.toString()).toList();
      
      print("Kelime listesi yüklendi. Toplam kelime: ${_kelimeListesi.length}");
    } catch (e) {
      print("JSON okuma hatası: $e");
      // Hata olursa boş liste kalmasın diye varsayılan birkaç kelime ekleyelim
      _kelimeListesi = ["apple", "banana", "computer"]; 
    }
  }

  // 2. Rastgele soru getiren fonksiyon
  Future<Map<String, String>?> rastgeleSoruGetir() async {
    // Liste boşsa yükle
    if (_kelimeListesi.isEmpty) {
      await kelimeListesiniYukle();
    }

    _kelimeListesi.shuffle();

    if (_kelimeListesi.isEmpty) return null;

    Random random = Random();
    String secilenKelime = _kelimeListesi[random.nextInt(_kelimeListesi.length)];

    try {
      final url = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$secilenKelime');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        
        // Bazen API'de definitions kısmı boş olabilir, kontrol edelim
        var meanings = data[0]['meanings'];
        if (meanings != null && meanings.isNotEmpty) {
           String tanim = meanings[0]['definitions'][0]['definition'];
           return {
             "kelime": secilenKelime,
             "tanim": tanim
           };
        }
        return await rastgeleSoruGetir(); // Tanım yoksa başka kelime dene
      } else {
        print("API'de bulunamadı: $secilenKelime");
        return await rastgeleSoruGetir(); // Hata varsa başka kelime dene
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return null;
    }
  }

  // Yanlış şıkları üreten fonksiyon
  List<String> yanlisSikGetir(int adet, String dogruCevap) {
    if (_kelimeListesi.isEmpty) return ["Error", "Error", "Error"];
    
    List<String> kopyaListe = List.from(_kelimeListesi);
    kopyaListe.remove(dogruCevap);
    kopyaListe.shuffle();
    
    // Eğer listede yeterince kelime yoksa hata vermesin diye kontrol
    int alinanAdet = adet > kopyaListe.length ? kopyaListe.length : adet;
    
    return kopyaListe.sublist(0, alinanAdet);
  }
}