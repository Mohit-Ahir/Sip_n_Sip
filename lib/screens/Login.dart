import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED for exiting the app
import 'package:google_sign_in/google_sign_in.dart'; 
import 'package:sip_and_sip/Admin/AdminDashboardPage.dart';
import 'package:sip_and_sip/screens/SignUp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sip_and_sip/User/Home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isGoogleLoading = false; 
  bool _isLoading = false; 
  bool passwordVisible = false;

  // --- EXIT ALERT BOX ---
  void showExitAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6D3),
        title: const Text("Exit App", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to close Sip & Sip? ☕", style: TextStyle(color: Colors.brown)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            onPressed: () => SystemNavigator.pop(), // Closes the app
            child: const Text("Yes, Exit", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- SIGN IN ALERT BOX ---
  void showSipAndSipAlert(String title, String message, bool isSuccess, VoidCallback? onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6D3),
        title: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.brown)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onConfirm != null) onConfirm();
            },
            child: const Text("Continue", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> googleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return; 
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.email).get();
        if (userDoc.exists) {
          String role = userDoc['role'].toString().trim().toLowerCase();
          showSipAndSipAlert("Welcome!", "Login Successful via Google.", true, () {
            if (role == "admin") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
            }
          });
        } else {
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn().signOut();
          showSipAndSipAlert("Access Denied", "No database record found.", false, null);
        }
      }
    } catch (e) {
      showSipAndSipAlert("Login Error", e.toString(), false, null);
    } finally {
      setState(() => _isGoogleLoading = false);
    }
  }

  signin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailController.text.trim(), 
            password: passwordController.text.trim()
        );
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(emailController.text.trim()).get();
        
        if (userDoc.exists) {
          String role = userDoc['role'].toString().trim().toLowerCase();
          showSipAndSipAlert("Login Success", "Welcome back!", true, () {
             if (role == "admin") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
            }
          });
        } else {
          await FirebaseAuth.instance.signOut();
          showSipAndSipAlert("Error", "User record not found.", false, null);
        }
      } on FirebaseAuthException catch (e) {
        showSipAndSipAlert("Failed", e.message ?? "Incorrect details.", false, null);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents direct exit
      onPopInvoked: (didPop) {
        if (didPop) return;
        showExitAlert(); // Shows your alert box
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5E6D3),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.brown.shade200, blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(Icons.local_cafe, size: 60, color: Color(0xFF6F4E37)),
                    ),
                    const SizedBox(height: 15),
                    const Text('Login Page', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.brown)),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: emailController,
                      validator: (v) => (v!.isEmpty) ? "Enter email" : null,
                      decoration: InputDecoration(
                        hintText: "Email", hintStyle: const TextStyle(color: Colors.brown),
                        prefixIcon: const Icon(Icons.email, color: Colors.brown),
                        fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !passwordVisible,
                      validator: (v) => (v!.length < 6) ? "Min 6 chars" : null,
                      decoration: InputDecoration(
                        hintText: "Password", hintStyle: const TextStyle(color: Colors.brown),
                        prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                        suffixIcon: IconButton(icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.brown), onPressed: () => setState(() => passwordVisible = !passwordVisible)),
                        fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : signin, 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white))
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Or With", style: TextStyle(color: Colors.brown))), Expanded(child: Divider())]),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        onPressed: _isGoogleLoading ? null : googleLogin,
                        style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Colors.brown.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isGoogleLoading ? const CircularProgressIndicator(color: Colors.brown) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset("assets/google.png", height: 22), const SizedBox(width: 12), const Text("Continue with Google", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500))]),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Don't have an account?"), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Signup())), child: const Text("Sign Up", style: TextStyle(color: Colors.brown)))]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}