import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';

class EditProductPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const EditProductPage({super.key, required this.docId, required this.currentData});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController; // NEW: Quantity Controller
  
  final String imgBBKey = "YOUR_IMGBB_KEY_HERE"; 
  String? _selectedCategory;
  bool _isPopular = false;
  String? currentImageUrl;
  bool isUploading = false;
  bool isSaving = false;

  final List<String> categories = ["Hot Coffee", "Cold Coffee", "Flavoured", "Special"];

  @override
  void initState() {
    super.initState();
    // Pre-filling the controllers with existing data from Firebase
    _nameController = TextEditingController(text: widget.currentData['name']);
    _priceController = TextEditingController(text: widget.currentData['price'].toString());
    _quantityController = TextEditingController(text: (widget.currentData['quantity'] ?? 0).toString()); // LOAD QUANTITY
    _selectedCategory = widget.currentData['category'];
    _isPopular = widget.currentData['isPopular'] ?? false;
    currentImageUrl = widget.currentData['image'] ?? "";
  }

  Widget displayProductImage() {
    if (currentImageUrl == null || currentImageUrl!.isEmpty) {
      return const Icon(Icons.coffee_rounded, size: 50, color: Colors.brown);
    }
    if (currentImageUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: currentImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      );
    } else {
      return Image.memory(base64Decode(currentImageUrl!), fit: BoxFit.cover);
    }
  }

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
          currentImageUrl = jsonResponse['data']['url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New image uploaded!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> updateProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('Products').doc(widget.docId).update({
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()), // UPDATING QUANTITY
        'category': _selectedCategory,
        'image': currentImageUrl, 
        'isPopular': _isPopular,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Updated Successfully!")));
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
                        const Expanded(child: Text("Edit Product", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
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
                        : ClipRRect(borderRadius: BorderRadius.circular(25), child: displayProductImage()),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text("Tap image to change", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 25),

                  buildContainerWrapper(
                    child: DropdownButton<String>(
                      value: _selectedCategory, isExpanded: true, underline: const SizedBox(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)))).toList(),
                    ),
                  ),

                  const SizedBox(height: 15),
                  buildInputField(Icons.coffee_rounded, "Product Name", _nameController),
                  const SizedBox(height: 15),
                  buildInputField(Icons.currency_rupee_rounded, "Price", _priceController, isNumber: true),
                  const SizedBox(height: 15),
                  
                  // NEW: STOCK QUANTITY INPUT
                  buildInputField(Icons.inventory_2_rounded, "Stock Quantity", _quantityController, isNumber: true),

                  const SizedBox(height: 15),

                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.04), blurRadius: 10)]),
                    child: SwitchListTile(
                      activeColor: Colors.brown,
                      title: const Text("Show in Popular List", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 14)),
                      value: _isPopular,
                      onChanged: (val) => setState(() => _isPopular = val),
                    ),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : updateProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Update Product Details", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
