import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({super.key, required this.orderId, required this.orderData});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final List<String> statusList = ["Processing", "Preparing", "Delivered", "Cancelled"];
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.orderData['status'] ?? "Processing";
  }

  // STATUS COLOR HELPER (Matches ManageOrdersPage)
  Color getStatusColor(String status) {
    if (status == "Delivered") return Colors.green;
    if (status == "Cancelled") return Colors.redAccent;
    if (status == "Preparing") return Colors.blueAccent;
    return Colors.orange; 
  }

  void updateStatus(String? newStatus) async {
    if (newStatus == null) return;
    await FirebaseFirestore.instance.collection('Orders').doc(widget.orderId).update({'status': newStatus});
    setState(() => currentStatus = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.brown, content: Text("Order status updated to $newStatus"))
    );
  }

  void deleteOrder() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Delete Order?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("This will remove the order permanently from the records."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('Orders').doc(widget.orderId).delete();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color sColor = getStatusColor(currentStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), // Premium Cream

      // 1. MATCHING ROUNDED BROWN APP BAR
      appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: const Text(
          "Receipt Details", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.1)
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 2. CUSTOMER INFO CARD
            sectionLabel("CUSTOMER INFO"),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: premiumCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alternate_email_rounded, color: Colors.brown, size: 20),
                      const SizedBox(width: 10),
                      Text(widget.orderData['customerEmail'] ?? "No Email", 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.brown)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.brown, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(widget.orderData['address'] ?? "No Address Provided", 
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. ITEMS SUMMARY CARD
            sectionLabel("ORDERED ITEMS"),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: premiumCardDecoration(),
              child: Column(
                children: [
                  for (var item in widget.orderData['items'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${item['name']} x${item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("${item['size']} • ${item['sugar']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                          Text("₹${item['price'] * item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                        ],
                      ),
                    ),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.brown)),
                      Text("₹${widget.orderData['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.brown)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. MANAGEMENT ACTIONS CARD
            sectionLabel("MANAGE STATUS"),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: premiumCardDecoration(),
              child: Column(
                children: [
                  ListTile(
                    title: const Text("Order Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: sColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sColor.withOpacity(0.3))
                      ),
                      child: DropdownButton<String>(
                        value: currentStatus,
                        underline: const SizedBox(),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: sColor),
                        style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 13),
                        onChanged: updateStatus,
                        items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Divider()),
                  ListTile(
                    onTap: deleteOrder,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    ),
                    title: const Text("Delete permanently", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
    );
  }

  BoxDecoration premiumCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
      ],
    );
  }
}