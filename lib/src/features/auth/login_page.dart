import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/shared/main_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  /// Handle login logic
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cred = await AuthService.instance.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final uid = cred.user!.uid;
      final appUser = await AuthService.instance.fetchProfile(uid);

      if (appUser == null) {
        throw Exception("Profile not found. Please register again.");
      }

      if (!mounted) return;

      // ✅ Navigate role-aware
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainLayoutPage(user: appUser)),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? "Authentication failed");
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.lock, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 20),
                _buildTextField(_emailController, "Email",
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, "Password", obscure: true),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Text(_errorMessage!,
                      style: const TextStyle(color: Colors.redAccent)),

                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.deepPurple)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                        ),
                        onPressed: _login,
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, "/register"),
                  child: const Text("Don’t have an account? Register",
                      style: TextStyle(color: Colors.amber)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool obscure = false, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.amber),
        ),
      ),
    );
  }
}