import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:sip_and_sip/User/CheckoutPage.dart';
import 'package:sip_and_sip/User/Home.dart';
import 'package:sip_and_sip/User/Categories.dart';
import 'package:sip_and_sip/User/Order.dart';
import 'package:sip_and_sip/User/UserProfile.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});
  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  int currentIndex = 2;
  String userEmail = FirebaseAuth.instance.currentUser!.email!;

  // Functions to update Firebase
  void updateQty(String docId, int newQty) {
    if (newQty < 1) return;
    FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').doc(docId).update({'qty': newQty});
  }

  void removeItem(String docId) {
    FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').doc(docId).delete();
  }

  // Crash-proof Image display
  Widget displayImage(String base64Str) {
    try {
      if (base64Str.isEmpty) return const Icon(Icons.local_cafe, size: 35, color: Colors.brown);
      return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: double.infinity, height: double.infinity, gaplessPlayback: true);
    } catch (e) {
      return const Icon(Icons.local_cafe, size: 35, color: Colors.brown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), // Premium cream background

      // MODERN APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          "My Cart", 
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.2)
        ),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.brown));
          
          var cartDocs = snapshot.data!.docs;
          double totalBill = 0;
          for (var d in cartDocs) { totalBill += (d['price'] * d['qty']); }

          // PREMIUM EMPTY STATE
          if (cartDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.brown.shade300),
                  const SizedBox(height: 15),
                  Text("Your cart is empty", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                  const SizedBox(height: 10),
                  Text("Looks like you haven't added\nany coffee yet.", textAlign: TextAlign.center, style: TextStyle(color: Colors.brown.shade400)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    var item = cartDocs[index];
                    var data = item.data() as Map<String, dynamic>;

                    // Grab Size and Sugar (Provide fallbacks if older items don't have it)
                    String size = data.containsKey('size') ? data['size'] : "Regular";
                    String sugar = data.containsKey('sugar') ? data['sugar'] : "Normal Sugar";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                      ),
                      child: Row(
                        children: [
                          // IMAGE BOX
                          Container(
                            height: 75, width: 75,
                            decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(15)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15), 
                              child: displayImage(item['image'] ?? "")
                            ),
                          ),
                          const SizedBox(width: 15),

                          // INFO SECTION
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                // Display Customization
                                Text("$size • $sugar", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text("₹${item['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 16)),
                              ],
                            ),
                          ),

                          // SLEEK QUANTITY & DELETE CONTROLS
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => removeItem(item.id),
                                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => updateQty(item.id, item['qty'] - 1),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.brown.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.remove, size: 16, color: Colors.brown),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(item['qty'].toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ),
                                  GestureDetector(
                                    onTap: () => updateQty(item.id, item['qty'] + 1),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),

              // PREMIUM CHECKOUT PANEL
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))]
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Payment", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
                        Text("₹$totalBill", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.brown)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutPage())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown, 
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: const Text("Checkout", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // ROUNDED FLOATING-STYLE BOTTOM NAV (Matches Home perfectly)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Ensure background is white to prevent overlap issues
        ),
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
            if (value == 2) return;
            if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
            if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
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
    );
  }
}