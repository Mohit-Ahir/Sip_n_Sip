import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // Crash-proof Image display
  Widget displayImage(String base64Str) {
    try {
      if (base64Str.isEmpty) return const Icon(Icons.local_cafe, size: 45, color: Colors.brown);
      return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: double.infinity, gaplessPlayback: true);
    } catch (e) {
      return const Icon(Icons.local_cafe, size: 45, color: Colors.brown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), 
      
      // MODERN APP BAR
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
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: Colors.brown, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 10),
                  
                  // 1. PERSONALIZED GREETING
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('Users').doc(currentUserEmail).get(),
                    builder: (context, snapshot) {
                      String name = "Coffee Lover";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        name = snapshot.data!['name'].toString().split(" ")[0]; // Gets First Name
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Good Morning, $name ☀️", style: TextStyle(fontSize: 16, color: Colors.brown.shade600, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          Text("What would you like\nto drink today?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.brown.shade900, height: 1.2)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  // 2. MODERN SEARCH BAR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search for latte, espresso...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: Colors.brown),
                      ),
                      onTap: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
                      },
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 3. PROMOTIONAL BANNER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.brown.shade800, Colors.brown.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                                child: const Text("PROMO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                              const Text("Buy 1 Get 1 Free\non all Espressos!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
                            ],
                          ),
                        ),
                        const Icon(Icons.local_cafe, size: 60, color: Colors.white70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // TITLE FOR GRID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Popular Coffee", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown.shade900)),
                      TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories())), child: const Text("See All", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)))
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 4. PREMIUM GRID CARDS
                  StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('Products').where('isPopular', isEqualTo: true).snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.brown));
                      if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No popular items yet"));

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(), // Important: Lets ListView handle scrolling
                        shrinkWrap: true,
                        itemCount: snapshot.data!.docs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75, // Better ratio
                        ),
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          var productData = doc.data() as Map<String, dynamic>; 

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsPage(productData: productData)));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // IMAGE AREA
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        child: displayImage(productData['image'] ?? ""),
                                      ),
                                    ),
                                  ),
                                  // TEXT AREA
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(productData['name'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        // MODERN PRICE + ADD BUTTON ROW
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("₹${productData['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 16)),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(10)),
                                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30), // Padding at bottom of list
                ],
              ),
            ),
          ],
        ),
      ),
      
      // ROUNDED FLOATING-STYLE BOTTOM NAV (WITH LABELS)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
          child: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.brown, 
            unselectedItemColor: Colors.grey.shade500, // Slightly darker grey for readability
            
            // CHANGES MADE HERE: Show Labels and set font size
            showUnselectedLabels: true, 
            showSelectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            
            elevation: 0,
            onTap: (value) {
              if (value == 0) return;
              if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
              if (value == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Cart()));
              if (value == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Orderr()));
              if (value == 4) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserProfile()));
            },
            items: const [
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_filled, size: 24)), label: "Home"),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.menu_book_rounded, size: 24)), label: "Menu"),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.shopping_cart_rounded, size: 24)), label: "Cart"),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.receipt_long_rounded, size: 24)), label: "Orders"),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded, size: 24)), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}