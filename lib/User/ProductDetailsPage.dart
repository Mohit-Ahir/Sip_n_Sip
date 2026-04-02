import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailsPage({super.key, required this.productData});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String selectedSize = 'Small';
  String selectedSugar = 'Normal Sugar';
  late int basePrice;
  late int finalPrice; // This is the dynamic price we will show everywhere

  @override
  void initState() {
    super.initState();
    basePrice = widget.productData['price'] ?? 0;
    finalPrice = basePrice; 
  }

  Widget displayImage(String base64Str) {
    try {
      if (base64Str.isEmpty) return Icon(Icons.local_cafe, size: 80, color: Colors.brown.shade300);
      return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: double.infinity, height: double.infinity, gaplessPlayback: true);
    } catch (e) {
      return Icon(Icons.local_cafe, size: 80, color: Colors.brown.shade300);
    }
  }

  void addToCart() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userEmail = user.email!;
    var cartRef = FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items');
    String cartItemId = "${widget.productData['name']}_${selectedSize}_$selectedSugar".replaceAll(" ", "");

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.brown)));

    try {
      var doc = await cartRef.doc(cartItemId).get();
      if (doc.exists) {
        await cartRef.doc(cartItemId).update({'qty': doc['qty'] + 1});
      } else {
        await cartRef.doc(cartItemId).set({
          'name': widget.productData['name'],
          'price': finalPrice,
          'image': widget.productData['image'] ?? "",
          'size': selectedSize,
          'sugar': selectedSugar,
          'qty': 1,
        });
      }
      Navigator.pop(context); 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$selectedSize ${widget.productData['name']} added to cart ☕")));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void updatePrice(String size) {
    setState(() {
      selectedSize = size;
      // Logical price calculation
      if (size == 'Small') finalPrice = basePrice;
      if (size == 'Medium') finalPrice = basePrice + 30;
      if (size == 'Large') finalPrice = basePrice + 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.brown),
        title: const Text("Customize", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.2)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // Product Image
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: displayImage(widget.productData['image'] ?? ""),
                  ),
                ),
                const SizedBox(height: 30),

                // Name and REFLACTED PRICE (Updated logic here)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.productData['name'] ?? "Unknown",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.brown.shade900, height: 1.2),
                      ),
                    ),
                    // This Price now reflects the size selection instantly
                    Text(
                      "₹$finalPrice", 
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.brown),
                    ),
                  ],
                ),
                const SizedBox(height: 35),

                // Size Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Select Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown.shade800)),
                    Text("Required", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: ['Small', 'Medium', 'Large'].map((size) {
                    bool isSelected = selectedSize == size;
                    return ChoiceChip(
                      label: Text(size),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.brown.shade700, fontWeight: FontWeight.bold, fontSize: 15),
                      selected: isSelected,
                      selectedColor: Colors.brown,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.brown : Colors.transparent)),
                      elevation: isSelected ? 3 : 0,
                      onSelected: (val) => updatePrice(size),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 35),

                // Sugar Selection
                const Text("Sugar Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: ['No Sugar', 'Normal Sugar', 'Extra Sugar'].map((sugar) {
                    bool isSelected = selectedSugar == sugar;
                    return ChoiceChip(
                      label: Text(sugar),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.brown.shade700, fontWeight: FontWeight.bold, fontSize: 15),
                      selected: isSelected,
                      selectedColor: Colors.brown,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.brown : Colors.transparent)),
                      elevation: isSelected ? 3 : 0,
                      onSelected: (val) => setState(() => selectedSugar = sugar),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Add To Cart Panel
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Price", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("₹$finalPrice", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24)),
                  ],
                ),
                SizedBox(
                  height: 55, width: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: addToCart,
                    child: const Text("Add to Cart", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}