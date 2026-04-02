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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D6C3),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text("My Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var cartDocs = snapshot.data!.docs;
          double totalBill = 0;
          for (var d in cartDocs) { totalBill += d['price'] * d['qty']; }

          if (cartDocs.isEmpty) {
            return const Center(child: Text("Your cart is empty ☕", style: TextStyle(fontSize: 18)));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    var item = cartDocs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            height: 60, width: 60,
                            decoration: BoxDecoration(color: Colors.brown.shade100, borderRadius: BorderRadius.circular(12)),
                            child: item['image'] != "" 
                              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(item['image']), fit: BoxFit.cover))
                              : const Icon(Icons.local_cafe, color: Colors.brown),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text("₹${item['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(onPressed: () => updateQty(item.id, item['qty'] - 1), icon: const Icon(Icons.remove_circle_outline)),
                              Text(item['qty'].toString(), style: const TextStyle(fontSize: 16)),
                              IconButton(onPressed: () => updateQty(item.id, item['qty'] + 1), icon: const Icon(Icons.add_circle_outline)),
                            ],
                          ),
                          IconButton(onPressed: () => removeItem(item.id), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("₹$totalBill", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutPage())),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("Checkout", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: (value) {
          if (value == 2) return;
          if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Home()));
          if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
          if (value == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Orderr()));
          if (value == 4) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserProfile()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}