import 'package:flutter/material.dart';
import 'package:inventify/screens/signup_screen.dart';
import 'package:inventify/screens/forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Global key to uniquely identify the Form widget and allow for validation.
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers for capturing the user input.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // Dispose of controllers when the widget is removed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper function to handle form submission and validation
  void _submitForm() {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      // Form is valid: proceed with account creation logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing data...')),
      );
      
      // Print captured data (replace with actual registration logic)
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');
     
    } else {
      // Form is invalid: validation messages are automatically shown
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly.')),
      );
    }
  }

  // New helper function to build the labeled TextFormField section
  Widget _buildLabeledInputField({
    required String label,
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isRequired = true, // isRequired is kept for standard fields
  }) {
    String? validator(String? value) {
      // --- Password Strength Check ---
      if (label == 'Password' && value != null && value.isNotEmpty) {
        if (value.length < 8) {
          return 'Password must be at least 8 characters long.';
        }
        if (!RegExp(r'[A-Z]').hasMatch(value)) {
          return 'Password must contain at least one uppercase letter.';
        }
        // This regex matches any non-alphanumeric character (special character)
        if (!RegExp(r'[!@#\$%\^&\*(),\._":{}|<>]').hasMatch(value)) {
          return 'Password must contain at least one special character.';
        }
      }
      
      // --- Basic Mandatory Check (for Full Name, Email, Password) ---
      if (isRequired && (value == null || value.isEmpty)) {
        return 'This field is required.';
      }

      // --- Email Format Check ---
      if (label == 'Email Address' && value != null && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
        return 'Please enter a valid email address.';
      }

      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explicit Text Label above the input field
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF212529),
              ),
            ),
          ),
          // Text Field (Now TextFormField for validation)
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            // We rely on the validator function above to determine required state
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon, color: const Color(0xFF6C757D)),
              filled: true,
              fillColor: Colors.white,
              // Error styling
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2A59C3);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212529)),
          onPressed: () {},
        ),
        title: const Text(
          'Welcome Back!', 
          style: TextStyle(
            color: Color(0xFF212529),
            fontWeight: FontWeight.bold,
          ),
        ), 
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Log in to continue to your dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 30),
 
              // --- Form Widget wraps all input fields ---
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabeledInputField(
                      label: 'Email Address',
                      hintText: 'Enter your email',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      // isRequired defaults to true here
                    ),
                    _buildLabeledInputField(
                      label: 'Password',
                      hintText: 'Enter your password',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      isPassword: true,
                      // isRequired defaults to true here
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                         
                  Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                          );
              
                      },
                      style: TextButton.styleFrom(
      padding: EdgeInsets.zero, // removes default padding
      minimumSize: Size(0, 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: primaryColor,
                            fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

              // --- Sign Up Button (Calls _submitForm) ---
              ElevatedButton(
                onPressed: _submitForm, // Call validation logic
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 30),

              // --- Text Link ---
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                },
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: const TextStyle(
                        fontSize: 15, 
                        color: Color(0xFF6C757D), 
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
