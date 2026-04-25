import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/dashboard_widgets.dart';
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
  bool _obscureText = true;
  bool _showAccountDetails = false;
  bool _showHowToUse = false;
  
  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final sessionBox = Hive.box('session');
    final usersBox = Hive.box<User>('users');
    final currentUserEmail = sessionBox.get('currentUserEmail');

    if (currentUserEmail != null) {
      currentUser = usersBox.values.cast<User?>().firstWhere(
        (u) => u?.email == currentUserEmail,
        orElse: () => User(name: "Unknown", email: "", password: ""),
      );
      
      if (currentUser != null) {
        nameController.text = currentUser!.name;
        emailController.text = currentUser!.email;
        passController.text = currentUser!.password;
      }
    }
    setState(() => isLoading = false);
  }

  void _updateProfile() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (nameController.text.isEmpty || emailController.text.isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are mandatory"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final usersBox = Hive.box<User>('users');
    final sessionBox = Hive.box('session');
    final oldEmail = currentUser?.email;

    if (emailController.text != oldEmail) {
      final exists = usersBox.values.any((u) => u.email == emailController.text);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email already in use by another account"), backgroundColor: Colors.orangeAccent),
        );
        return;
      }
    }

    if (currentUser != null) {
      final updatedUser = User(
        name: nameController.text,
        email: emailController.text,
        password: passController.text,
      );
      
      final index = usersBox.values.toList().indexWhere((u) => u.email == oldEmail);
      if (index != -1) {
        await usersBox.putAt(index, updatedUser);
        await sessionBox.put('currentUserEmail', updatedUser.email);
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Profile updated successfully!",
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => currentUser = updatedUser);
      }
    }
  }

  void _logout() async {
    await Hive.box('session').delete('currentUserEmail');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _eraseAllData() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              await Hive.box<Task>('tasks').clear();
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("All data erased successfully", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("ERASE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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

    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        CircularIconButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          "Profile",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor),
                        ),
                        const Spacer(),
                        const SizedBox(width: 50),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, size: 60, color: theme.hintColor),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        currentUser?.name ?? "User",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // APP SETTINGS SECTION
                    _buildSectionLabel("APP SETTINGS"),
                    const SizedBox(height: 12),
                    _buildThemeToggle(),
                    const SizedBox(height: 12),
                    _buildTimeFormatToggle(),
                    const SizedBox(height: 12),
                    _buildNotificationToggle(),
                    const SizedBox(height: 12),
                    _buildRoughNotesToggle(),
                    const SizedBox(height: 12),
                    _buildNotificationDelaySlider(),
                    
                    const SizedBox(height: 30),

                    // HOW TO USE SECTION
                    _buildCollapsibleHeader(
                      "HOW TO USE", 
                      _showHowToUse, 
                      () => setState(() => _showHowToUse = !_showHowToUse)
                    ),
                    if (_showHowToUse) ...[
                      const SizedBox(height: 12),
                      _buildHowToUse(),
                    ],

                    const SizedBox(height: 30),
                    
                    // ACCOUNT DETAILS SECTION
                    _buildCollapsibleHeader(
                      "ACCOUNT DETAILS", 
                      _showAccountDetails, 
                      () => setState(() => _showAccountDetails = !_showAccountDetails)
                    ),
                    if (_showAccountDetails) ...[
                      const SizedBox(height: 15),
                      _buildLabel("Full Name"),
                      TaskifyTextField(controller: nameController, hintText: "Name"),
                      const SizedBox(height: 25),
                      _buildLabel("Email Address"),
                      TaskifyTextField(controller: emailController, hintText: "Email", keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 25),
                      _buildLabel("Password"),
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
                        text: "Update Profile",
                        onPressed: _updateProfile,
                      ),
                    ],
                    
                    const SizedBox(height: 50),
                    _buildEraseDataTile(),
                    const SizedBox(height: 20),
                    TaskifyButton(
                      text: "Logout",
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      textColor: Colors.redAccent,
                      onPressed: _logout,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Box formatted Footer fixed at the bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 25, top: 10),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: theme.dividerColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Made with ",
                        style: TextStyle(color: theme.hintColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                      Text(
                        " by ",
                        style: TextStyle(color: theme.hintColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: _launchLinkedIn,
                        child: Text(
                          "manosekar_m",
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCollapsibleHeader(String title, bool isExpanded, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.grey,
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: theme.hintColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    final settingsBox = Hive.box('settings');
    final isDark = settingsBox.get('isDarkMode', defaultValue: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Theme.of(context).primaryColor),
              const SizedBox(width: 15),
              Text(
                "Dark Mode",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          Switch(
            value: isDark,
            activeThumbColor: Colors.blue,
            onChanged: (val) {
              settingsBox.put('isDarkMode', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFormatToggle() {
    final settingsBox = Hive.box('settings');
    final bool is24Hours = settingsBox.get('is24Hours', defaultValue: false);
    final bool is12Hour = !is24Hours;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_filled, color: Theme.of(context).primaryColor),
              const SizedBox(width: 15),
              Text(
                "12-Hour Format",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          Switch(
            value: is12Hour,
            activeThumbColor: Colors.blue,
            onChanged: (val) {
              settingsBox.put('is24Hours', !val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle() {
    final settingsBox = Hive.box('settings');
    final bool notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: Theme.of(context).primaryColor),
              const SizedBox(width: 15),
              Text(
                "Enable Notifications",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          Switch(
            value: notificationsEnabled,
            activeThumbColor: Colors.blue,
            onChanged: (val) {
              settingsBox.put('notificationsEnabled', val);
              setState(() {});
              if (!val) {
                NotificationService().cancelAllNotifications();
              } else {
                final tasks = Hive.box<Task>('tasks').values;
                for (var task in tasks) {
                  if (!task.isCompleted) {
                    NotificationService().scheduleTaskNotifications(task);
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDelaySlider() {
    final settingsBox = Hive.box('settings');
    final double currentDelay = settingsBox.get('notificationDelay', defaultValue: 30.0).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: Theme.of(context).primaryColor),
              const SizedBox(width: 15),
              Text(
                "Early Alert Delay",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                "${currentDelay.toInt()} mins",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: currentDelay,
            min: 5,
            max: 60,
            divisions: 11,
            activeColor: Colors.blue,
            inactiveColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            onChanged: (val) {
              setState(() {
                settingsBox.put('notificationDelay', val);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEraseDataTile() {
    return InkWell(
      onTap: _eraseAllData,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.redAccent),
            const SizedBox(width: 15),
            const Text(
              "Erase All Data",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.redAccent.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }

  Widget _buildRoughNotesToggle() {
    final settingsBox = Hive.box('settings');
    final bool showRoughNotes = settingsBox.get('showRoughNotes', defaultValue: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: Theme.of(context).primaryColor),
              const SizedBox(width: 15),
              Text(
                "Show Rough Notes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          Switch(
            value: showRoughNotes,
            activeThumbColor: Colors.blue,
            onChanged: (val) {
              settingsBox.put('showRoughNotes', val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUse() {
    final theme = Theme.of(context);
    final steps = [
      "Launch the app and log in or create a new account to keep your tasks synced.",
      "On the Home screen, tap the floating '+' button to create your first task.",
      "Set a clear title, start time, and duration for each activity in your schedule.",
      "Tap the orange 'Focus' button on any task card to start a dedicated focus timer.",
      "Enable 'Notifications' in settings to receive timely reminders before tasks start.",
      "Adjust 'Early Alert Delay' to choose exactly how many minutes before to be notified.",
      "Enable 'Show Rough Notes' to jot down quick ideas directly from your Home screen.",
      "Switch to 'Calendar' view to manage your schedule for any specific date.",
      "Swipe a task right to mark as completed, or swipe left to permanently delete it.",
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.hintColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
