import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:sip_and_sip/Admin/AddProductPage.dart';
import 'package:sip_and_sip/Admin/EditProductPage.dart';
import 'package:sip_and_sip/Admin/AdminDashboardPage.dart';
import 'package:sip_and_sip/Admin/ManageOrdersPage.dart';
import 'package:sip_and_sip/Admin/ViewUsersPage.dart';
import 'package:sip_and_sip/Admin/AdminProfilePage.dart';

class AllProductsPage extends StatefulWidget {
  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {

  // 1. HYBRID IMAGE DISPLAY
  Widget displayImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(color: Colors.brown.shade50, child: const Icon(Icons.coffee, color: Colors.brown));
    }
    try {
      if (imagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
        return Image.memory(base64Decode(imagePath), fit: BoxFit.cover, gaplessPlayback: true);
      }
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.grey);
    }
  }

  // 2. DELETE CONFIRMATION DIALOG
  void confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Product?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove '$name' permanently?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('Products').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name removed")));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), // Premium Cream
      
      // MODERN TRANSPARENT APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          "All Products", 
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.2)
        ),
      ),

      body: Column(
        children: [
          // 3. CURVED HEADER ACCENT
          Container(
            height: 20,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
          ),

          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('Products').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.brown));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No products found in database."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var product = snapshot.data!.docs[index];
                    var data = product.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))]
                      ),
                      child: Row(
                        children: [
                          // PRODUCT THUMBNAIL
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(18)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: displayImage(data['image'] ?? ""),
                            ),
                          ),
                          const SizedBox(width: 15),
                          
                          // INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.brown)),
                                const SizedBox(height: 4),
                                Text("₹${data['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 16)),
                              ],
                            ),
                          ),
                          
                          // ACTION BUTTONS
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.orangeAccent, size: 28),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (c) => EditProductPage(docId: product.id, currentData: data)));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                            onPressed: () => confirmDelete(product.id, data['name'] ?? ""),
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

      // 4. FLOATING ACTION BUTTON (Add Product)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductPage()));
        },
      ),

      // 5. ROUNDED PREMIUM BOTTOM NAV
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
          child: BottomNavigationBar(
            currentIndex: 1, // Products Tab
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.brown, 
            unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
            onTap: (index) {
              if (index == 1) return;
              switch (index) {
                case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage())); break;
                case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageOrdersPage())); break;
                case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ViewUsersPage())); break;
                case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProfilePage())); break;
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dash"),
              BottomNavigationBarItem(icon: Icon(Icons.coffee_rounded), label: "Products"),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: "Orders"),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Users"),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}