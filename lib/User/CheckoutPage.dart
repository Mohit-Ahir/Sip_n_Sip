import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String userEmail = FirebaseAuth.instance.currentUser!.email!;
  double deliveryFee = 30;

  void placeOrder(List<DocumentSnapshot> cartItems, double total) async {
    try {
      showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));

      // 1. Create the Order in Firestore
      await FirebaseFirestore.instance.collection('Orders').add({
        'customerEmail': userEmail,
        'items': cartItems.map((doc) => {
          'name': doc['name'],
          'price': doc['price'],
          'qty': doc['qty'],
        }).toList(),
        'totalAmount': total + deliveryFee,
        'status': 'Processing',
        'orderDate': FieldValue.serverTimestamp(),
        'address': 'Ahmedabad, Gujarat', // Static for now
      });

      // 2. Clear the User's Cart
      var cartItemsRef = FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items');
      var snapshots = await cartItemsRef.get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }

      Navigator.pop(context); // Close loading
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Order Placed ☕"),
          content: const Text("Your coffee will arrive soon!"),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Go back to Home
            }, child: const Text("OK"))
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text("Checkout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var items = snapshot.data!.docs;
          double subtotal = 0;
          for (var d in items) { subtotal += d['price'] * d['qty']; }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Delivery Address
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [Icon(Icons.location_on, color: Colors.brown), SizedBox(width: 10), Text("Ahmedabad, Gujarat\nNear Coffee Street")]),
              ),
              const SizedBox(height: 20),
              const Text("Your Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Order Items
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${item["name"]} x${item["qty"]}"),
                          Text("₹${item["price"] * item["qty"]}", style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Payment Method
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [Icon(Icons.money, color: Colors.green), SizedBox(width: 12), Text("Cash on Delivery", style: TextStyle(fontWeight: FontWeight.bold)), Spacer(), Icon(Icons.check_circle, color: Colors.green)]),
              ),
              const SizedBox(height: 20),
              // Bill Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subtotal"), Text("₹$subtotal")]),
                    const SizedBox(height: 8),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Delivery Fee"), Text("₹30")]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)), Text("₹${subtotal + deliveryFee}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown))]),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => placeOrder(items, subtotal),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, minimumSize: const Size(double.infinity, 50)),
                child: Text("Place Order • ₹${subtotal + deliveryFee}", style: const TextStyle(color: Colors.white)),
              )
            ],
          );
        },
      ),
    );
  }
}