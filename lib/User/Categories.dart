import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:sip_and_sip/User/Home.dart';
import 'package:sip_and_sip/User/UserProfile.dart';
import 'package:sip_and_sip/User/cart.dart';
import 'package:sip_and_sip/User/Order.dart';
import 'package:sip_and_sip/User/ProductDetailsPage.dart'; 

class Categories extends StatefulWidget {
  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  int currentIndex = 1;
  String searchQuery = "";
  final List<String> categoryList = ["Hot Coffee", "Cold Coffee", "Flavoured", "Special"];

  // Crash-proof Image display
  Widget displayImage(String base64Str) {
    try {
      if (base64Str.isEmpty) return const Icon(Icons.local_cafe, size: 45, color: Colors.brown);
      // Added width: double.infinity to make image fill the card header perfectly
      return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: double.infinity, gaplessPlayback: true);
    } catch (e) {
      return const Icon(Icons.local_cafe, size: 45, color: Colors.brown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), // Premium cream background matching Home
      
      // MODERN APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          "Our Menu", 
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.2)
        ),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // MODERN SEARCH BAR
            Container(
              margin: const EdgeInsets.only(bottom: 25),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search for your favorite coffee...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none, 
                  icon: const Icon(Icons.search, color: Colors.brown)
                ),
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              ),
            ),
            
            // DYNAMIC CATEGORY LOOP
            for (var category in categoryList)
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('Products').where('category', isEqualTo: category).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

                  // Search Filter Logic
                  var filteredDocs = snapshot.data!.docs.where((d) => (d.data() as Map<String,dynamic>)['name'].toString().toLowerCase().contains(searchQuery)).toList();
                  if (filteredDocs.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          category, 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown.shade900)
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDocs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          crossAxisSpacing: 15, 
                          mainAxisSpacing: 15, 
                          childAspectRatio: 0.75, // Taller card ratio like Home Page
                        ),
                        itemBuilder: (context, index) {
                          var doc = filteredDocs[index];
                          var productData = doc.data() as Map<String, dynamic>;

                          return GestureDetector(
                            onTap: () {
                              // GO TO PRODUCT DETAILS PAGE
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProductDetailsPage(productData: productData)),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(20), 
                                boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // BIG IMAGE SECTION
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), 
                                        child: displayImage(productData['image'] ?? "")
                                      ),
                                    ),
                                  ),
                                  
                                  // TEXT & PRICE SECTION
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(productData['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        
                                        // MODERN PRICE + ADD ICON
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
                      ),
                      const SizedBox(height: 20), // Spacing between categories
                    ],
                  );
                },
              ),
              const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
      
      // ROUNDED FLOATING-STYLE BOTTOM NAV (Matches Home exactly)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.brown, 
            unselectedItemColor: Colors.grey.shade500,
            showUnselectedLabels: true, 
            showSelectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
            onTap: (value) {
              if (value == 1) return; // Already on Menu
              if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
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