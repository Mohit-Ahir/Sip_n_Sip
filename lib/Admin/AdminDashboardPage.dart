import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator
import 'package:sip_and_sip/Admin/ManageProductsPage.dart';
import 'package:sip_and_sip/Admin/ManageOrdersPage.dart';
import 'package:sip_and_sip/Admin/ViewUsersPage.dart';
import 'package:sip_and_sip/Admin/AdminProfilePage.dart';
import 'package:sip_and_sip/Admin/NotificationsPage.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    String? adminEmail = FirebaseAuth.instance.currentUser?.email;

    // WRAP SCAFFOLD WITH POPSCOPE
    return PopScope(
      canPop: false, // Block automatic exit
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // SHOW ADMIN EXIT DIALOG
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFFF5E6D3),
            title: const Text("Exit Admin Panel?", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
            content: const Text("Are you sure you want to exit the management system?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                onPressed: () => SystemNavigator.pop(),
                child: const Text("Exit Now", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5E6D3), 
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 70,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Text("Sip & Sip", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2)),
            ],
          ),
          actions: [
            if (adminEmail != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('Users').doc(adminEmail).snapshots(),
                builder: (context, userSnap) {
                  Timestamp lastCheckTime = Timestamp.fromDate(DateTime(2020));
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final Map<String, dynamic>? userData = userSnap.data!.data() as Map<String, dynamic>?;
                    if (userData != null && userData.containsKey('lastNotificationCheck') && userData['lastNotificationCheck'] != null) {
                      lastCheckTime = userData['lastNotificationCheck'] as Timestamp;
                    }
                  }
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('Orders').where('orderDate', isGreaterThan: lastCheckTime).snapshots(),
                    builder: (context, orderSnap) {
                      int newOrders = orderSnap.hasData ? orderSnap.data!.docs.length : 0;
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('Products').where('quantity', isLessThanOrEqualTo: 5).snapshots(),
                        builder: (context, stockSnap) {
                          int lowStockItems = stockSnap.hasData ? stockSnap.data!.docs.length : 0;
                          int totalAlerts = newOrders + lowStockItems;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.brown, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()))),
                              if (totalAlerts > 0)
                                Positioned(right: 10, top: 15, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text(totalAlerts.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('Users').doc(adminEmail).get(),
                  builder: (context, snapshot) {
                    String name = "Admin";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      name = snapshot.data!['name']?.toString().split(" ")[0] ?? "Admin";
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hello, $name 👋", style: TextStyle(fontSize: 16, color: Colors.brown.shade600, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        const Text("Dashboard", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.brown.shade800, Colors.brown.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("SYSTEM STATUS", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text("Inventory & Orders are monitored in real-time.", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])), Icon(Icons.bolt_rounded, size: 50, color: Colors.white24)]),
                ),
                const SizedBox(height: 30),
                const Text("Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
                const SizedBox(height: 15),
                GridView(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
                  children: [
                    streamCard("Products", FirebaseFirestore.instance.collection('Products').snapshots(), Icons.coffee_rounded),
                    streamCard("Orders", FirebaseFirestore.instance.collection('Orders').snapshots(), Icons.shopping_bag_rounded),
                    streamCard("Users", FirebaseFirestore.instance.collection('Users').where('role', isEqualTo: 'user').snapshots(), Icons.people_alt_rounded),
                    revenueCard(),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
            child: BottomNavigationBar(
              currentIndex: 0, type: BottomNavigationBarType.fixed, backgroundColor: Colors.white, selectedItemColor: Colors.brown, unselectedItemColor: Colors.grey.shade400, showUnselectedLabels: true,
              onTap: (index) {
                if (index == 0) return;
                switch (index) {
                  case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageProductsPage())); break;
                  case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageOrdersPage())); break;
                  case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ViewUsersPage())); break;
                  case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProfilePage())); break;
                }
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
      ),
    );
  }

  Widget revenueCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Orders').where('status', isEqualTo: 'Delivered').snapshots(),
      builder: (context, snapshot) {
        double totalRevenue = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            totalRevenue += (doc['totalAmount'] ?? 0).toDouble();
          }
        }
        return dashboardCard("Revenue", "₹${totalRevenue.toStringAsFixed(0)}", Icons.account_balance_wallet_rounded);
      },
    );
  }

  Widget streamCard(String title, Stream<QuerySnapshot> stream, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "0";
        return dashboardCard(title, count, icon);
      },
    );
  }

  Widget dashboardCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, size: 28, color: Colors.brown), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.brown)), Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.brown.shade300))])]),
    );
  }
}