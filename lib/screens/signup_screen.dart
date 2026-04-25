import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user.dart';
import '../widgets/custom_widgets.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: theme.scaffoldBackgroundColor,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.8, -0.8),
              radius: 1.2,
              colors: [
                theme.primaryColor.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 70),
                    Text(
                      "Create\nAccount",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Sign up to get started",
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TaskifyTextField(controller: nameController, hintText: "Full Name"),
                    const SizedBox(height: 20),
                    TaskifyTextField(controller: emailController, hintText: "Email", keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    TaskifyTextField(
                      controller: passController,
                      hintText: "Password",
                      obscureText: _obscureText,
                      isPasswordField: true,
                      onSuffixTap: () => setState(() => _obscureText = !_obscureText),
                    ),
                    const SizedBox(height: 40),
                    TaskifyButton(
                      text: "Sign Up",
                      onPressed: () {
                        if (nameController.text.isNotEmpty &&
                            emailController.text.isNotEmpty &&
                            passController.text.isNotEmpty) {
                          final usersBox = Hive.box<User>('users');
                          final exists = usersBox.values.any((u) => u.email == emailController.text);
                          if (exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Email already registered. Please login."), backgroundColor: Colors.orangeAccent),
                            );
                            return;
                          }
                          usersBox.add(User(name: nameController.text, email: emailController.text, password: passController.text));
                          Hive.box('session').put('currentUserEmail', emailController.text);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill in every detail to sign up"), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account? ", style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w500)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                            child: Text("Login", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
