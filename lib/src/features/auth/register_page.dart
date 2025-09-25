import 'package:flutter/material.dart';
//import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/shared/main_layout.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _courseGroupController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_clearError);
    _lastNameController.addListener(_clearError);
    _courseGroupController.addListener(_clearError);
    _emailController.addListener(_clearError);
    _phoneController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _courseGroupController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appUser = await AuthService.instance.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        courseGroup: _courseGroupController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainLayoutPage(user: appUser)),
      );
    } on AuthException catch (e) {
      debugPrint("AuthException during register: ${e.message}");
      setState(() => _errorMessage = e.message);
    } catch (err) {
      debugPrint("Unexpected registration error: $err");
      setState(() => _errorMessage = "Unexpected error. Please try again.");
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _firstNameController,
                    hint: "First Name",
                    validator: (val) => val == null || val.isEmpty
                        ? "First name required"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _lastNameController,
                    hint: "Last Name",
                    validator: (val) => val == null || val.isEmpty
                        ? "Last name required"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _courseGroupController,
                    hint: "Course Group",
                    validator: (val) => val == null || val.isEmpty
                        ? "Course group required"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _emailController,
                    hint: "Email",
                    keyboard: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Email required";
                      final regex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$");
                      if (!regex.hasMatch(val)) return "Invalid email address";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _phoneController,
                    hint: "Phone",
                    keyboard: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Phone required";
                      if (val.length < 7) return "Enter a valid phone number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _passwordController,
                    hint: "Password",
                    obscure: _obscurePassword,
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
                          onPressed: _register,
                          child: const Text(
                            "Register",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, "/login"),
                    child: const Text(
                      "Already have an account? Login",
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
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
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
