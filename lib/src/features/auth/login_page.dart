import 'package:flutter/material.dart';
//import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/shared/main_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isUnlocked = false;
  bool _obscurePassword = true;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 16,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });

    _emailController.addListener(() {
      if (_errorMessage != null) setState(() => _errorMessage = null);
    });
    _passwordController.addListener(() {
      if (_errorMessage != null) setState(() => _errorMessage = null);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appUser = await AuthService.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isUnlocked = true);
      await Future.delayed(const Duration(milliseconds: 800));

      Navigator.pushReplacement(
        context,


      
        MaterialPageRoute(builder: (_) => MainLayoutPage(user: appUser)),
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isUnlocked = false;
      });

      _passwordController.clear();
      FocusScope.of(context).requestFocus(_passwordFocusNode);

      _shakeController.forward(from: 0.0);

      try {
        await AuthService.instance.logout();
      } catch (err) {
        debugPrint("Logout failed after invalid login: $err");
      }
    } catch (err) {
      debugPrint("Unexpected login error: $err");

      setState(() {
        _errorMessage = "Unexpected error. Please try again.";
        _isUnlocked = false;
      });
      _shakeController.forward(from: 0.0);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = "Enter your email to reset password.");
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(email);
      setState(() => _errorMessage = "✅ Reset link sent to $email");
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (err) {
      debugPrint("Reset password error: $err");
      setState(() => _errorMessage = "Failed to send reset link.");
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final offset = _shakeAnimation.value;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            _isUnlocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            key: ValueKey(_isUnlocked),
                            size: 80,
                            color: _isUnlocked
                                ? Colors.greenAccent
                                : (_errorMessage != null
                                    ? Colors.redAccent
                                    : Colors.deepPurple),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _emailController,
                    hint: "Email",
                    keyboard: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Email required";
                      }
                      final regex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$");
                      if (!regex.hasMatch(val)) {
                        return "Invalid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    hint: "Password",
                    obscure: _obscurePassword,
                    focusNode: _passwordFocusNode,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Password required";
                      }
                      if (val.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.deepPurple,
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                          ),
                          onPressed: _login,
                          child: const Text(
                            "Login",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.lightBlueAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, "/register"),
                    child: const Text(
                      "Don’t have an account? Register",
                      style: TextStyle(color: Colors.amber),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required FormFieldValidator<String> validator,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    FocusNode? focusNode,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        suffixIcon: suffixIcon,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.amber),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}