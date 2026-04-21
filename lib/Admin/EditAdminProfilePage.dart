import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';

class EditAdminProfilePage extends StatefulWidget {
  const EditAdminProfilePage({super.key});

  @override
  State<EditAdminProfilePage> createState() => _EditAdminProfilePageState();
}

class _EditAdminProfilePageState extends State<EditAdminProfilePage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // PASTE YOUR IMGBB KEY HERE
  final String imgBBKey = "95170aa0021e9a2be058c52de30c72ea"; 
  bool isUploading = false;
  bool loading = false;
  String? profileImageUrl;

  User? admin = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  void fetchAdminData() async {
    if (admin != null) {
      DocumentSnapshot adminData = await FirebaseFirestore.instance.collection('Users').doc(admin!.email).get();
      if (adminData.exists) {
        setState(() {
          nameController.text = adminData['name'] ?? "";
          phoneController.text = adminData['phone'] ?? "";
          profileImageUrl = adminData['profileImage'];
        });
      }
    }
  }

  // IMAGE UPLOAD & ADJUST LOGIC
  Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Adjust Admin Photo', toolbarColor: Colors.brown, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
        ],
      );

      if (croppedFile != null) {
        setState(() => isUploading = true);
        try {
          var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgBBKey'));
          request.files.add(await http.MultipartFile.fromPath('image', croppedFile.path));
          var response = await request.send();
          var responseData = await response.stream.bytesToString();
          var jsonResponse = json.decode(responseData);

          if (response.statusCode == 200) {
            String newUrl = jsonResponse['data']['url'];
            await FirebaseFirestore.instance.collection('Users').doc(admin!.email).update({'profileImage': newUrl});
            setState(() => profileImageUrl = newUrl);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin photo updated! ✨")));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        } finally {
          setState(() => isUploading = false);
        }
      }
    }
  }

  void updateAdminProfile() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
    setState(() => loading = true);
    try {
      await FirebaseFirestore.instance.collection('Users').doc(admin!.email).update({'name': nameController.text.trim(), 'phone': phoneController.text.trim()});
      if (passwordController.text.isNotEmpty) {
        if (passwordController.text == confirmPasswordController.text) {
          await admin!.updatePassword(passwordController.text);
          await FirebaseFirestore.instance.collection('Users').doc(admin!.email).update({'password': passwordController.text});
        }
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(height: 220, width: double.infinity, decoration: const BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.vertical(bottom: Radius.circular(45)))),
                SafeArea(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Row(children: [IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)), const Expanded(child: Text("Edit Admin Profile", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))]),
                        const SizedBox(height: 20),
                        
                        // CLICKABLE AVATAR FOR CHANGE
                        GestureDetector(
                          onTap: isUploading ? null : pickAndUploadImage,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: const Color(0xFFF5E6D3),
                                  child: isUploading 
                                      ? const CircularProgressIndicator(color: Colors.brown)
                                      : profileImageUrl != null 
                                          ? CachedNetworkImage(
                                              imageUrl: profileImageUrl!,
                                              imageBuilder: (c, i) => Container(decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: i, fit: BoxFit.cover))),
                                              errorWidget: (c, u, e) => const Icon(Icons.person, size: 65, color: Colors.brown),
                                            )
                                          : const Icon(Icons.admin_panel_settings_rounded, size: 65, color: Colors.brown),
                                ),
                              ),
                              Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.brown, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  buildInputField(Icons.person_outline_rounded, "Admin Full Name", nameController),
                  buildInputField(Icons.phone_android_rounded, "Admin Phone", phoneController),
                  buildPasswordField("System Password", passwordController),
                  buildPasswordField("Confirm Password", confirmPasswordController),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: loading ? null : updateAdminProfile, style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Update System Profile", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputField(IconData icon, String label, TextEditingController controller) {
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]), child: TextField(controller: controller, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold), decoration: InputDecoration(icon: Icon(icon, color: Colors.brown), labelText: label, labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13), border: InputBorder.none)));
  }

  Widget buildPasswordField(String label, TextEditingController controller) {
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]), child: TextField(controller: controller, obscureText: true, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold), decoration: InputDecoration(icon: const Icon(Icons.lock_outline_rounded, color: Colors.brown), labelText: label, labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13), border: InputBorder.none)));
  }
}