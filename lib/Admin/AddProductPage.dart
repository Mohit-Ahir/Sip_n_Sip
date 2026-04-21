import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(); 

  final String imgBBKey = "95170aa0021e9a2be058c52de30c72ea"; 
  String? _selectedCategory;
  bool _isPopular = false;
  String? uploadedImageUrl;
  bool isUploading = false;
  bool isSaving = false;

  final List<String> categories = ["Hot Coffee", "Cold Coffee", "Flavoured", "Special"];

  Future<void> pickAndAdjustImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Product Photo',
            toolbarColor: Colors.brown,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
        ],
      );

      if (croppedFile != null) {
        uploadToImgBB(File(croppedFile.path));
      }
    }
  }

  Future<void> uploadToImgBB(File imageFile) async {
    setState(() => isUploading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgBBKey'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          uploadedImageUrl = jsonResponse['data']['url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image ready! ✨")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> saveProduct() async {
    // UPDATED VALIDATION: Added check for quantity
    if (_selectedCategory == null || _nameController.text.isEmpty || 
        _priceController.text.isEmpty || _quantityController.text.isEmpty || uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields & upload image")));
      return;
    }

    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('Products').add({
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()), // SAVING QUANTITY
        'category': _selectedCategory,
        'image': uploadedImageUrl,
        'isPopular': _isPopular,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Added Successfully!")));
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 180, width: double.infinity,
                decoration: const BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.vertical(bottom: Radius.circular(45))),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
                        const Expanded(child: Text("Add New Product", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  GestureDetector(
                    onTap: isUploading ? null : pickAndAdjustImage,
                    child: Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
                        border: Border.all(color: Colors.brown.withOpacity(0.1))
                      ),
                      child: isUploading 
                        ? const Center(child: CircularProgressIndicator(color: Colors.brown))
                        : uploadedImageUrl != null 
                          ? ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.network(uploadedImageUrl!, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.brown.shade200),
                                const SizedBox(height: 10),
                                const Text("Tap to Pick & Adjust Image", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  buildContainerWrapper(
                    child: DropdownButton<String>(
                      value: _selectedCategory, isExpanded: true, underline: const SizedBox(),
                      hint: const Text("Select Category", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)))).toList(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  buildInputField(Icons.coffee_rounded, "Product Name", _nameController),

                  const SizedBox(height: 15),

                  buildInputField(Icons.currency_rupee_rounded, "Price", _priceController, isNumber: true),

                  const SizedBox(height: 15),

                  // NEW: QUANTITY INPUT FIELD
                  buildInputField(Icons.inventory_2_rounded, "Stock Quantity", _quantityController, isNumber: true),

                  const SizedBox(height: 15),

                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.04), blurRadius: 10)]),
                    child: SwitchListTile(
                      activeColor: Colors.brown,
                      title: const Text("Display in Popular List", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 14)),
                      value: _isPopular,
                      onChanged: (val) => setState(() => _isPopular = val),
                    ),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Publish Product", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContainerWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: child,
    );
  }

  Widget buildInputField(IconData icon, String label, TextEditingController controller, {bool isNumber = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.brown),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }
}