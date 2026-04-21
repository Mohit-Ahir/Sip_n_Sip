import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sip_and_sip/Admin/OrderDetailsPage.dart'; // Import the new page
import 'package:sip_and_sip/Admin/AdminDashboardPage.dart';
import 'package:sip_and_sip/Admin/ManageProductsPage.dart';
import 'package:sip_and_sip/Admin/ViewUsersPage.dart';
import 'package:sip_and_sip/Admin/AdminProfilePage.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});
  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  Color getStatusColor(String status) {
    if (status == "Delivered") return Colors.green;
    if (status == "Cancelled") return Colors.redAccent;
    if (status == "Preparing") return Colors.blueAccent;
    return Colors.orange; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
        title: const Text("Recent Orders", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Orders').orderBy('orderDate', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.brown));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No orders found."));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              var data = order.data() as Map<String, dynamic>;
              String status = data['status'] ?? "Processing";
              Color sColor = getStatusColor(status);

              return GestureDetector(
                onTap: () {
                  // REDIRECT TO DETAILS PAGE
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => OrderDetailsPage(orderId: order.id, orderData: data))
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))]
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.brown.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.brown),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['customerEmail'] ?? "Guest", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.brown), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text("Total: ₹${data['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(status, style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
          child: BottomNavigationBar(
            currentIndex: 2, type: BottomNavigationBarType.fixed, backgroundColor: Colors.white, selectedItemColor: Colors.brown, unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true, selectedFontSize: 12, unselectedFontSize: 11, selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: (index) {
              if (index == 2) return;
              if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
              if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageProductsPage()));
              if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ViewUsersPage()));
              if (index == 4) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProfilePage()));
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dash"),
              BottomNavigationBarItem(icon: Icon(Icons.coffee_rounded), label: "Products"),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: "Orders"),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Users"),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}