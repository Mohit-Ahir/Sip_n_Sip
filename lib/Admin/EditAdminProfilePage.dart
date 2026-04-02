import 'package:flutter/material.dart';

class EditAdminProfilePage extends StatelessWidget {
  const EditAdminProfilePage({super.key});

  Widget inputField(IconData icon, String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.brown.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.brown),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 10,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7DCCF),

      body: Column(
        children: [
          /// Top Profile Section
          Container(
            height: 220,
            width: double.infinity,
            color: const Color(0xFF7B5644),
            child: const Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 70, color: Color(0xFF7B5644)),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  inputField(Icons.person, "Admin Name"),
                  inputField(Icons.email, "Email"),
                  inputField(Icons.lock, "New Password"),
                  inputField(Icons.lock_outline, "Confirm Password"),

                  const SizedBox(height: 30),

                  /// Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5644),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // Save changes logic
                      },
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
