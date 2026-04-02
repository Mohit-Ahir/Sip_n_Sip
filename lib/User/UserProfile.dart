import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Add this to pubspec.yaml
import 'dart:convert';
import 'dart:io';

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

  // FUNCTION TO PICK AND UPLOAD IMAGE
  Future<void> uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    // Compress to 300x300 to keep Firestore document size small
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 50,
    );

    if (image != null) {
      try {
        // Show loading snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Updating profile picture...")),
        );

        final bytes = await File(image.path).readAsBytes();
        String base64Image = base64Encode(bytes);

        // Update only the profileImage field in Firestore
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUserEmail)
            .update({'profileImage': base64Image});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated! ✨")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    }
  }

  // Crash-proof Image display helper
  Widget displayProfileImage(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) {
      return const Icon(Icons.person_rounded, size: 65, color: Colors.brown);
    }
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          gaplessPlayback: true,
        ),
      );
    } catch (e) {
      return const Icon(Icons.person_rounded, size: 65, color: Colors.brown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUserEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>?;
          String name = userData?['name'] ?? "User Name";
          String phone = userData?['phone'] ?? "No Phone";
          String email = userData?['email'] ?? "No Email";
          String? profileImage = userData?['profileImage'];

          return Column(
            children: [
              // HEADER SECTION
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.brown,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "My Profile",
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 25),
                          
                          // CLICKABLE AVATAR
                          GestureDetector(
                            onTap: uploadProfileImage, // Tap to change photo
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundColor: const Color(0xFFF5E6D3),
                                    child: displayProfileImage(profileImage),
                                  ),
                                ),
                                // Small Camera Icon overlay
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: Colors.brown, shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.brown)),
              const Text("Coffee Enthusiast ☕", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
              
              const SizedBox(height: 25),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  children: [
                    profileCard(Icons.person_outline_rounded, "Full Name", name),
                    profileCard(Icons.phone_android_rounded, "Phone Number", phone),
                    profileCard(Icons.email_outlined, "Email Address", email),
                    
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfile()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text("Edit Account Details", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut(); 
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()),
                            (route) => false, 
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]
        ),
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
            elevation: 0,
            onTap: (value) {
              if (value == 4) return;
              if (value == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
              if (value == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categories()));
              if (value == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Cart()));
              if (value == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Orderr()));
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

  Widget profileCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF5E6D3), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.brown, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.brown)),
            ],
          ),
        ],
      ),
    );
  }
}