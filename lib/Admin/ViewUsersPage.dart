import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sip_and_sip/Admin/AdminDashboardPage.dart';
import 'package:sip_and_sip/Admin/ManageProductsPage.dart';
import 'package:sip_and_sip/Admin/ManageOrdersPage.dart';
import 'package:sip_and_sip/Admin/AdminProfilePage.dart';

class ViewUsersPage extends StatefulWidget {
  const ViewUsersPage({super.key});
  @override
  State<ViewUsersPage> createState() => _ViewUsersPageState();
}

class _ViewUsersPageState extends State<ViewUsersPage> {
  // SEARCH CONTROLS
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // 1. DYNAMIC PROFILE IMAGE LOGIC
  Widget displayUserPhoto(String? url, String name) {
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.brown.shade100,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "?", 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 20)
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2, color: Colors.brown),
      errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey),
    );
  }

  // 2. DELETE CONFIRMATION
  void confirmDelete(String email, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Remove User?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete the account for $name? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('Users').doc(email).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User account removed")));
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), // Premium Cream

      // 3. UPDATED APP BAR (MATCHING PREMIUM DESIGN)
      appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: const Text(
          "Customer Directory", 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 22, 
            letterSpacing: 1.2
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 25),

          // 4. MODERN SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search name or email...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search_rounded, color: Colors.brown),
                  suffixIcon: searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() { searchQuery = ""; });
                        },
                      ) 
                    : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // 5. DYNAMIC CUSTOMER LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Users').where('role', isEqualTo: 'user').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.brown));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No customers yet.", style: TextStyle(color: Colors.grey)));

                // Filter logic for search
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  String name = (doc['name'] ?? "").toString().toLowerCase();
                  String email = (doc['email'] ?? "").toString().toLowerCase();
                  return name.contains(searchQuery) || email.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No matching users found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var user = filteredDocs[index];
                    var data = user.data() as Map<String, dynamic>;
                    String name = data['name'] ?? "No Name";
                    String photo = data['profileImage'] ?? "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        children: [
                          // USER PHOTO
                          SizedBox(width: 60, height: 60, child: displayUserPhoto(photo, name)),
                          const SizedBox(width: 15),
                          
                          // USER INFO
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.brown)),
                              const SizedBox(height: 2),
                              Text(data['email'] ?? "", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              Text(data['phone'] ?? "", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                          
                          // POPUP MENU
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            onSelected: (val) => confirmDelete(user.id, name),
                            itemBuilder: (c) => [
                              const PopupMenuItem(
                                value: "del", 
                                child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 10), Text("Remove User")])
                              )
                            ],
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

      // ROUNDED PREMIUM BOTTOM NAV
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
          child: BottomNavigationBar(
            currentIndex: 3, 
            type: BottomNavigationBarType.fixed, 
            backgroundColor: Colors.white, 
            selectedItemColor: Colors.brown, 
            unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true, 
            selectedFontSize: 12, 
            unselectedFontSize: 11, 
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: (index) {
              if (index == 3) return;
              if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
              if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageProductsPage()));
              if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageOrdersPage()));
              if (index == 4) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProfilePage()));
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