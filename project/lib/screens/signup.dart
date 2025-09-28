import 'package:flutter/material.dart';
import 'login.dart';
import 'dashboard_content.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. Global key to uniquely identify the Form widget and allow for validation.
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers for capturing the user input.
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();

  // State to manage the shop vs. referral toggle
  bool _isShopCreator = true;

  @override
  void dispose() {
    // Dispose of controllers when the widget is removed
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
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
      print('Full Name: ${_fullNameController.text}');
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');
      if (_isShopCreator) {
        print('Shop Name: ${_shopNameController.text}');
      }
      Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  DashboardContent()),
    );
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

      // --- Conditional Mandatory Check (Shop Name) ---
      if (label == 'Shop Name' && _isShopCreator) {
        if (value == null || value.isEmpty) {
          return 'Shop name is required to create a new shop.';
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

  // Simplified segmented control chip (Unchanged)
  Widget _buildSimpleToggleChip(String text, bool isActive, VoidCallback onTap) {
    const primaryColor = Color(0xFF2A59C3);
    const surfaceColor = Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : surfaceColor,
            borderRadius: BorderRadius.circular(10),
            // Light mode styling
            boxShadow: isActive 
              ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 6)] 
              : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
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
          'Create Account', 
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

              // --- Form Widget wraps all input fields ---
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Input Fields with Controllers and Validation ---
                    _buildLabeledInputField(
                      label: 'Full Name',
                      hintText: 'Enter your full name',
                      icon: Icons.person_outline,
                      controller: _fullNameController,
                      // isRequired defaults to true here
                    ),
                    _buildLabeledInputField(
                      label: 'Email Address',
                      hintText: 'Enter your email',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      // isRequired defaults to true here
                    ),
                    _buildLabeledInputField(
                      label: 'Password',
                      hintText: 'Create a password',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      isPassword: true,
                      // isRequired defaults to true here
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --- Segmented Control ---
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    _buildSimpleToggleChip(
                      'Create a new shop',
                      _isShopCreator,
                      () {
                        setState(() {
                          _isShopCreator = true;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildSimpleToggleChip(
                      'Join with referral',
                      !_isShopCreator,
                      () {
                        setState(() {
                          _isShopCreator = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // --- Shop Name Field (Conditional) ---
              if (_isShopCreator)
                // isRequired parameter is omitted here, relying on default true. 
                // The validator handles the conditional check based on _isShopCreator.
                _buildLabeledInputField(
                  label: 'Shop Name',
                  hintText: 'Enter your shop name',
                  icon: Icons.storefront_outlined,
                  controller: _shopNameController,
                ),
              
              const SizedBox(height: 10),

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
                  'Create Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 30),

              // --- Text Link ---
              GestureDetector(
                onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: const TextStyle(
                        fontSize: 15, 
                        color: Color(0xFF6C757D), 
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign in',
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
