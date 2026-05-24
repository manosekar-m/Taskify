import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user.dart';
import '../services/hive_service.dart';
import '../widgets/custom_widgets.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  
  User? _currentUser;
  bool isLoading = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await HiveService().currentUser;
    if (user != null) {
      nameController.text = user.name;
      emailController.text = user.email;
      passController.text = user.password;
    }
    setState(() {
      _currentUser = user;
      isLoading = false;
    });
  }

  void _logout() async {
    await HiveService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _updateProfile() async {
    if (_currentUser == null) return;
    
    final updatedUser = User(
      id: _currentUser!.id,
      name: nameController.text,
      email: emailController.text,
      password: passController.text,
    );
    
    await Hive.box<User>(HiveService.userBoxName).put(updatedUser.id, updatedUser);
    
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile updated successfully!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadUserData();
  }

  void _eraseAllData() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("Erase All Data?", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
        content: Text(
          "This will permanently delete all your tasks and schedule. This action cannot be undone.",
          style: TextStyle(color: theme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              NotificationService().cancelAllNotifications();
              await HiveService().deleteAllTasks();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All data erased successfully", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.black,
                  duration: Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("ERASE", style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchLinkedIn() async {
    final Uri url = Uri.parse('https://www.linkedin.com/in/manosekar-m/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch LinkedIn profile")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: theme.cardColor,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, size: 18, color: theme.primaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(theme, isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection("Visuals", [
                    _buildThemeToggle(),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection("Preferences", [
                    _buildTimeFormatToggle(),
                    const Divider(height: 1, indent: 60),
                    _buildNotificationToggle(),
                    const Divider(height: 1, indent: 60),
                    _buildRoughNotesToggle(),
                    const SizedBox(height: 15),
                    _buildNotificationDelaySlider(),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection("Security", [
                    _buildBiometricToggle(),
                  ]),
                  const SizedBox(height: 20),
                  _buildExpandableSection("Account Details", Icons.person_outline, [
                    const SizedBox(height: 15),
                    _buildTextFieldLabel("Display Name"),
                    TaskifyTextField(controller: nameController, hintText: "Name"),
                    const SizedBox(height: 15),
                    _buildTextFieldLabel("Email Address"),
                    TaskifyTextField(controller: emailController, hintText: "Email", keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 15),
                    _buildTextFieldLabel("Password"),
                    StatefulBuilder(
                      builder: (context, setFieldState) {
                        return TaskifyTextField(
                          controller: passController,
                          hintText: "Password",
                          isPasswordField: true,
                          obscureText: _obscurePassword,
                          onSuffixTap: () => setFieldState(() => _obscurePassword = !_obscurePassword),
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    TaskifyButton(
                      text: "Update Profile",
                      onPressed: _updateProfile,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildExpandableSection("How to Use", Icons.help_outline, [
                    const SizedBox(height: 10),
                    _buildHowToUse(),
                  ]),
                  const SizedBox(height: 40),
                  _buildSection("Danger Zone", [
                    _buildEraseDataTile(),
                  ]),
                  const SizedBox(height: 20),
                  _buildLogoutButton(),
                  const SizedBox(height: 60),
                  _buildFooter(theme),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? theme.primaryColor.withValues(alpha: 0.15) : theme.primaryColor.withValues(alpha: 0.05),
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Hero(
            tag: 'profile_pic',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1), width: 2),
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: theme.cardColor,
                child: Icon(Icons.person, size: 45, color: theme.primaryColor.withValues(alpha: 0.8)),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _currentUser?.name ?? "User Name",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor),
          ),
          Text(
            _currentUser?.email ?? "email@example.com",
            style: TextStyle(fontSize: 14, color: theme.hintColor, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.grey,
            ),
          ),
        ),
        GlassContainer(
          borderRadius: 20,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(String title, IconData icon, List<Widget> children) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: GlassContainer(
        borderRadius: 20,
        child: ExpansionTile(
          leading: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: children,
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    final theme = Theme.of(context);
    final settingsBox = Hive.box('settings');
    final isDark = settingsBox.get('isDarkMode', defaultValue: false);

    return ListTile(
      leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: theme.primaryColor),
      title: Text("Dark Mode", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: isDark,
        activeTrackColor: theme.primaryColor,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          settingsBox.put('isDarkMode', val);
        },
      ),
    );
  }

  Widget _buildTimeFormatToggle() {
    final theme = Theme.of(context);
    final settingsBox = Hive.box('settings');
    final bool is24Hours = settingsBox.get('is24Hours', defaultValue: false);

    return ListTile(
      leading: Icon(Icons.access_time_filled, color: theme.primaryColor),
      title: Text("12-Hour Format", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: !is24Hours,
        activeTrackColor: theme.primaryColor,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          settingsBox.put('is24Hours', !val);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildNotificationToggle() {
    final theme = Theme.of(context);
    final settingsBox = Hive.box('settings');
    final bool notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);

    return ListTile(
      leading: Icon(Icons.notifications_active, color: theme.primaryColor),
      title: Text("Notifications", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: notificationsEnabled,
        activeTrackColor: theme.primaryColor,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          settingsBox.put('notificationsEnabled', val);
          setState(() {});
          if (!val) {
            NotificationService().cancelAllNotifications();
          } else {
            HiveService().getTasks(DateTime.now()).then((tasks) {
              for (var task in tasks) {
                if (!task.isCompleted) {
                  NotificationService().scheduleTaskNotifications(task);
                }
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildRoughNotesToggle() {
    final theme = Theme.of(context);
    final settingsBox = Hive.box('settings');
    final bool showRoughNotes = settingsBox.get('showRoughNotes', defaultValue: false);

    return ListTile(
      leading: Icon(Icons.notes_rounded, color: theme.primaryColor),
      title: Text("Show Rough Notes", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: showRoughNotes,
        activeTrackColor: theme.primaryColor,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          settingsBox.put('showRoughNotes', val);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildNotificationDelaySlider() {
    final theme = Theme.of(context);
    final settingsBox = Hive.box('settings');
    final double currentDelay = settingsBox.get('notificationDelay', defaultValue: 30.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Early Alert Delay",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.primaryColor),
              ),
              Text(
                "${currentDelay.toInt()} mins",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.primaryColor,
              inactiveTrackColor: theme.primaryColor.withValues(alpha: 0.1),
              thumbColor: theme.primaryColor,
              overlayColor: theme.primaryColor.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: currentDelay,
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (val) {
                setState(() {
                  settingsBox.put('notificationDelay', val);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricToggle() {
    final theme = Theme.of(context);
    final settingsBox = Hive.box('settings');
    final bool isBiometricEnabled = settingsBox.get('isBiometricEnabled', defaultValue: false);
    final LocalAuthentication auth = LocalAuthentication();

    return ListTile(
      leading: Icon(Icons.fingerprint, color: theme.primaryColor),
      title: Text("Biometric Lock", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: isBiometricEnabled,
        activeTrackColor: theme.primaryColor,
        onChanged: (val) async {
          if (val) {
            final bool canCheckBiometrics = await auth.canCheckBiometrics;
            final bool isDeviceSupported = await auth.isDeviceSupported();
            
            if (canCheckBiometrics && isDeviceSupported) {
              try {
                final bool didAuthenticate = await auth.authenticate(
                  localizedReason: 'Please authenticate to enable Biometric Lock',
                );
                if (didAuthenticate) {
                  settingsBox.put('isBiometricEnabled', true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Biometric Lock enabled!"),
                        backgroundColor: theme.primaryColor,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Authentication error: $e")),
                  );
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Biometrics not available or supported on this device")),
                );
              }
            }
          } else {
            settingsBox.put('isBiometricEnabled', false);
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    final theme = Theme.of(context);
    return TaskifyButton(
      text: "Log Out",
      color: theme.primaryColor.withValues(alpha: 0.1),
      textColor: theme.primaryColor,
      onPressed: _logout,
    );
  }

  Widget _buildEraseDataTile() {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.delete_forever_rounded, color: theme.primaryColor),
      title: Text("Erase All Data", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: theme.primaryColor, size: 20),
      onTap: _eraseAllData,
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).hintColor),
      ),
    );
  }

  Widget _buildHowToUse() {
    final theme = Theme.of(context);
    final steps = [
      "Tap '+' to create your first task.",
      "Set title, start time, and duration.",
      "Tap 'Focus' for a dedicated timer.",
      "Enable notifications for timely alerts.",
      "Swipe right to complete, left to delete.",
    ];

    return Column(
      children: steps.map((step) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                step,
                style: TextStyle(fontSize: 14, color: theme.hintColor, height: 1.4),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Made with ", style: TextStyle(color: theme.hintColor, fontSize: 12)),
            Icon(Icons.favorite, color: theme.primaryColor, size: 14),
            Text(" by ", style: TextStyle(color: theme.hintColor, fontSize: 12)),
            GestureDetector(
              onTap: _launchLinkedIn,
              child: Text(
                "manosekar_m",
                style: TextStyle(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
