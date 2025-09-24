import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/shared/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      await AuthService.instance.login(_email.text.trim(), _password.text);
      await navigateAfterLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> navigateAfterLogin() async {
    final user = AuthService.instance.currentUser;

    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = snap.data()?['role'] as String?;
      print('Fetched role: $role');

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
        return;
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } catch (e) {
      print('Error fetching role: $e');
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.center,
              colors: [
                Colors.blue,
                Colors.black,
              ]
            ),   
        ),
        
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 400,
                    width: 400,
                    child: Lottie.asset('assets/Student.json'),
                  ),
                  Text(
                    'Student Reminder',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.lime,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),             
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _email,
                    style: TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email', 
                    labelStyle: TextStyle(color: Colors.white),
                    floatingLabelStyle: TextStyle(color: Colors.blue),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 2),
                    ),
              
                    fillColor: Colors.transparent,
                      border: OutlineInputBorder(),
                      filled: true,
                      hintStyle: TextStyle(color: Colors.white),
                      hintText: "Enter your email",
                      prefixIcon: Icon(Icons.email, color: Colors.blueGrey,)
                    ),
                    keyboardType: TextInputType.emailAddress,
                    
                  ),
                  const SizedBox(height: 12),
                      
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Colors.blueGrey),
                      fillColor: Colors.transparent,
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      floatingLabelStyle: TextStyle(color: Colors.blue),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          color: Colors.lime,
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                      ),
                    ),
                  ),
                      
                  const SizedBox(height: 20),
                      
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                        begin: Alignment.centerLeft, 
                        end: Alignment.centerRight,
                      )
                    ),
                    child: ElevatedButton(
                      onPressed: _busy ? null : _login,
                      style: ElevatedButton.styleFrom(minimumSize: Size(300, 50),
                      backgroundColor: Colors.transparent,
                      elevation: 5,
                      ),
                      child: _busy
                          ? const CircularProgressIndicator()
                          : const Text('Login',
                              style: TextStyle(fontSize: 16,
                               color: Colors.white,
                              ),
                        
                               
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                      
                  OutlinedButton(

                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                    child: _busy
                        ? const CircularProgressIndicator()
                        : const Text('No Account? Register',
                            style: TextStyle(fontSize: 15,
                            color: Colors.white
                            ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
