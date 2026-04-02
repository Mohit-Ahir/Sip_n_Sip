import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sip_and_sip/User/Categories.dart';
import 'package:sip_and_sip/User/Home.dart';
import 'package:sip_and_sip/User/UserProfile.dart';
import 'package:sip_and_sip/User/cart.dart';

class Orderr extends StatefulWidget {
  @override
  State<Orderr> createState() => _OrderrState();
}

class _OrderrState extends State<Orderr> {
  int currentIndex = 3;
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;

  // Status Color Logic
  Color getStatusColor(String status) {
    if (status == "Delivered") return Colors.green;
    if (status == "Cancelled") return Colors.redAccent;
    if (status == "Preparing") return Colors.blueAccent;
    return Colors.orange; // Processing
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
          "My Orders", 
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.2)
        ),
      ),

      body: userEmail == null 
        ? const Center(child: Text("Please Login first")) 
        : StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('Orders')
                .where('customerEmail', isEqualTo: userEmail)
                // .orderBy('orderDate', descending: true) // Add this back if you create the index in Firebase!
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.brown));
              }

              // PREMIUM EMPTY STATE
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 80, color: Colors.brown.shade300),
                      const SizedBox(height: 15),
                      Text("No orders yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                      const SizedBox(height: 10),
                      Text("When you place an order,\nit will appear here.", textAlign: TextAlign.center, style: TextStyle(color: Colors.brown.shade400)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var order = snapshot.data!.docs[index];
                  String status = order['status'] ?? "Processing";
                  Color sColor = getStatusColor(status);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER: ORDER ID & STATUS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt, color: Colors.brown, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Order #${order.id.substring(0, 5).toUpperCase()}", 
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.brown)
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text(status, style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Divider(color: Colors.grey.shade200, thickness: 1.5),
                        ),
                        
                        // ORDER ITEMS LIST
                        for (var item in (order['items'] as List))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${item['name']}  x${item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 3),
                                      // SHOW CUSTOMIZATION IF AVAILABLE
                                      if (item['size'] != null && item['sugar'] != null)
                                        Text("${item['size']} • ${item['sugar']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Text("₹${item['price'] * item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 15)),
                              ],
                            ),
                          ),
                        
                        Divider(color: Colors.grey.shade200, thickness: 1.5),
                        const SizedBox(height: 10),

                        // TOTAL ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Paid", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                            Text("₹${order['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.brown, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

      // ROUNDED FLOATING-STYLE BOTTOM NAV
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
              if (value == 3) return; // Already on Orders
              if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
              if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
              if (value == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Cart()));
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