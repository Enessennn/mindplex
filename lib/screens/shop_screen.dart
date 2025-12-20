import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/database_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // Temalar silindi, sadece eşyalar kaldı
  final List<Map<String, dynamic>> shopItems = [
    {
      "id": "hint_pack",
      "name": "5'li İpucu",
      "desc": "Zorlandığında kullan.",
      "price": 250,
      "icon": Icons.lightbulb_circle,
      "color": Colors.orange
    },
    {
      "id": "avatar_king",
      "name": "Kral Avatarı",
      "desc": "Profilinde taç gözüksün.",
      "price": 15000,
      "icon": Icons.emoji_events,
      "color": Colors.amber
    },
    {
      "id": "iphone_17",
      "name": "iPhone 17",
      "desc": "En üst rütbe sembolü.",
      "price": 55000,
      "icon": Icons.phone_iphone,
      "color": Colors.black87
    },
  ];

  void _buyItem(String itemId, int price, String itemName) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$itemName Satın Al"),
        content: Text("$price MP ödemek istiyor musun?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text("SATIN AL"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    bool success = await DatabaseService().purchaseItem(price, itemId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? "Başarılı! 🎉" : "Yetersiz Bakiye!"),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold arka planını şeffaf yapıyoruz ki main.dart'taki gradient görünsün
    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text('Mağaza', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Color(0xFF2D3142))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: DatabaseService().getUserStream(),
            builder: (context, snapshot) {
              int score = 0;
              if (snapshot.hasData && snapshot.data!.data() != null) {
                score = (snapshot.data!.data() as Map<String, dynamic>)['score'] ?? 0;
              }
              // Puan Göstergesi (Chip Stilinde)
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Text(
                    "$score MP", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16)
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DatabaseService().getUserStream(),
        builder: (context, snapshot) {
          List<dynamic> inventory = [];
          if (snapshot.hasData && snapshot.data!.data() != null) {
            inventory = (snapshot.data!.data() as Map<String, dynamic>)['inventory'] ?? [];
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.75, // Kartları biraz daha uzun yaptık
              crossAxisSpacing: 15, 
              mainAxisSpacing: 15
            ),
            itemCount: shopItems.length,
            itemBuilder: (context, index) {
              final item = shopItems[index];
              bool isOwned = inventory.contains(item['id']);
              bool isConsumable = item['id'] == 'hint_pack';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65), // Buzlu Cam Efekti
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: item['color'].withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // İkon Alanı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'], size: 36, color: item['color']),
                    ),
                    const SizedBox(height: 12),
                    
                    // İsim ve Açıklama
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        item['desc'], 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Fiyat
                    Text("${item['price']} MP", style: TextStyle(color: item['color'], fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),

                    // Buton
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: (isOwned && !isConsumable)
                          ? Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text("SAHİPSİN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          : ElevatedButton(
                              onPressed: () => _buyItem(item['id'], item['price'], item['name']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D3142), // Koyu renk buton
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("SATIN AL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}