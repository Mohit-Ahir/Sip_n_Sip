import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sip_and_sip/User/AddressPicker.dart'; 

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final String userEmail = FirebaseAuth.instance.currentUser!.email!;
  final double deliveryFee = 30.0;

  // CONTROLLERS FOR DATA
  final TextEditingController _addressController = TextEditingController();
  double pickedLat = 0.0;
  double pickedLng = 0.0;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // LOGIC: Save order to Firestore
  void placeOrder(List<DocumentSnapshot> cartItems, double total) async {
    String finalAddress = _addressController.text.trim();

    if (finalAddress.isEmpty || finalAddress == "Select your delivery address") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a delivery address")),
      );
      return;
    }

    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.brown)));

      await FirebaseFirestore.instance.collection('Orders').add({
        'customerEmail': userEmail,
        'items': cartItems.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['name'],
            'price': data['price'],
            'qty': data['qty'],
            'size': data['size'] ?? "Small",
            'sugar': data['sugar'] ?? "Normal",
          };
        }).toList(),
        'totalAmount': total + deliveryFee,
        'status': 'Processing',
        'orderDate': FieldValue.serverTimestamp(),
        'address_text': finalAddress,
        'latitude': pickedLat,
        'longitude': pickedLng,
      });

      // Clear the Cart after order
      var cartItemsRef = FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items');
      var snapshots = await cartItemsRef.get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }

      Navigator.pop(context); // Close loading
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Text("Order Placed Successfully! ☕", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            Center(
              child: TextButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); }, 
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 18))
              ),
            )
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), // Premium background

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.brown),
        title: const Text("Checkout", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24)),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.brown));
          
          var items = snapshot.data!.docs;
          double subtotal = 0;
          for (var d in items) { 
            var data = d.data() as Map<String, dynamic>;
            subtotal += (data['price'] * data['qty']); 
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // 1. ADDRESS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.brown)),
                  TextButton.icon(
                    onPressed: () async {
                      final dynamic result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const AddressPicker()));
                      if (result != null && result is Map) {
                        setState(() {
                          _addressController.text = result['address'];
                          pickedLat = result['lat'];
                          pickedLng = result['lng'];
                        });
                      }
                    },
                    icon: const Icon(Icons.map_rounded, color: Colors.brown, size: 20),
                    label: const Text("Use Map", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: TextField(
                  controller: _addressController,
                  maxLines: null, // Allows text to grow downwards
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Click 'Use Map' or type your house number & street...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 0), // Adjust to align with text
                      child: Icon(Icons.location_on_rounded, color: Colors.brown),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 2. ORDER SUMMARY
              const Text("Your Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.brown)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10)]
                ),
                child: Column(
                  children: items.map((doc) {
                    var item = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${item["name"]} x${item["qty"]}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text("${item['size']} • ${item['sugar']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text("₹${item["price"] * item["qty"]}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.brown, fontSize: 15)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 30),

              // 3. BILL DETAILS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10)]
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        Text("₹$subtotal", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Delivery Fee", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        Text("₹$deliveryFee", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider(thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.brown)),
                        Text("₹${subtotal + deliveryFee}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.brown)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),

      // CONFIRM BUTTON PANEL
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').get().then((snap) {
                double total = 0;
                for (var d in snap.docs) { 
                   var data = d.data() as Map<String, dynamic>;
                   total += (data['price'] * data['qty']); 
                }
                placeOrder(snap.docs, total);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown, 
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            child: const Text("Confirm Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}