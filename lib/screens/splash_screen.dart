import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAuthenticating = false;
  final LocalAuthentication auth = LocalAuthentication();
  
  String _currentQuote = "";
  int _quoteIndex = 0;
  Timer? _quoteTimer;
  final List<String> _quotes = [
    "Plan your day, own your life.",
    "Small steps, big results.",
    "Focus on being productive, not busy.",
    "Your future is created by what you do today.",
    "Turn dreams into deadlines.",
    "Efficiency is doing things right.",
  ];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    _startQuoteAnimation();
    _navigateToNext();
  }

  void _startQuoteAnimation() {
    final quote = _quotes[DateTime.now().second % _quotes.length];
    const totalAnimDuration = Duration(milliseconds: 2000);
    final charDelay = totalAnimDuration.inMilliseconds ~/ (quote.isNotEmpty ? quote.length : 1);

    _quoteTimer = Timer.periodic(Duration(milliseconds: charDelay), (timer) {
      if (_quoteIndex < quote.length) {
        if (mounted) {
          setState(() {
            _currentQuote = quote.substring(0, _quoteIndex + 1);
            _quoteIndex++;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final settingsBox = Hive.box('settings');
    final bool isBiometricEnabled = settingsBox.get('isBiometricEnabled', defaultValue: false);

    if (isBiometricEnabled) {
      setState(() => _isAuthenticating = true);
      try {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to access Taskify',
        );
        
        if (didAuthenticate) {
          _proceedToNext();
        } else {
          setState(() => _isAuthenticating = false);
        }
      } catch (e) {
        setState(() => _isAuthenticating = false);
        _proceedToNext(); // Fallback if biometrics fail or aren't supported
      }
    } else {
      _proceedToNext();
    }
  }

  void _proceedToNext() {
    if (!mounted) return;
    final sessionBox = Hive.box('session');
    final String? userId = sessionBox.get('userId');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => userId != null ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9F9F7),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 100), // Push content down a bit
                Text(
                  "TASKIFY",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 20,
                  child: Text(
                    _currentQuote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (_isAuthenticating) ...[
                  const SizedBox(height: 50),
                  GestureDetector(
                    onTap: _navigateToNext,
                    child: Column(
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: 40,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Tap to try again",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
