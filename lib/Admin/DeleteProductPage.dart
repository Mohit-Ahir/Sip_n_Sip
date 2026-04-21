import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeleteProductPage extends StatefulWidget {
  // Parameters to receive data from the previous screen
  final String docId;
  final String productName;

  const DeleteProductPage({
    super.key, 
    required this.docId, 
    required this.productName
  });

  @override
  State<DeleteProductPage> createState() => _DeleteProductPageState();
}

class _DeleteProductPageState extends State<DeleteProductPage> {
  bool isDeleting = false;

  // 1. LOGIC: DELETE FROM FIREBASE
  Future<void> deleteProduct() async {
    setState(() => isDeleting = true);
    
    try {
      // Deletes the specific document using its ID
      await FirebaseFirestore.instance
          .collection('Products')
          .doc(widget.docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.brown,
            content: Text("${widget.productName} removed from menu successfully"),
          ),
        );
        Navigator.pop(context); // Go back to All Products list
      }
    } catch (e) {
      setState(() => isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3), // Premium Cream matching your app
      
      // MODERN TRANSPARENT APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.brown),
        title: const Text(
          "Confirm Removal",
          style: TextStyle(
            color: Colors.brown, 
            fontWeight: FontWeight.w900, 
            fontSize: 20,
            letterSpacing: 1.2
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35), // Deep rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 2. MODERN ILLUSTRATION CONTAINER
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded, 
                    size: 70, 
                    color: Colors.redAccent.shade700
                  ),
                ),

                const SizedBox(height: 30),

                // 3. DYNAMIC WARNING TEXT
                const Text(
                  "Delete Product?",
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.brown
                  ),
                ),
                
                const SizedBox(height: 15),
                
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.grey, 
                      fontSize: 16, 
                      height: 1.5
                    ),
                    children: [
                      const TextSpan(text: "Are you sure you want to remove "),
                      TextSpan(
                        text: widget.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.black87
                        ),
                      ),
                      const TextSpan(text: " from the system? This cannot be undone."),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 4. ACTION BUTTONS
                if (isDeleting)
                  const CircularProgressIndicator(color: Colors.brown)
                else
                  Column(
                    children: [
                      // DELETE BUTTON (PRIMARY)
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.shade700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)
                            ),
                          ),
                          onPressed: deleteProduct,
                          child: const Text(
                            "Yes, Remove Item",
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 16
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),

                      // CANCEL BUTTON (SECONDARY)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel, Keep it",
                            style: TextStyle(
                              color: Colors.brown.shade400, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 16
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}