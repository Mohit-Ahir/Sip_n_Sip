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

class ManageProductsPage extends StatefulWidget {
  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  
  // 1. HYBRID IMAGE ENGINE
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

  // 2. DELETE CONFIRMATION
  void confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Remove Coffee?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '$name' from the menu?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('Products').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name deleted")));
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
      backgroundColor: const Color(0xFFF5E6D3), 

      // 3. UPDATED APP BAR (EXACT MATCH TO VIEWUSERSPAGE)
      appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 0, // Set to 0 for the flat premium look
        toolbarHeight: 80,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: const Text(
          "Inventory Management", 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 22, // Matched to 22
            letterSpacing: 1.2 // Matched to 1.2
          ),
        ),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.brown));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No products found in database."));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 100), 
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var product = snapshot.data!.docs[index];
              var productData = product.data() as Map<String, dynamic>;
              
              int stock = productData['quantity'] ?? 0;
              bool lowStock = stock <= 5; 

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))]
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(18)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: displayImage(productData['image'] ?? ""),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productData['name'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.brown)),
                          const SizedBox(height: 4),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: lowStock ? Colors.red.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Stock: $stock", 
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.bold, 
                                color: lowStock ? Colors.red : Colors.grey.shade600
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          Text("₹${productData['price']}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.orangeAccent, size: 28),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (c) => EditProductPage(docId: product.id, currentData: productData)));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                          onPressed: () => confirmDelete(product.id, productData['name'] ?? ""),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("New Coffee", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage())),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
          child: BottomNavigationBar(
            currentIndex: 1, type: BottomNavigationBarType.fixed, backgroundColor: Colors.white, selectedItemColor: Colors.brown, unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true, selectedFontSize: 12, unselectedFontSize: 11, selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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