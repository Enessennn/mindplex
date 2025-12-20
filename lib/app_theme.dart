import 'package:flutter/material.dart';

// --- ANA RENK PALETİ ---
const kPrimaryColor = Color(0xFF6F35A5); // Ana Mor
const kPrimaryLightColor = Color(0xFFF1E6FF); // Açık Mor
const kCardColor = Colors.white; 
const kBackgroundColor = Color(0xFFF5F7FA);

// --- OYUN İÇİN GEREKLİ EKSİK RENKLER (Hataları Çözen Kısım) ---
const kTextColor = Color(0xFF2D3142); // Koyu Gri Yazı Rengi

// Oyun içi seviye/buton renkleri
const kGame1Color = Color(0xFF4CAF50); // Yeşil
const kGame2Color = Color(0xFF2196F3); // Mavi
const kGame3Color = Color(0xFFFF9800); // Turuncu
const kGame4Color = Color(0xFFFF5252); // Kırmızı/Mercan (Kelime oyununda seçili harf vs.)

// --- SABİTLER ---
const double kDefaultPadding = 20.0;

// --- TEMA AYARLARI ---
ThemeData buildThemeData() {
  return ThemeData(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kBackgroundColor,
    useMaterial3: true,
    fontFamily: 'Roboto', 
    
    // Renk Şeması
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      primary: kPrimaryColor,
      secondary: kGame1Color, 
    ),

    // AppBar Teması
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: kTextColor),
      titleTextStyle: TextStyle(
        color: kTextColor, 
        fontSize: 20, 
        fontWeight: FontWeight.bold
      ),
    ),

    // Buton Teması
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        maximumSize: const Size(double.infinity, 56),
        minimumSize: const Size(double.infinity, 56),
      ),
    ),

    // Input Teması
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: kPrimaryLightColor,
      iconColor: kPrimaryColor,
      prefixIconColor: kPrimaryColor,
      contentPadding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding, vertical: kDefaultPadding),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide.none,
      ),
    ),
    
    iconTheme: const IconThemeData(color: kPrimaryColor),
  );
}