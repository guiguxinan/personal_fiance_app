import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF5D9B9B);
  static const Color primaryLight = Color(0xFF8FCACA);
  static const Color primaryDark = Color(0xFF3D7B7B);

  // Background
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);

  // Category colors
  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B), // 餐饮 - 红色
    Color(0xFF4ECDC4), // 交通 - 青色
    Color(0xFFFFE66D), // 购物 - 黄色
    Color(0xFF95E1D3), // 娱乐 - 浅绿
    Color(0xFFF38181), // 居住 - 粉红
    Color(0xFFAA96DA), // 医疗 - 紫色
    Color(0xFF6C5CE7), // 教育 - 深紫
    Color(0xFFA8D8EA), // 其他 - 浅蓝
  ];

  // Semantic colors
  static const Color expense = Color(0xFFE74C3C);
  static const Color income = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
}
