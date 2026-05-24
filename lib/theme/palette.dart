import 'package:flutter/material.dart';

class Palette {
  // ── Brand Colors ──────────────────────────────────────────────────────────
  // Primary: Premium Indigo (like Linear/Notion)
  static const Color primary     = Color(0xFF5B5BD6); // Light mode primary
  static const Color primaryDark = Color(0xFF818CF8); // Dark mode primary (lighter, readable)

  // Secondary: Soft Violet
  static const Color secondary     = Color(0xFF7C3AED);
  static const Color secondaryDark = Color(0xFFA78BFA);

  // Highlight: Electric Cyan spark
  static const Color highlight = Color(0xFF06B6D4);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  // Slightly violet-tinted white for light — feels alive, not sterile
  static const Color backgroundLight = Color(0xFFF5F4FF);
  // Deep midnight navy for dark — rich, not just black
  static const Color backgroundDark  = Color(0xFF0B0B18);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark  = Color(0xFF13132A); // Elevated surface
  static const Color cardDark     = Color(0xFF1A1A35); // Card on dark surface

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color hintLight = Color(0xFF64648C); // Muted slate-violet
  static const Color hintDark  = Color(0xFF8B8BAE);

  // ── Borders / Dividers ───────────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFE8E8F4); // Faint violet tint
  static const Color dividerDark  = Color(0xFF252545);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark  = Color(0xFFF87171);
  static const Color success    = Color(0xFF10B981);

  // ── Hero Gradient (always used on dark "hero" cards) ─────────────────────
  // Deep Indigo → Violet — premium, on-brand
  static const Color heroGradientStart = Color(0xFF4338CA); // Indigo 700
  static const Color heroGradientEnd   = Color(0xFF7C3AED); // Violet 600
}
