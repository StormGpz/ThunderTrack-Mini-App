import 'package:flutter/material.dart';

/// 应用常量定义
class AppConstants {
  // 颜色常量
  static const Color primaryColor = Colors.indigo;
  static const Color secondaryColor = Colors.orange;
  static const Color backgroundColor = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF2A2A2A);
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  
  // 文字大小
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 12.0;
  
  // 边距和间距
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  
  // 动画时长
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // 交易相关常量
  static const List<String> supportedAssets = ['ETH', 'BTC', 'SOL', 'ARB'];
  static const List<String> tradeSides = ['buy', 'sell'];
  static const List<String> orderTypes = ['market', 'limit'];
  
  // 日记相关常量
  static const int maxDiaryTitleLength = 100;
  static const int maxDiaryContentLength = 2000;
  static const List<String> diaryCategories = [
    '技术分析',
    '基本面分析', 
    '交易心得',
    '风险管理',
    '市场观察'
  ];
  
  // 存储键名
  static const String userTokenKey = 'user_token';
  static const String userProfileKey = 'user_profile';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
}