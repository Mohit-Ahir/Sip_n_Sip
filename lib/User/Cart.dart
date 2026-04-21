import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void updateQty(String docId, int newQty) {
    if (newQty < 1) return;
    FirebaseFirestore.instance
        .collection('Carts')
        .doc(userEmail)
        .collection('Items')
        .doc(docId)
        .update({'qty': newQty});
  }

  void removeItem(String docId) {
    FirebaseFirestore.instance
        .collection('Carts')
        .doc(userEmail)
        .collection('Items')
        .doc(docId)
        .delete();
  }

  Widget displayImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.local_cafe, size: 30, color: Colors.brown);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.brown.shade200),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), 

      // 1. UPDATED APP BAR (MATCHING PREMIUM DESIGN)
      appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: const Text(
          "My Cart", 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 22, 
            letterSpacing: 1.2
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Carts')
            .doc(userEmail)
            .collection('Items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }
          
          var cartDocs = snapshot.data?.docs ?? [];
          double totalBill = 0;
          for (var d in cartDocs) {
            var data = d.data() as Map<String, dynamic>;
            totalBill += (data['price'] * data['qty']);
          }

          if (cartDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.brown.withOpacity(0.2)),
                  const SizedBox(height: 15),
                  Text("Your cart is empty", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown.shade400)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  // Added 25px top padding to separate first card from rounded AppBar
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    var item = cartDocs[index];
                    var data = item.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))
                        ]
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 80, width: 80,
                            decoration: BoxDecoration(
                              color: Colors.brown.shade50, 
                              borderRadius: BorderRadius.circular(15)
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15), 
                              child: displayImage(data['image'])
                            ),
                          ),
                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? "", 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                                const SizedBox(height: 4),
                                Text("${data['size'] ?? 'Small'} • ${data['sugar'] ?? 'Normal'}", 
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text("₹${data['price']}", 
                                  style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 17)),
                              ],
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => removeItem(item.id),
                                child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade300, size: 22),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  qtyButton(Icons.remove, () => updateQty(item.id, data['qty'] - 1)),
                                  const SizedBox(width: 12),
                                  Text(data['qty'].toString(), 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                                  const SizedBox(width: 12),
                                  qtyButton(Icons.add, () => updateQty(item.id, data['qty'] + 1), isAdd: true),
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

              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [
                    BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
                  ]
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Balance", 
                            style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600)),
                          Text("₹${totalBill.toStringAsFixed(0)}", 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.brown)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity, height: 60,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutPage())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown, 
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
                          ),
                          child: const Text("Checkout Now", 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.brown, 
            unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true, 
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: (value) {
              if (value == 2) return;
              if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
              if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
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
    );
  }

  Widget qtyButton(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isAdd ? Colors.brown : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.brown.shade100)
        ),
        child: Icon(icon, size: 16, color: isAdd ? Colors.white : Colors.brown),
      ),
    );
  }
}