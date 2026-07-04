import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sip_and_sip/User/AddressPicker.dart'; 
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final String userEmail = FirebaseAuth.instance.currentUser!.email!;
  final double deliveryFee = 30.0;
  final TextEditingController _addressController = TextEditingController();
  double pickedLat = 0.0;
  double pickedLng = 0.0;

  late Razorpay _razorpay;
  String selectedPaymentMethod = "COD"; 

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    
    // ATTACHING LISTENERS
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _razorpay.clear(); 
    super.dispose();
  }

  // --- RAZORPAY HANDLERS WITH DEBUG PRINTS ---
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("PAYMENT SUCCESS: ${response.paymentId}"); // CHECK THIS IN CONSOLE
    
    // Place order after successful payment
    FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').get().then((snap) {
      double total = 0;
      for (var d in snap.docs) { 
        var data = d.data() as Map<String, dynamic>;
        total += (data['price'] * data['qty']); 
      }
      placeOrder(snap.docs, total, paymentId: response.paymentId);
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("PAYMENT ERROR: ${response.code} - ${response.message}"); // CHECK THIS IN CONSOLE
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("WALLET SELECTED: ${response.walletName}");
  }

  void openRazorpay(double amount) {
    var options = {
      'key': 'YOUR_RAZORPAY_KEY_HER', // MAKE SURE THIS IS YOUR TEST KEY
      'amount': (amount + deliveryFee) * 100, // convert to paise
      'name': 'Sip & Sip Coffee',
      'description': 'Payment for Order',
      'prefill': {'contact': '9876543210', 'email': userEmail},
      'timeout': 300, // 5 minutes
    };

    try {
      print("Opening Razorpay...");
      _razorpay.open(options);
    } catch (e) {
      print("RAZORPAY OPEN ERROR: $e");
    }
  }

  // --- ORDER LOGIC ---
  void placeOrder(List<DocumentSnapshot> cartItems, double total, {String? paymentId}) async {
    String finalAddress = _addressController.text.trim();
    if (finalAddress.isEmpty || finalAddress == "Select your delivery address") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide an address")));
      return;
    }

    try {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.brown)));

      // 1. Save Order
      await FirebaseFirestore.instance.collection('Orders').add({
        'customerEmail': userEmail,
        'items': cartItems.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {'name': data['name'], 'price': data['price'], 'qty': data['qty'], 'size': data['size'] ?? "Small", 'sugar': data['sugar'] ?? "Normal"};
        }).toList(),
        'totalAmount': total + deliveryFee,
        'status': 'Processing',
        'orderDate': FieldValue.serverTimestamp(),
        'address_text': finalAddress,
        'latitude': pickedLat,
        'longitude': pickedLng,
        'paymentMethod': selectedPaymentMethod,
        'paymentId': paymentId ?? "COD_ORDER",
      });

      // 2. Reduce Stock
      for (var cartItemDoc in cartItems) {
        var cartData = cartItemDoc.data() as Map<String, dynamic>;
        var productQuery = await FirebaseFirestore.instance.collection('Products').where('name', isEqualTo: cartData['name']).get();
        if (productQuery.docs.isNotEmpty) {
          var pDoc = productQuery.docs.first;
          await pDoc.reference.update({'quantity': (pDoc['quantity'] ?? 0) - cartData['qty']});
        }
      }

      // 3. Clear Cart
      var cartItemsRef = FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items');
      var snapshots = await cartItemsRef.get();
      for (var doc in snapshots.docs) { await doc.reference.delete(); }

      Navigator.pop(context); // Close loading
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Text("Order Placed Successfully! ☕", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [Center(child: TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 18))))],
        ),
      );
    } catch (e) { 
      Navigator.pop(context); 
      print("FIRESTORE SAVE ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 70, centerTitle: true, iconTheme: const IconThemeData(color: Colors.brown), title: const Text("Checkout", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 24))),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var items = snapshot.data!.docs;
          double subtotal = 0;
          for (var d in items) { var data = d.data() as Map<String, dynamic>; subtotal += (data['price'] * data['qty']); }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Address Section
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.brown)),
                TextButton.icon(
                  onPressed: () async {
                    final dynamic result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const AddressPicker()));
                    if (result != null && result is Map) {
                      setState(() { _addressController.text = result['address']; pickedLat = result['lat']; pickedLng = result['lng']; });
                    }
                  },
                  icon: const Icon(Icons.map_rounded, color: Colors.brown, size: 20),
                  label: const Text("Use Map", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                ),
              ]),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                child: TextField(controller: _addressController, maxLines: null, decoration: const InputDecoration(hintText: "Click 'Use Map'...", border: InputBorder.none, contentPadding: EdgeInsets.all(20), prefixIcon: Icon(Icons.location_on_rounded, color: Colors.brown))),
              ),
              const SizedBox(height: 30),
              
              // Payment Section
              const Text("Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.brown)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    RadioListTile(title: const Text("Cash on Delivery"), value: "COD", groupValue: selectedPaymentMethod, activeColor: Colors.brown, onChanged: (val) => setState(() => selectedPaymentMethod = val.toString())),
                    RadioListTile(title: const Text("Online Payment"), value: "ONLINE", groupValue: selectedPaymentMethod, activeColor: Colors.brown, onChanged: (val) => setState(() => selectedPaymentMethod = val.toString())),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              // Order Summary and Totals go here (Designs unchanged)
              const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.brown)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10)]),
                child: Column(children: items.map((doc) { var item = doc.data() as Map<String, dynamic>; return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${item["name"]} x${item["qty"]}", style: const TextStyle(fontWeight: FontWeight.bold)), Text("${item['size']} • ${item['sugar']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12))])), Text("₹${item["price"] * item["qty"]}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.brown))])); }).toList()),
              ),
              const SizedBox(height: 30),
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10)]), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subtotal"), Text("₹$subtotal", style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 10), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Delivery Fee"), Text("₹30")]), const Divider(height: 30), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.brown)), Text("₹${subtotal + deliveryFee}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.brown))])])),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(25), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]), 
        child: SizedBox(
          width: double.infinity, height: 55, 
          child: ElevatedButton(
            onPressed: () { 
              FirebaseFirestore.instance.collection('Carts').doc(userEmail).collection('Items').get().then((snap) { 
                double total = 0; 
                for (var d in snap.docs) { var data = d.data() as Map<String, dynamic>; total += (data['price'] * data['qty']); } 
                
                if (selectedPaymentMethod == "ONLINE") {
                  openRazorpay(total); 
                } else {
                  placeOrder(snap.docs, total); 
                }
              }); 
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), 
            child: Text(selectedPaymentMethod == "ONLINE" ? "Pay Now" : "Confirm Order", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
          )
        )
      ),
    );
  }
}
