import 'dart:ui';
import 'package:flutter/material.dart';

class TaskifyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool isPasswordField;
  final VoidCallback? onSuffixTap;

  const TaskifyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.isPasswordField = false,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textAlignVertical: TextAlignVertical.center, // Center text vertically
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.primaryColor,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: false, // Ensure consistent height
            contentPadding: const EdgeInsets.symmetric(vertical: 15), // Consistent padding
            hintText: hintText,
            suffixIcon: isPasswordField
                ? IconButton(
                    padding: EdgeInsets.zero, // Remove internal padding
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: theme.hintColor,
                      size: 20,
                    ),
                    onPressed: onSuffixTap,
                  )
                : null,
            hintStyle: TextStyle(
              color: theme.hintColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class TaskifyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;

  const TaskifyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.primaryColor,
          foregroundColor: textColor ?? (isDark ? Colors.black : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.5,
    this.borderRadius = 25,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.05 : 0.03),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.1 : 0.05),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
