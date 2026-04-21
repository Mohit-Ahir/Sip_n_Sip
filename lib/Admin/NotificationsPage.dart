import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  @override
  void initState() {
    super.initState();
    markNotificationsAsRead();
  }

  void markNotificationsAsRead() async {
    String? adminEmail = FirebaseAuth.instance.currentUser?.email;
    if (adminEmail != null) {
      await FirebaseFirestore.instance.collection('Users').doc(adminEmail).update({
        'lastNotificationCheck': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: const Text("System Alerts", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
        children: [
          
          // --- SECTION 1: LOW STOCK ALERTS ---
          sectionTitle("Inventory Alerts", Icons.warning_amber_rounded, Colors.redAccent),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Products').where('quantity', isLessThanOrEqualTo: 5).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return noAlertsWidget("All items are well stocked.");
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return alertCard(
                    title: "Low Stock: ${doc['name']}",
                    subtitle: "Only ${doc['quantity']} items remaining in inventory!",
                    color: Colors.orange.shade800,
                    icon: Icons.inventory_2_rounded,
                    bgColor: Colors.orange.shade50,
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 30),

          // --- SECTION 2: RECENT ORDERS ---
          sectionTitle("Recent Orders", Icons.history_rounded, Colors.brown),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Orders').orderBy('orderDate', descending: true).limit(15).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return noAlertsWidget("No recent orders found.");
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  String time = "Just now";
                  if (doc['orderDate'] != null) {
                    time = DateFormat('jm').format((doc['orderDate'] as Timestamp).toDate());
                  }
                  return alertCard(
                    title: "Order from ${doc['customerEmail'].toString().split('@')[0]}",
                    subtitle: "Amount: ₹${doc['totalAmount']} • Time: $time",
                    color: Colors.brown,
                    icon: Icons.shopping_bag_rounded,
                    bgColor: Colors.brown.shade50,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget sectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget alertCard({required String title, required String subtitle, required Color color, required IconData icon, required Color bgColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget noAlertsWidget(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
    );
  }
}