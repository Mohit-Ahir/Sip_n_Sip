import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sip_and_sip/screens/Login.dart';
import 'package:sip_and_sip/User/Home.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  bool passwordVisible = false, confirmPasswordVisible = false, _isGoogleLoading = false, _isSaving = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmpasswordController = TextEditingController();

  void showExitAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6D3),
        title: const Text("Exit App", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        content: const Text("Do you want to close the application?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            onPressed: () => SystemNavigator.pop(),
            child: const Text("Yes, Exit", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

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

  Future<void> googleSignup() async {
    setState(() => _isGoogleLoading = true);
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('Users').doc(user.email).set({
          'name': user.displayName ?? "New User",
          'phone': "Not provided",
          'email': user.email,
          'password': "Signed in with Google",
          'role': 'user',
          'CreateAt': FieldValue.serverTimestamp(),
        });
        showSipAndSipAlert("Success", "Account created!", true, () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
        });
      }
    } catch (e) {
      showSipAndSipAlert("Error", e.toString(), false, null);
    } finally {
      setState(() => _isGoogleLoading = false);
    }
  }

  signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(), password: passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('Users').doc(emailController.text.trim()).set({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'role': 'user',
          'CreateAt': FieldValue.serverTimestamp(),
        });
        showSipAndSipAlert("Success!", "Your account is ready.", true, () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
        });
      } on FirebaseAuthException catch (e) {
        showSipAndSipAlert("Failed", e.message ?? "Error", false, null);
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        showExitAlert();
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
                    const Text('Create account', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.brown)),
                    const SizedBox(height: 40),
                    buildTextField(nameController, "Full Name", Icons.person, (v) => v!.isEmpty ? "Enter name" : null),
                    const SizedBox(height: 20),
                    buildTextField(phoneController, "Phone", Icons.phone, (v) => v!.length != 10 ? "10 digits" : null),
                    const SizedBox(height: 20),
                    buildTextField(emailController, "Email", Icons.email, (v) => !v!.contains("@") ? "Invalid email" : null),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !passwordVisible,
                      validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
                      decoration: InputDecoration(
                        hintText: "Password", prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                        suffixIcon: IconButton(icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.brown), onPressed: () => setState(() => passwordVisible = !passwordVisible)),
                        fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: confirmpasswordController,
                      obscureText: !confirmPasswordVisible,
                      validator: (v) => v != passwordController.text ? "Not same" : null,
                      decoration: InputDecoration(
                        hintText: "Confirm", prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                        suffixIcon: IconButton(icon: Icon(confirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.brown), onPressed: () => setState(() => confirmPasswordVisible = !confirmPasswordVisible)),
                        fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSaving ? null : signup, style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)))),
                    const SizedBox(height: 30),
                    Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Or With", style: TextStyle(color: Colors.brown))), Expanded(child: Divider())]),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        onPressed: _isGoogleLoading ? null : googleSignup,
                        style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Colors.brown.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isGoogleLoading ? const CircularProgressIndicator(color: Colors.brown) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset("assets/google.png", height: 22), const SizedBox(width: 12), const Text("Continue with Google", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500))]),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Already have an account?"), TextButton(onPressed: () => Navigator.pop(context), child: const Text("Login", style: TextStyle(color: Colors.brown)))]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String hint, IconData icon, String? Function(String?)? validator) {
    return TextFormField(controller: controller, validator: validator, decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.brown), prefixIcon: Icon(icon, color: Colors.brown), fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  }
}