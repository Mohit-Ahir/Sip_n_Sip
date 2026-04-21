import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final List<String> categoryList = [
    "Hot Coffee",
    "Cold Coffee",
    "Flavoured",
    "Special",
  ];

  // 1. FAST IMAGE DISPLAY (Hybrid Logic: Handles ImgBB URLs & old Base64)
  Widget displayImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(Icons.local_cafe, size: 45, color: Colors.brown);
    }
    try {
      if (imagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.brown.shade50,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.brown,
              ),
            ),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
        return Image.memory(
          base64Decode(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          gaplessPlayback: true,
        );
      }
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),

       appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: const Text(
          "Our Menu", 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 22, 
            letterSpacing: 1.2
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search for your favorite coffee...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.brown),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = "");
                          },
                        )
                      : null,
                ),
              ),
            ),

            // DYNAMIC CATEGORY LOOP
            for (var category in categoryList)
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Products')
                    .where('category', isEqualTo: category)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  var filteredDocs = snapshot.data!.docs.where((doc) {
                    String productName =
                        (doc.data() as Map<String, dynamic>)['name']
                            .toString()
                            .toLowerCase();
                    return productName.contains(searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIXED PADDING ERROR HERE:
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          left: 5,
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade900,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDocs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.75,
                            ),
                        itemBuilder: (context, index) {
                          var doc = filteredDocs[index];
                          var productData = doc.data() as Map<String, dynamic>;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsPage(
                                    productData: productData,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.brown.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.brown.shade50,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(22),
                                            ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(22),
                                            ),
                                        child: displayImage(
                                          productData['image'],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productData['name'] ?? "",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.brown,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "₹${productData['price']}",
                                              style: const TextStyle(
                                                color: Colors.brown,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.brown,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                    ],
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
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
            elevation: 0,
            onTap: (value) {
              if (value == 1) return;
              if (value == 0)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Home()),
                );
              if (value == 2)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Cart()),
                );
              if (value == 3)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => Orderr()),
                );
              if (value == 4)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfile()),
                );
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded),
                label: "Menu",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded),
                label: "Cart",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: "Orders",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
