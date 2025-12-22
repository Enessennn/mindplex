import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Dosya yapına uygun importlar:
import 'service/database_service.dart';
import 'screens/word_game_screen.dart';
import 'screens/english_game_screen.dart';
import 'screens/login_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/profile_screen.dart';
// import 'app_theme.dart'; // Temayı buradan manuel vereceğimiz için kapattım

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MindPlexApp());
}

class MindPlexApp extends StatelessWidget {
  const MindPlexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindPlex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Arka planı gradient ile yöneteceğiz ama varsayılanı temiz tutalım
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        fontFamily: 'Roboto', // Varsa özel fontunu ekleyebilirsin
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            if (snapshot.data!.emailVerified) {
              return const MainScreen();
            } else {
              return const VerifyEmailScreen();
            }
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // Sayfalarımız
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      RealHomeScreen(onNavigate: _onItemTapped), 
      const GameHomeScreen(),                     
      const ShopScreen(),                         
      const ProfileScreen(),                      
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Stack: Arka plan gradientinin üzerine sayfayı ve menüyü koymak için
      body: Stack(
        children: [
          // 1. KATMAN: Global Arka Plan Gradienti (Tüm uygulama burada çalışır)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0EAFC), // Çok açık mavi/gri
                  Color(0xFFCFDEF3), // Biraz daha koyu ton
                ],
              ),
            ),
          ),
          
          // 2. KATMAN: Sayfa İçeriği
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80), // Menü için boşluk bırak
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),

          // 3. KATMAN: Yüzen Alt Menü (Modern Floating Navbar)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9), // Hafif saydam beyaz
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
                    BottomNavigationBarItem(icon: Icon(Icons.gamepad_rounded), label: 'Oyunlar'),
                    BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Mağaza'),
                    BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: const Color(0xFF6A11CB), // Seçili İkon Rengi (Mor)
                  unselectedItemColor: Colors.grey.shade400,
                  onTap: _onItemTapped,
                  backgroundColor: Colors.transparent, // Container rengini kullan
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  showUnselectedLabels: false, // Seçili olmayanların yazısını gizle (Sadeleştirme)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- YARDIMCI WIDGET: CAM KART (GLASS CARD) ---
// Kod tekrarını önlemek için özel widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;

  const GlassCard({super.key, required this.child, this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.70), // %70 Opak Beyaz
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// --- ANA SAYFA ---
class RealHomeScreen extends StatelessWidget {
  final Function(int) onNavigate;
  const RealHomeScreen({super.key, required this.onNavigate});

  // Rütbe Bilgisini Hesaplama
  Map<String, dynamic> getRankDetails(List<dynamic> inventory) {
    bool hasIphone = inventory.contains('iphone_17');
    bool hasKing = inventory.contains('avatar_king');

    if (hasIphone) {
      return {'title': 'İmparator', 'icon': Icons.diamond, 'colors': [const Color(0xFF232526), const Color(0xFF414345)], 'text': Colors.white};
    } else if (hasKing) {
      return {'title': 'Kral', 'icon': Icons.emoji_events, 'colors': [Colors.orange.shade600, Colors.amber.shade400], 'text': Colors.white};
    } else {
      return {'title': 'Çaylak', 'icon': Icons.rocket_launch, 'colors': [const Color(0xFF6A11CB), const Color(0xFF2575FC)], 'text': Colors.white};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          const Text('MindPlex', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
          
          StreamBuilder<DocumentSnapshot>(
            stream: DatabaseService().getUserStream(),
            builder: (context, snapshot) {
              String name = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? "Misafir";
              return Text('Hoş geldin, $name 👋', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500));
            }
          ),
          
          const SizedBox(height: 25),

          // --- ANA RÜTBE KARTI ---
          StreamBuilder<DocumentSnapshot>(
            stream: DatabaseService().getUserStream(),
            builder: (context, snapshot) {
              int score = 0;
              List<dynamic> inventory = [];
              if (snapshot.hasData && snapshot.data!.data() != null) {
                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                score = data['score'] ?? 0;
                inventory = data['inventory'] ?? [];
              }
              final rank = getRankDetails(inventory);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: rank['colors']),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: (rank['colors'][0] as Color).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rank['title'], style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 5),
                            const Text('Mevcut Servet', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: Icon(rank['icon'], color: Colors.white, size: 24),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$score MP', 
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 30),
          const Text("Hızlı Menü", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 15),

          // --- CAM KARTLAR İLE MENÜ ---
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  onTap: () => onNavigate(1), // Oyunlara git
                  child: const Column(
                    children: [
                      Icon(Icons.gamepad, size: 32, color: Color(0xFF4CAF50)),
                      SizedBox(height: 10),
                      Text("Oyna", style: TextStyle(fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GlassCard(
                  onTap: () => onNavigate(2), // Mağazaya git
                  child: const Column(
                    children: [
                      Icon(Icons.shopping_bag, size: 32, color: Color(0xFFFF5252)),
                      SizedBox(height: 10),
                      Text("Harca", style: TextStyle(fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          GlassCard(
            onTap: () => onNavigate(3), // Profile git
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.blue)),
                    const SizedBox(width: 15),
                    const Text("Profil & Koleksiyon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- OYUNLAR EKRANI ---


class GameHomeScreen extends StatelessWidget {
  const GameHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold arka planı şeffaf, böylece ana gradient görünür
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Alt menü için boşluk
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık Alanı
            const Text(
              'Oyun Alanı', 
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF2D3142),
                letterSpacing: -0.5
              )
            ),
            const SizedBox(height: 5),
            Text(
              'Bugün hangi yeteneğini geliştireceksin?', 
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 25),

            // --- KELİME OYUNU KARTI (YEŞİL TEMA) ---
            _buildPremiumGameCard(
              context,
              title: "Kelime Oyunu",
              subtitle: "Harfleri birleştir, zekanı konuştur.",
              reward: "50 MP",
              gradientColors: [const Color(0xFF43E97B), const Color(0xFF38F9D7)], // Yeşil Gradient
              icon: Icons.spellcheck,
              targetPage: const WordGameScreen(),
            ),

            const SizedBox(height: 20),

            // --- İNGİLİZCE PRATİK KARTI (MAVİ TEMA) ---
            _buildPremiumGameCard(
              context,
              title: "İngilizce Pratik",
              subtitle: "Kelime dağarcığını test et.",
              reward: "10 MP",
              gradientColors: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Mavi Gradient
              icon: Icons.translate,
              targetPage: const EnglishGameScreen(),
            ),

            const SizedBox(height: 40),

            // --- GELECEK OYUNLAR (PASİF KART) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.rocket_launch, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    "Yeni Oyunlar Yolda!", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Çok yakında eklenecek...", 
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String reward,
    required List<Color> gradientColors,
    required IconData icon,
    required Widget targetPage,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7), // Buzlu Cam
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.2), // Kartın rengine göre gölge
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // SOL TARAFTAKİ RENKLİ ALAN
            Container(
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: Center(
                child: Icon(icon, size: 40, color: Colors.white),
              ),
            ),
            
            // SAĞ TARAFTAKİ İÇERİK
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Başlık
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFF2D3142)
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Alt Başlık
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    
                    // Alt Satır: Ödül ve Buton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ödül Etiketi
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: gradientColors[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.bolt, size: 14, color: gradientColors[0]),
                              const SizedBox(width: 4),
                              Text(
                                "+$reward", 
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold, 
                                  color: gradientColors[0]
                                )
                              ),
                            ],
                          ),
                        ),
                        
                        // Küçük Oyna İkonu
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black54, size: 20),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}