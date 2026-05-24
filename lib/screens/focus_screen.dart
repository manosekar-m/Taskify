import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/task.dart';
import '../services/hive_service.dart';

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  Timer? _beepTimer;
  bool _isRunning = false;
  late AnimationController _pulseController;
  late AnimationController _bgController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _bgColorAnimation;

  // Pomodoro Cycles
  int _currentCycle = 1;
  bool _isBreak = false;
  final int _workDuration = 25 * 60;
  final int _shortBreakDuration = 5 * 60;
  final int _longBreakDuration = 15 * 60;

  // Audio Players
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedSound;

  // ── High-reliability ambient sounds ──
  final List<Map<String, dynamic>> _focusSounds = [
    {
      'name': 'Rain',
      'icon': '🌧️',
      'url': 'https://assets.mixkit.co/sfx/preview/mixkit-rain-on-metal-roof-495.mp3',
    },
    {
      'name': 'Forest',
      'icon': '🌲',
      'url': 'https://assets.mixkit.co/sfx/preview/mixkit-forest-birds-ambience-1210.mp3',
    },
    {
      'name': 'Ocean',
      'icon': '🌊',
      'url': 'https://assets.mixkit.co/sfx/preview/mixkit-ocean-waves-1176.mp3',
    },
    {
      'name': 'Cafe',
      'icon': '☕',
      'url': 'https://assets.mixkit.co/sfx/preview/mixkit-coffee-shop-ambience-447.mp3',
    },
    {
      'name': 'White',
      'icon': '🔊',
      'url': 'https://assets.mixkit.co/sfx/preview/mixkit-town-square-ambience-2523.mp3',
    },
  ];

  @override
  void initState() {
    super.initState();
    _totalSeconds = _parseDurationToSeconds(widget.task.duration);
    _remainingSeconds = _totalSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _bgColorAnimation = ColorTween(
      begin: const Color(0xFF0D0D0D),
      end: const Color(0xFF1A1A1A),
    ).animate(_bgController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _beepTimer?.cancel();
    FlutterRingtonePlayer().stop();
    _pulseController.dispose();
    _bgController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
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
    if (hours == 0 && minutes == 0) minutes = 25;
    return (hours * 3600) + (minutes * 60);
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _stopTimer();
        _handleCycleCompletion();
        _showCompletionDialog();
      }
    });
  }

  void _handleCycleCompletion() {
    if (_isBreak) {
      setState(() {
        _isBreak = false;
        _totalSeconds = _workDuration;
        _remainingSeconds = _totalSeconds;
        _currentCycle++;
      });
      _showCycleDialog("☀️ Break Over!", "Ready to focus again?");
    } else {
      setState(() {
        _isBreak = true;
        _totalSeconds = (_currentCycle % 4 == 0) ? _longBreakDuration : _shortBreakDuration;
        _remainingSeconds = _totalSeconds;
      });
      _showCycleDialog("🎉 Work Session Complete!", "Take a well-deserved break.");
    }
  }

  void _showCycleDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text("Start Next Session", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleSound(String? url) async {
    HapticFeedback.lightImpact();
    try {
      if (url == null || url == _selectedSound) {
        await _audioPlayer.stop();
        setState(() => _selectedSound = null);
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(UrlSource(url));
        setState(() => _selectedSound = url);
      }
    } catch (_) {
      setState(() => _selectedSound = null);
    }
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }

  void _stopTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _remainingSeconds = _totalSeconds);
  }

  void _showCompletionDialog() {
    FlutterRingtonePlayer().playAlarm();
    _beepTimer = Timer(const Duration(seconds: 5), () {
      FlutterRingtonePlayer().stop();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Center(
          child: Column(children: [
            Text("🎉", style: TextStyle(fontSize: 50)),
            SizedBox(height: 12),
            Text(
              "Focus Complete!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ]),
        ),
        content: Text(
          "Great work on '${widget.task.title}'!\nMark it as done?",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              _beepTimer?.cancel();
              FlutterRingtonePlayer().stop();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Not Yet", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: () async {
              _beepTimer?.cancel();
              FlutterRingtonePlayer().stop();
              widget.task.isCompleted = true;
              await HiveService().updateTask(widget.task);
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
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

  double get _progress => _remainingSeconds / _totalSeconds;

  Color get _accentColor => _isBreak ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgColorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _bgColorAnimation.value ?? const Color(0xFF1A1A2E),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildTaskTitle(),
                        const SizedBox(height: 12),
                        _buildSessionBadge(),
                        const SizedBox(height: 40),
                        _buildTimer(),
                        const SizedBox(height: 44),
                        _buildControls(),
                        const SizedBox(height: 36),
                        _buildSoundSection(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            "FOCUS MODE",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTaskTitle() {
    return Text(
      widget.task.title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
    );
  }

  Widget _buildSessionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        _isBreak ? "🍃  BREAK  •  RECHARGE" : "⚡  CYCLE $_currentCycle  •  ${widget.task.duration.toUpperCase()}",
        style: TextStyle(
          color: _accentColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return ScaleTransition(
      scale: _isRunning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: SizedBox(
        width: 270,
        height: 270,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: _isRunning ? 0.25 : 0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Background track
            SizedBox(
              width: 240,
              height: 240,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 10,
                color: Colors.white.withValues(alpha: 0.07),
                strokeCap: StrokeCap.round,
              ),
            ),
            // Progress arc
            SizedBox(
              width: 240,
              height: 240,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 10,
                color: _accentColor,
                backgroundColor: Colors.transparent,
                strokeCap: StrokeCap.round,
              ),
            ),
            // Inner glass card
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.02),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFlipClock(),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isRunning ? "FOCUSING" : (_remainingSeconds == _totalSeconds ? "READY" : "PAUSED"),
                      key: ValueKey(_isRunning),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: _isRunning ? Colors.white : Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlBtn(
          icon: Icons.refresh_rounded,
          color: Colors.white60,
          size: 56,
          iconSize: 26,
          onTap: () {
            HapticFeedback.lightImpact();
            _resetTimer();
          },
        ),
        const SizedBox(width: 30),
        // Main play/pause button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _isRunning ? _pauseTimer() : _startTimer();
          },
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 42,
            ),
          ),
        ),
        const SizedBox(width: 30),
        _controlBtn(
          icon: Icons.stop_rounded,
          color: Colors.white,
          size: 56,
          iconSize: 26,
          onTap: () {
            HapticFeedback.lightImpact();
            _stopTimer();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  Widget _buildSoundSection() {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Text(
              "AMBIENT SOUNDS",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _soundTile(null, '🔇', 'Off', _selectedSound == null),
            ..._focusSounds.map((s) => _soundTile(s['url'], s['icon'], s['name'], _selectedSound == s['url'])),
          ],
        ),
      ],
    );
  }

  Widget _soundTile(String? url, String emoji, String label, bool isActive) {
    return GestureDetector(
      onTap: () => _toggleSound(url),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _accentColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? _accentColor : Colors.white.withValues(alpha: 0.08),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isActive ? _accentColor : Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipClock() {
    String time = _formattedTime;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: time.split('').map((char) {
        if (char == ':') {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ":",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          );
        }
        return _FlipCard(digit: char);
      }).toList(),
    );
  }
}

class _FlipCard extends StatelessWidget {
  final String digit;
  const _FlipCard({required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 26,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Middle crease
          Center(
            child: Container(
              height: 1,
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final rotate = Tween(begin: 1.57, end: 0.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return AnimatedBuilder(
                animation: rotate,
                builder: (context, _) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(rotate.value),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
              );
            },
            child: Text(
              digit,
              key: ValueKey(digit),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
