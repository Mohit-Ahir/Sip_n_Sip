import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  final List<String> statusList = ["Processing", "Preparing", "Delivered", "Cancelled"];

  Color getStatusColor(String status) {
    if (status == "Delivered") return Colors.green;
    if (status == "Cancelled") return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5D6C3),
      appBar: AppBar(title: const Text("Manage Orders", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF7B5E57), centerTitle: true),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Orders').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              String status = order['status'];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Customer: ${order['customerEmail']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    for (var item in order['items']) Text("• ${item['name']} x${item['qty']}"),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total: ₹${order['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                       
                        DropdownButton<String>(
                          value: status,
                          style: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.bold),
                          onChanged: (newStatus) {
                            FirebaseFirestore.instance.collection('Orders').doc(order.id).update({'status': newStatus});
                          },
                          items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),


      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
          if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageProductsPage()));
          if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ViewUsersPage()));
          if (index == 4) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProfilePage()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}