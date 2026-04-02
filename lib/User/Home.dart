import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // For Base64 images
import 'package:sip_and_sip/User/Categories.dart';
import 'package:sip_and_sip/User/Order.dart';
import 'package:sip_and_sip/User/UserProfile.dart';
import 'package:sip_and_sip/User/cart.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;

  // ADD TO CART LOGIC
  void addToCart(String name, int price, String image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userEmail = user.email!;
    var cartRef = FirebaseFirestore.instance
        .collection('Carts')
        .doc(userEmail)
        .collection('Items');

    var doc = await cartRef.doc(name).get();

    if (doc.exists) {
      cartRef.doc(name).update({'qty': doc['qty'] + 1});
    } else {
      cartRef.doc(name).set({
        'name': name,
        'price': price,
        'image': image,
        'qty': 1,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$name added to cart")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        centerTitle: true,
        title: const Text("Sip & Sip ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Good Morning ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("Fresh coffee at your door", style: TextStyle(color: Colors.brown.shade700)),
              const SizedBox(height: 25),
              const Text("Popular Coffee", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('Products').where('isPopular', isEqualTo: true).snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.brown));
                    if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No popular items yet"));

                    return GridView.builder(
                      itemCount: snapshot.data!.docs.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.70,
                      ),
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade100,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.memory(base64Decode(doc['image']), fit: BoxFit.cover),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Text(doc['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text("₹${doc['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 34,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          addToCart(doc['name'], doc['price'], doc['image']);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                                        child: const Text("Add", style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: (value) {
          if (value == 0) return;
          if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
          if (value == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Cart()));
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