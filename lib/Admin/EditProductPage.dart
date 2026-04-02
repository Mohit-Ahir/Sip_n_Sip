import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _selectedCategory;
  bool _isPopular = false;
  String base64Image = "";

  final List<String> categories = ["Hot Coffee", "Cold Coffee", "Flavoured", "Special"];

  @override
  void initState() {
    super.initState();
   
    _nameController = TextEditingController(text: widget.currentData['name']);
    _priceController = TextEditingController(text: widget.currentData['price'].toString());
    _selectedCategory = widget.currentData['category'];
    _isPopular = widget.currentData['isPopular'] ?? false;
    base64Image = widget.currentData['image'] ?? "";
  }

 
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 400, maxHeight: 400, imageQuality: 50
    );
    
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> updateProduct() async {
    if (_selectedCategory == null || _nameController.text.isEmpty || _priceController.text.isEmpty || base64Image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.brown)));

      await FirebaseFirestore.instance.collection('Products').doc(widget.docId).update({
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'image': base64Image,
        'isPopular': _isPopular,
      });

      Navigator.pop(context); 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Updated Successfully")));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D6C3),
      appBar: AppBar(
        title: const Text("Edit Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7B5E57),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
           
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF7B5E57)),
                ),
                child: base64Image.isEmpty 
                  ? const Icon(Icons.add_photo_alternate, size: 45, color: Color(0xFF7B5E57))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(base64Decode(base64Image), fit: BoxFit.cover),
                    ),
              ),
            ),
            const SizedBox(height: 20),
           
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: const Color(0xFFECECEC), borderRadius: BorderRadius.circular(15)),
              child: DropdownButton<String>(
                value: _selectedCategory,
                hint: const Text("Select Category"),
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              ),
            ),
            const SizedBox(height: 15),
           
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: "Product Name", prefixIcon: Icon(Icons.coffee))),
            const SizedBox(height: 15),
           
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Price", prefixIcon: Icon(Icons.currency_rupee))),
            const SizedBox(height: 15),
          
            SwitchListTile(
              title: const Text("Show in Popular Coffee"),
              value: _isPopular,
              activeColor: const Color(0xFF7B5E57),
              onChanged: (val) => setState(() => _isPopular = val),
            ),
            const SizedBox(height: 30),
           
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: updateProduct,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B5E57), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text("Update Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}