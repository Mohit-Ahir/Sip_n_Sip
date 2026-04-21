import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:sip_and_sip/User/Categories.dart';
import 'package:sip_and_sip/User/Order.dart';
import 'package:sip_and_sip/User/UserProfile.dart';
import 'package:sip_and_sip/User/cart.dart';
import 'package:sip_and_sip/User/ProductDetailsPage.dart'; 

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning";
    if (hour >= 12 && hour < 17) return "Good Afternoon";
    if (hour >= 17 && hour < 21) return "Good Evening";
    return "Good Night";
  }

  String getGreetingEmoji() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "☀️";
    if (hour >= 12 && hour < 17) return "🌤️";
    if (hour >= 17 && hour < 21) return "🌆";
    return "🌙";
  }

  Widget displayImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(Icons.local_cafe, size: 45, color: Colors.brown);
    }
    try {
      if (imagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.brown.shade50,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.brown)),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
        return Image.memory(base64Decode(imagePath), fit: BoxFit.cover, width: double.infinity, gaplessPlayback: true);
      }
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    // WRAP SCAFFOLD WITH POPSCOPE
    return PopScope(
      canPop: false, // Block automatic exit
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // SHOW EXIT DIALOG
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFFF5E6D3),
            title: const Text("Exit App?", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
            content: const Text("Are you sure you want to close Sip & Sip? ☕", style: TextStyle(color: Colors.brown)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("No", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => SystemNavigator.pop(),
                child: const Text("Yes, Exit", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5E6D3), 
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          toolbarHeight: 70,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_cafe, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Text("Sip & Sip", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.2)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.brown, size: 28), onPressed: () {}),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 10),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('Users').doc(currentUserEmail).get(),
                      builder: (context, snapshot) {
                        String name = "Coffee Lover";
                        if (snapshot.hasData && snapshot.data!.exists) {
                          name = snapshot.data!['name'].toString().split(" ")[0];
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${getGreeting()}, $name ${getGreetingEmoji()}", style: TextStyle(fontSize: 16, color: Colors.brown.shade600, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 5),
                            Text("What would you like\nto drink today?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.brown.shade900, height: 1.2)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.brown.shade800, Colors.brown.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("LIMITED OFFER", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                SizedBox(height: 10),
                                Text("Get 20% OFF on your\nfirst purchase!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3)),
                              ],
                            ),
                          ),
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white60, size: 45),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Popular Coffee", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown.shade900)),
                        TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories())), child: const Text("See All", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('Products').where('isPopular', isEqualTo: true).snapshots(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.brown));
                        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No items found"));
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snapshot.data!.docs.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75),
                          itemBuilder: (context, index) {
                            var doc = snapshot.data!.docs[index];
                            var productData = doc.data() as Map<String, dynamic>; 
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsPage(productData: productData))),
                              child: Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5))]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))), child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(22)), child: displayImage(productData['image'])))),
                                    Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(productData['name'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown), overflow: TextOverflow.ellipsis), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("₹${productData['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 16)), Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: Colors.white, size: 18))])])),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 30), 
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
            child: BottomNavigationBar(
              currentIndex: 0, type: BottomNavigationBarType.fixed, backgroundColor: Colors.white, selectedItemColor: Colors.brown, unselectedItemColor: Colors.grey.shade400, showUnselectedLabels: true,
              onTap: (value) {
                if (value == 0) return;
                if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
                if (value == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Cart()));
                if (value == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Orderr()));
                if (value == 4) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserProfile()));
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: "Menu"),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: "Cart"),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: "Orders"),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}