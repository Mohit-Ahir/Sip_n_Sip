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

  
  Color getStatusColor(String status) {
    if (status == "Delivered") return Colors.green;
    if (status == "Cancelled") return Colors.red;
    if (status == "Preparing") return Colors.blue;
    return Colors.orange; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D6C3),
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.brown,
      ),
      body: userEmail == null 
        ? const Center(child: Text("Please Login first")) 
        : StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('Orders')
                .where('customerEmail', isEqualTo: userEmail)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No orders found ☕"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var order = snapshot.data!.docs[index];
                  String status = order['status'] ?? "Processing";
                  Color sColor = getStatusColor(status);
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Order ID: #${order.id.substring(0, 5).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                           
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text(status, style: TextStyle(color: sColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(height: 25),
                        for (var item in (order['items'] as List))
                          Text("${item['name']} x${item['qty']} - ₹${item['price'] * item['qty']}"),
                        const Divider(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Paid", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("₹${order['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: (value) {
          if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
          if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
          if (value == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Cart()));
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