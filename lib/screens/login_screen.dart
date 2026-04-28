import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user.dart';
import '../widgets/custom_widgets.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.45, 1.0],
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
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
                    const SizedBox(height: 80),
                    Text(
                      "Welcome\nBack",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Login to continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 60),
                    TaskifyTextField(
                      controller: emailController,
                      hintText: "Email",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TaskifyTextField(
                      controller: passController,
                      hintText: "Password",
                      obscureText: _obscureText,
                      isPasswordField: true,
                      onSuffixTap: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    TaskifyButton(
                      text: "Login",
                      onPressed: () {
                        if (emailController.text.isNotEmpty && passController.text.isNotEmpty) {
                          final usersBox = Hive.box<User>('users');
                          final user = usersBox.values.cast<User?>().firstWhere(
                            (u) => u?.email == emailController.text && u?.password == passController.text,
                            orElse: () => null,
                          );
                          if (user != null) {
                            Hive.box('session').put('currentUserEmail', emailController.text);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Invalid email or password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.black,
                                duration: Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill in every detail to login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.black,
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w500),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const SignupScreen()),
                              );
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                            ),
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
