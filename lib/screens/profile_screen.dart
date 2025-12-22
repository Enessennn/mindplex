import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindeplex/screens/login_screen.dart';
import '../service/database_service.dart';
import '../service/auth_service.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Eşya Detayları
  Map<String, dynamic> getItemDetails(String itemId) {
    switch (itemId) {
      case 'iphone_17':
        // GÜNCELLEME: İmparator hissi için altın ikon ve simsiyah arka plan.
        return {'name': 'iPhone 17', 'icon': Icons.phone_iphone, 'color': Colors.amber, 'bg': Colors.black, 'rare': true};
      case 'avatar_king':
        return {'name': 'Kral Tacı', 'icon': Icons.emoji_events, 'color': Colors.amber, 'bg': Colors.amber.shade50, 'rare': true};
      case 'hint_pack':
        return {'name': 'İpucu', 'icon': Icons.lightbulb, 'color': Colors.orange, 'bg': Colors.orange.shade50, 'rare': false};
      default:
        return {'name': 'Eşya', 'icon': Icons.inventory, 'color': Colors.grey, 'bg': Colors.grey.shade50, 'rare': false};
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Çok açık gri/beyaz zemin
      body: StreamBuilder<DocumentSnapshot>(
        stream: DatabaseService().getUserStream(),
        builder: (context, snapshot) {
          int score = 0;
          List<dynamic> inventory = [];
          int freeHints = 0;

          if (snapshot.hasData && snapshot.data!.data() != null) {
            Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
            score = data['score'] ?? 0;
            inventory = data['inventory'] ?? [];
            freeHints = data['free_hints'] ?? 0;
          }

          // Rütbe Ayarları
          bool hasIphone = inventory.contains('iphone_17');
          bool hasKing = inventory.contains('avatar_king');

          String rankName = "Çaylak";
          Color themeColor = const Color(0xFF6C63FF); // Modern Mor
          IconData rankIcon = Icons.rocket_launch;

          if (hasIphone) {
            rankName = "İMPARATOR";
            themeColor = const Color(0xFF1A1A1A); // Lüks Siyah
            rankIcon = Icons.diamond;
          } else if (hasKing) {
            rankName = "KRAL";
            themeColor = const Color(0xFFFFB400); // Canlı Altın
            rankIcon = Icons.emoji_events;
          }

          int level = (score / 1000).floor() + 1;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(60),
                          bottomRight: Radius.circular(60),
                        ),
                        boxShadow: [
                          BoxShadow(color: themeColor.withValues(alpha: 0.4),blurRadius: 20,offset: const Offset(0, 10))
                        ]
                      ),
                      child: SafeArea(child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(onPressed: (){
                          AuthService().signOut();
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen()));//Login ekranına yönlendirme
                        }, icon: Icon(Icons.logout,color:Colors.white70),
                        tooltip: "Çıkış Yap",
                        ),
                      ),),
                    ),

                    Positioned(
                      bottom: -50,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FD),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1),blurRadius: 15,offset: const Offset(0, 10))
                          ]
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: Icon(rankIcon,size: 50,color: themeColor),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 100,
                      child: Column(
                        children: [
                          Text(
                            user?.email?.split('@')[0]??"Kullanıcı",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:Colors.white
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              rankName,style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 12,letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCleanStat("Seviye", "$level"),
                      Container(width: 1,height: 40,color: Colors.grey.shade300),
                      _buildCleanStat("Puan", "$score"),
                      Container(width: 1,height: 40,color:Colors.grey.shade300),
                      _buildCleanStat("İpucu", "$freeHints"),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Koleksiyonum",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.grey.shade800),),

                      const SizedBox(height: 15),
                      inventory.isEmpty
                      ?Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.shade100,blurRadius: 10,offset: Offset(0, 5))],
                        ),
                      ):GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: inventory.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemBuilder: (context, index) {
                          var item=getItemDetails(inventory[index]);
                          bool isRare=item['rare']==true;

                          return Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isRare?item['bg']:Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5)
                                )
                              ],
                              border: isRare?Border.all(color: item['color'],width: 1):Border.all(color: Colors.transparent),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:item['bg'],
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),blurRadius: 5)],
                                    ),
                                    child: Icon(item['icon'],color: item['color'],size: 24),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item['name'],style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,

                                            color: isRare&&item['bg']==Colors.black?Colors.white:Colors.black87
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isRare?"Nadir Eşya":"Standart",
                                          style: TextStyle(fontSize: 10,color: isRare&&item['bg']==Colors.black?Colors.grey:Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // Temiz İstatistik Widget'ı
  Widget _buildCleanStat(String label, String value) {
    return Column(
      children: [
        Text(
          value, 
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(), 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.5)
        ),
      ],
    );
  }
}