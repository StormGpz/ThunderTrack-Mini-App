import 'package:flutter/material.dart';

/// EVA初号机主题配色方案
/// 基于新世纪福音战士初号机的经典配色设计
class EvaTheme {
  // 禁止实例化
  EvaTheme._();

  // === 核心颜色 ===
  
  /// 初号机主紫色 - 深邃的机体紫
  static const Color primaryPurple = Color(0xFF5E35B1);
  
  /// 初号机深紫色 - 更深的阴影紫
  static const Color darkPurple = Color(0xFF4A148C);
  
  /// 初号机荧光绿 - 科技感强烈的荧光绿
  static const Color neonGreen = Color(0xFF00E676);
  
  /// 强化荧光绿 - 更亮的警告绿
  static const Color brightGreen = Color(0xFF00FF41);
  
  /// 初号机黄色 - 警告和高亮色
  static const Color evaYellow = Color(0xFFFFD600);
  
  /// 警告黄色 - 与 evaYellow 相同，用于一致性
  static const Color warningYellow = Color(0xFFFFD600);
  
  /// 初号机橙色 - AT力场色
  static const Color atFieldOrange = Color(0xFFFF6D00);

  // === 中性色 ===
  
  /// 深空黑 - 背景主色
  static const Color deepBlack = Color(0xFF0A0A0A);
  
  /// 机甲灰 - 卡片背景
  static const Color mechGray = Color(0xFF1E1E1E);
  
  /// 边框灰 - 分割线和边框
  static const Color borderGray = Color(0xFF333333);
  
  /// 文本灰 - 次要文本
  static const Color textGray = Color(0xFF9E9E9E);
  
  /// 浅灰色 - 辅助文本
  static const Color lightGray = Color(0xFF9E9E9E);
  
  /// 浅文本色 - 主要文本（暗色主题）
  static const Color lightText = Color(0xFFE0E0E0);
  
  /// 纯白 - 主要文本
  static const Color pureWhite = Color(0xFFFFFFFF);

  // === 状态色 ===
  
  /// 成功绿 - 使用荧光绿变体
  static const Color successGreen = neonGreen;
  
  /// 错误红 - 紧急状态红
  static const Color errorRed = Color(0xFFE53935);
  
  /// 警告橙 - 使用AT力场橙
  static const Color warningOrange = atFieldOrange;
  
  /// 信息蓝 - 柔和的信息蓝
  static const Color infoBlue = Color(0xFF1E88E5);

  // === 渐变色 ===
  
  /// 主紫色渐变
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, darkPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 荧光绿渐变
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonGreen, brightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 科技感渐变
  static const LinearGradient techGradient = LinearGradient(
    colors: [primaryPurple, neonGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === 主题数据 ===
  
  /// 亮色主题（初号机日间模式）
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: _createMaterialColor(primaryPurple),
    primaryColor: primaryPurple,
    colorScheme: ColorScheme.light(
      primary: primaryPurple,
      secondary: neonGreen,
      tertiary: evaYellow,
      surface: pureWhite,
      background: Color(0xFFF5F5F5),
      error: errorRed,
      onPrimary: pureWhite,
      onSecondary: deepBlack,
      onSurface: deepBlack,
      onBackground: deepBlack,
      onError: pureWhite,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryPurple,
      foregroundColor: pureWhite,
      elevation: 4,
      centerTitle: true,
      iconTheme: IconThemeData(color: pureWhite),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: pureWhite,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: pureWhite,
      elevation: 4,
      shadowColor: primaryPurple,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: pureWhite,
        elevation: 4,
        shadowColor: primaryPurple,
      ),
    ),
  );

  /// 暗色主题（初号机夜间模式）
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: _createMaterialColor(primaryPurple),
    primaryColor: primaryPurple,
    colorScheme: ColorScheme.dark(
      primary: primaryPurple,
      secondary: neonGreen,
      tertiary: evaYellow,
      surface: mechGray,
      background: deepBlack,
      error: errorRed,
      onPrimary: pureWhite,
      onSecondary: deepBlack,
      onSurface: pureWhite,
      onBackground: pureWhite,
      onError: pureWhite,
    ),
    scaffoldBackgroundColor: deepBlack,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryPurple,
      foregroundColor: pureWhite,
      elevation: 4,
      centerTitle: true,
      iconTheme: IconThemeData(color: pureWhite),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: pureWhite,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: mechGray,
      elevation: 4,
      shadowColor: neonGreen,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: pureWhite,
        elevation: 4,
        shadowColor: neonGreen,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: mechGray,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: neonGreen, width: 2),
      ),
    ),
  );

  /// 创建MaterialColor
  static MaterialColor _createMaterialColor(Color color) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.value, shades);
  }

  // === 特殊效果组件 ===
  
  /// 荧光绿发光效果
  static BoxDecoration neonGlowDecoration = BoxDecoration(
    color: neonGreen,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: neonGreen.withOpacity(0.5),
        blurRadius: 20,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: neonGreen.withOpacity(0.3),
        blurRadius: 40,
        spreadRadius: 4,
      ),
    ],
  );
  
  /// 紫色发光效果
  static BoxDecoration primaryGlowDecoration = BoxDecoration(
    color: primaryPurple,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: primaryPurple.withOpacity(0.5),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  /// 科技感边框
  static BoxDecoration techBorderDecoration = BoxDecoration(
    border: Border.all(color: neonGreen, width: 1),
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: neonGreen.withOpacity(0.2),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
  );

  // === 文本样式 ===
  
  /// 标题文本样式
  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: pureWhite,
    letterSpacing: 1.5,
  );
  
  /// 荧光绿强调文本
  static const TextStyle neonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: neonGreen,
    letterSpacing: 1.2,
  );
  
  /// 科技感数字文本
  static const TextStyle techNumberStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: neonGreen,
    fontFamily: 'monospace',
    letterSpacing: 2.0,
  );
}