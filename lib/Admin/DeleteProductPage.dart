import 'package:flutter/material.dart';

class DeleteProductPage extends StatelessWidget {
  final String productName = "Cappuccino";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F3F1),

      appBar: AppBar(
        title: Text("Delete Product"),
        backgroundColor: Colors.brown,
      ),

      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Container(
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Icon(Icons.delete, size: 60, color: Colors.red),

                SizedBox(height: 15),

                Text(
                  "Delete Product?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  "Are you sure you want to delete $productName?",
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Cancel"),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {

                        // Delete product from database here

                        Navigator.pop(context);
                      },
                      child: Text("Delete"),
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