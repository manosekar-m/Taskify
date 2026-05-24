import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/hive_service.dart';
import '../widgets/custom_widgets.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _signup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await HiveService().registerUser(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: theme.cardColor,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: theme.primaryColor),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F0C1B), const Color(0xFF09090B)]
                : [const Color(0xFFEEF2F6), const Color(0xFFF9FAFC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Join Taskify and stay organized",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 45),
                  Padding(
                    padding: const EdgeInsets.only(left: 5, bottom: 8),
                    child: Text(
                      "Full Name",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.hintColor),
                    ),
                  ),
                  TaskifyTextField(
                    controller: _nameController,
                    hintText: "Enter your name",
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.only(left: 5, bottom: 8),
                    child: Text(
                      "Email Address",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.hintColor),
                    ),
                  ),
                  TaskifyTextField(
                    controller: _emailController,
                    hintText: "Enter your email",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.only(left: 5, bottom: 8),
                    child: Text(
                      "Password",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.hintColor),
                    ),
                  ),
                  TaskifyTextField(
                    controller: _passwordController,
                    hintText: "Create a password",
                    obscureText: !_isPasswordVisible,
                    isPasswordField: true,
                    onSuffixTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  const SizedBox(height: 45),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TaskifyButton(
                          text: "Sign Up",
                          onPressed: _signup,
                        ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Log In",
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
