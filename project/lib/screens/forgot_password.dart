import 'package:flutter/material.dart';
import 'package:project/screens/reset_password.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  // Simple handler for button press (placeholder)
  void _sendResetLink(BuildContext context) {
    // In a real app, you would validate the email and call an API here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset link sent to your email (placeholder)!')),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Use the primary color from the parent application's theme
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'), 
        centerTitle: true,// Added the title to the AppBar
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Using `automaticallyImplyLeading: true` will show a back button if available
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // The large title from the body has been moved to the AppBar.
            // Removed: // 1. Title Text and SizedBox(height: 12.0)

            // 2. Subtitle/Instructions
            Center(
            child:Text(
              "Enter your email and we'll send you a link to reset your password.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            ),
            const SizedBox(height: 40.0),

            // 3. Email Input Field (Styling moved here)
            const Text(
              'Email Address',
               style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                // Custom input field appearance for the design
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100, // Light background
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              ),
            ),
            const SizedBox(height: 40.0),

            // 4. Primary Button (Styling moved here)
            ElevatedButton(
              onPressed: (){
               Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                          );},
              style: ElevatedButton.styleFrom(
                // Use the primary color from the theme
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                // Custom button appearance for the design
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('Send Reset Link'),
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
