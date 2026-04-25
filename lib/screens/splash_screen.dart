import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final String _title = "TASKIFY";
  final List<String> _quotes = [
    "The secret of getting ahead is getting started.",
    "Focus on being productive instead of busy.",
    "Your mind is for having ideas, not holding them.",
    "The way to get started is to quit talking and begin doing.",
    "Done is better than perfect.",
    "Small progress is still progress.",
  ];
  
  late String _currentQuote;
  int _visibleLetters = 0;
  bool _showQuote = false;
  late Timer _letterTimer;

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[Random().nextInt(_quotes.length)];
    
    // Start revealing letters one by one
    // We want the whole title to be visible within ~1.5 seconds to leave time for the quote
    int totalTitleDurationMs = 1500;
    int intervalMs = totalTitleDurationMs ~/ _title.length;

    _letterTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_visibleLetters < _title.length) {
        setState(() {
          _visibleLetters++;
        });
      } else {
        _letterTimer.cancel();
        setState(() {
          _showQuote = true;
        });
      }
    });

    // Navigate to next screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _letterTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated "TASKIFY" text
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_title.length, (index) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: index < _visibleLetters ? 1.0 : 0.0,
                  child: Text(
                    _title[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      fontFamily: 'Roboto',
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Animated Quote
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _showQuote ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _currentQuote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
