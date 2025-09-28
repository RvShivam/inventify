import 'package:flutter/material.dart';
import 'login_screen.dart'; 

class Validators {
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Must contain a lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain a number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Must contain a special character';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter a $fieldName';
    }
    return null;
  }
}


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isCreatingShop = true; 

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _referralController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _onSignupPressed() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    // TODO: Add your API call logic here
    print('Form is valid! Signing up...');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor, 
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              // ADD THE FORM WIDGET HERE
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    Text('Full Name', style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      validator: Validators.name,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ... The rest of your Column's children ...
                    Text('Email Address', style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Password', style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      validator: Validators.password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Create a password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ToggleButtons(
                      isSelected: [_isCreatingShop, !_isCreatingShop],
                      onPressed: (index) {
                        setState(() {
                          _isCreatingShop = index == 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: colors.onPrimary,
                      color: colors.onSurface.withOpacity(0.8),
                      fillColor: colors.primary,
                      borderColor: colors.onSurface.withOpacity(0.12),
                      selectedBorderColor: colors.primary,
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 29), child: Text('Create a new shop')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 29), child: Text('Join with referral')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isCreatingShop)
                      _buildShopNameField(textTheme)
                    else
                      _buildReferralField(textTheme),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _onSignupPressed,
                        child: const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?", style: textTheme.bodyMedium),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colors.secondary,
                          ),
                          child: const Text('Sign in'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopNameField(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shop Name', style: textTheme.bodySmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: _shopNameController,
          validator: (value) => Validators.required(value, 'Shop Name'),
          decoration: const InputDecoration(
            hintText: 'Enter your shop name',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildReferralField(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Referral Code', style: textTheme.bodySmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: _referralController,
          validator: (value) => Validators.required(value, 'Referral Code'),
          decoration: const InputDecoration(
            hintText: 'Enter referral code',
            prefixIcon: Icon(Icons.group_add_outlined),
          ),
        ),
      ],
    );
  }
}