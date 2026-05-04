// lib/utils/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF2563EB);       // Azul vibrante
  static const primaryDark = Color(0xFF1E3A8A);   // Azul escuro
  static const primaryLight = Color(0xFF3B82F6);  // Azul claro
  static const income = Color(0xFF10B981);         // Verde receitas
  static const expense = Color(0xFFEF4444);        // Vermelho despesas
  static const background = Color(0xFFF8FAFC);     // Cinza muito claro

  // Chart colors
  static const chartColor1 = Color(0xFF6366F1);
  static const chartColor2 = Color(0xFFF59E0B);
  static const chartColor3 = Color(0xFF10B981);
  static const chartColor4 = Color(0xFFEF4444);
  static const chartColor5 = Color(0xFF8B5CF6);
  static const chartColor6 = Color(0xFF06B6D4);

  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        cardColor: Colors.white,
        fontFamily: 'Roboto',
      );

  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
