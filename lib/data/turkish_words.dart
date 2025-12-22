import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// Global kelime listesi
List<String> kTurkishDictionary = [];

class WordRepository {
  static Future<void> loadDictionary() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/words.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      kTurkishDictionary = jsonList.map((e) => e.toString()).toList();
      print("Sözlük yüklendi: ${kTurkishDictionary.length} kelime");
    } catch (e) {
      print("HATA: Sözlük yüklenemedi! $e");
      kTurkishDictionary = ["KALEM", "KİTAP", "BİLGİSAYAR", "TELEFON"]; 
    }
  }
}