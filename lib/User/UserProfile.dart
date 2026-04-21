import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sip_and_sip/screens/Login.dart';
import 'package:sip_and_sip/User/Categories.dart';
import 'package:sip_and_sip/User/Home.dart';
import 'package:sip_and_sip/User/Order.dart';
import 'package:sip_and_sip/User/cart.dart';
import 'package:sip_and_sip/User/EditProfile.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), 
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').doc(currentUserEmail).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>?;
          String name = userData?['name'] ?? "User Name";
          String phone = userData?['phone'] ?? "No Phone";
          String email = userData?['email'] ?? "No Email";
          String? profileImageUrl = userData?['profileImage'];

          return Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.vertical(bottom: Radius.circular(45))),
                  ),
                  SafeArea(
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          const Text("My Profile", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 20),
                          
                          // VIEW ONLY AVATAR
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFFF5E6D3),
                              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: profileImageUrl,
                                      imageBuilder: (context, imageProvider) => Container(
                                        decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                      ),
                                      placeholder: (context, url) => const CircularProgressIndicator(color: Colors.brown),
                                      errorWidget: (context, url, error) => const Icon(Icons.person, size: 70, color: Colors.brown),
                                    )
                                  : const Icon(Icons.person_rounded, size: 70, color: Colors.brown),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.brown)),
              const Text("Coffee Enthusiast ☕", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 25),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  children: [
                    profileInfoCard(Icons.person_outline_rounded, "Full Name", name),
                    profileInfoCard(Icons.phone_android_rounded, "Phone", phone),
                    profileInfoCard(Icons.email_outlined, "Email", email),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfile())),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text("Edit Account Details", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut(); 
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Login()), (route) => false);
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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
            currentIndex: 4,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.brown, 
            unselectedItemColor: Colors.grey.shade500,
            showUnselectedLabels: true, 
            showSelectedLabels: true,
            onTap: (value) {
              if (value == 4) return;
              if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
              if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
              if (value == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Cart()));
              if (value == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Orderr()));
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

  Widget profileInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF5E6D3), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.brown, size: 22)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.brown))]),
        ],
      ),
    );
  }
}