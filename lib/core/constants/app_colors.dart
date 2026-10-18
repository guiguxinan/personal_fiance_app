import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary colors (V2.1: 粉色系，按原型「轻记 V2」)
  static const Color primary = Color(0xFFE88BA3);
  static const Color primaryLight = Color(0xFFFBE4EC);
  static const Color primaryLighter = Color(0xFFFDF0F4);
  static const Color primaryDark = Color(0xFFC96B85);
  static const Color primaryDeep = Color(0xFFB85A75);

  // Background / surface（按原型 --bg / --card）
  static const Color background = Color(0xFFFAF5F7);
  static const Color surface = Colors.white;
  static const Color line = Color(0xFFF0E3E8);

  // Text（按原型 --ink / --ink-2 / --ink-3）
  static const Color textPrimary = Color(0xFF2E2429);
  static const Color textSecondary = Color(0xFF6B5A61);
  static const Color textHint = Color(0xFFA89AA0);

  // Category colors（按原型：支出 8 色 + 收入 5 色）
  static const List<Color> categoryColors = [
    Color(0xFFE88BA3), // 餐饮
    Color(0xFFE8C4A0), // 交通
    Color(0xFFF2B8C8), // 购物
    Color(0xFFD47B95), // 娱乐
    Color(0xFFF7D4DE), // 居住
    Color(0xFFC96B85), // 医疗
    Color(0xFFB85A75), // 教育
    Color(0xFFA89AA0), // 支出·其他
    Color(0xFF5BB892), // 工资
    Color(0xFF7FD0AE), // 奖金
    Color(0xFF3D9472), // 理财
    Color(0xFFA8DCC2), // 兼职
    Color(0xFFE8C4A0), // 收入·其他
  ];

  // Semantic colors（按原型：支出为深色主文字，收入为绿色系）
  static const Color expense = Color(0xFFC96B85);
  static const Color income = Color(0xFF5BB892);
  static const Color incomeLight = Color(0xFFE0F3EA);
  static const Color warning = Color(0xFFF39C12);

  // V3.3 (B2)：统计页「一句话洞察」卡（按原型 V3.1 insight-card：#FFF6E0→#FBF1D9 渐变、文字 #8A6D2B）
  static const Color insightBgStart = Color(0xFFFFF6E0);
  static const Color insightBgEnd = Color(0xFFFBF1D9);
  static const Color insightText = Color(0xFF8A6D2B);

  // Gradient colors（按原型 135deg 三段渐变）
  static const Color expenseGradientStart = Color(0xFFF2A8BC);
  static const Color expenseGradientMid = Color(0xFFE88BA3);
  static const Color expenseGradientEnd = Color(0xFFD47B95);
  static const Color incomeGradientStart = Color(0xFF8FD4B5);
  static const Color incomeGradientMid = Color(0xFF5BB892);
  static const Color incomeGradientEnd = Color(0xFF3D9472);
}
