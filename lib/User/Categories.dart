import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:sip_and_sip/User/Home.dart';
import 'package:sip_and_sip/User/UserProfile.dart';
import 'package:sip_and_sip/User/cart.dart';
import 'package:sip_and_sip/User/Order.dart';

class Categories extends StatefulWidget {
  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  int currentIndex = 1;
  String searchQuery = "";
  final List<String> categoryList = ["Hot Coffee", "Cold Coffee", "Flavoured", "Special"];

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
      backgroundColor: const Color(0xFFE6D6C3),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text("Coffee Categories", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                decoration: const InputDecoration(hintText: "Search coffee..", border: InputBorder.none, icon: Icon(Icons.search)),
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              ),
            ),
            
            for (var category in categoryList)
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('Products').where('category', isEqualTo: category).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

                  var filteredDocs = snapshot.data!.docs.where((d) => d['name'].toString().toLowerCase().contains(searchQuery)).toList();
                  if (filteredDocs.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(category, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDocs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          var product = filteredDocs[index];
                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Container(
                                  height: 55, width: 55,
                                  decoration: BoxDecoration(color: Colors.brown.shade100, borderRadius: BorderRadius.circular(12)),
                                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(product['image']), fit: BoxFit.cover)),
                                ),
                                const SizedBox(height: 10),
                                Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 5),
                                Text("₹ ${product['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                SizedBox(width: double.infinity, height: 34,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      addToCart(product['name'], product['price'], product['image']);
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                                    child: const Text("Add", style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: (value) {
          if (value == 1) return;
          if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Home()));
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