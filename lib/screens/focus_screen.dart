import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../models/task.dart';

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  Timer? _beepTimer;
  bool _isRunning = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _parseDurationToSeconds(widget.task.duration);
    _remainingSeconds = _totalSeconds;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _beepTimer?.cancel();
    FlutterRingtonePlayer().stop();
    _animationController.dispose();
    super.dispose();
  }

  int _parseDurationToSeconds(String durationStr) {
    int hours = 0;
    int minutes = 0;
    
    String d = durationStr.toLowerCase();
    
    if (d.contains('hr')) {
      final hrParts = d.split('hr');
      hours = int.tryParse(hrParts[0].trim()) ?? 0;
      
      if (hrParts.length > 1 && hrParts[1].contains('min')) {
        final minParts = hrParts[1].split('min');
        minutes = int.tryParse(minParts[0].trim()) ?? 0;
      }
    } else if (d.contains('min')) {
      final minParts = d.split('min');
      minutes = int.tryParse(minParts[0].trim()) ?? 0;
    }
    
    if (hours == 0 && minutes == 0) {
      minutes = 25; // Default Pomodoro
    }
    
    return (hours * 3600) + (minutes * 60);
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _animationController.reverse(from: _remainingSeconds / _totalSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer();
        _showCompletionDialog();
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
    _animationController.stop();
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
    _animationController.stop();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = _totalSeconds;
    });
    _animationController.value = 1.0;
  }

  void _showCompletionDialog() {
    final theme = Theme.of(context);
    
    // Play a beep sound for 5 seconds
    FlutterRingtonePlayer().playAlarm();
    _beepTimer = Timer(const Duration(seconds: 5), () {
      FlutterRingtonePlayer().stop();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.orange, size: 50),
              const SizedBox(height: 15),
              Text(
                "Focus Session Complete!",
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        content: Text(
          "Great job focusing on '${widget.task.title}'. Would you like to mark this task as completed?",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.hintColor,
            fontSize: 16,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              _beepTimer?.cancel();
              FlutterRingtonePlayer().stop();
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close screen
            },
            child: Text(
              "Not Yet",
              style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              _beepTimer?.cancel();
              FlutterRingtonePlayer().stop();
              widget.task.isCompleted = true;
              widget.task.save();
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close screen
            },
            child: const Text("Mark as Done", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    int h = _remainingSeconds ~/ 3600;
    int m = (_remainingSeconds % 3600) ~/ 60;
    int s = _remainingSeconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Focus Mode",
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.task.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: theme.hintColor),
                    const SizedBox(width: 8),
                    Text(
                      widget.task.duration,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: CircularProgressIndicator(
                      value: _remainingSeconds / _totalSeconds,
                      strokeWidth: 12,
                      backgroundColor: theme.dividerColor,
                      color: _isRunning ? Colors.orange : theme.primaryColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        _isRunning ? "FOCUSING" : "PAUSED",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: _isRunning ? Colors.orange : theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlBtn(
                    icon: Icons.refresh_rounded,
                    color: theme.hintColor,
                    onTap: _resetTimer,
                    isSmall: true,
                  ),
                  const SizedBox(width: 30),
                  _buildControlBtn(
                    icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isRunning ? Colors.orange : theme.primaryColor,
                    onTap: _isRunning ? _pauseTimer : _startTimer,
                    isSmall: false,
                  ),
                  const SizedBox(width: 30),
                  _buildControlBtn(
                    icon: Icons.stop_rounded,
                    color: Colors.redAccent,
                    onTap: () {
                      _stopTimer();
                      Navigator.pop(context);
                    },
                    isSmall: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBtn({required IconData icon, required Color color, required VoidCallback onTap, required bool isSmall}) {
    final theme = Theme.of(context);
    final size = isSmall ? 60.0 : 80.0;
    final iconSize = isSmall ? 30.0 : 45.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
