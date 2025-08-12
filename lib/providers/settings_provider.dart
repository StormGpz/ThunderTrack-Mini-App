import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置Provider
class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  factory SettingsProvider() => _instance;
  SettingsProvider._internal();

  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';
  static const String _defaultDiaryVisibilityKey = 'default_diary_visibility';
  static const String _autoShareEnabledKey = 'auto_share_enabled';

  SharedPreferences? _prefs;
  
  // 设置状态
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('zh', 'CN');
  bool _defaultDiaryIsPublic = true;
  bool _autoShareEnabled = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get defaultDiaryIsPublic => _defaultDiaryIsPublic;
  bool get autoShareEnabled => _autoShareEnabled;
  
  /// 当前是否为深色模式
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// 当前是否为中文
  bool get isChineseLocale => _locale.languageCode == 'zh';

  /// 初始化设置
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    // 加载主题模式
    final themeModeIndex = _prefs!.getInt(_themeModeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex];

    // 加载语言设置
    final localeString = _prefs!.getString(_localeKey) ?? 'zh_CN';
    final localeParts = localeString.split('_');
    if (localeParts.length >= 2) {
      _locale = Locale(localeParts[0], localeParts[1]);
    } else {
      _locale = Locale(localeParts[0]);
    }

    // 加载日记可见性设置
    _defaultDiaryIsPublic = _prefs!.getBool(_defaultDiaryVisibilityKey) ?? true;

    // 加载自动分享设置
    _autoShareEnabled = _prefs!.getBool(_autoShareEnabledKey) ?? false;

    notifyListeners();
  }

  /// 切换主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _prefs?.setInt(_themeModeKey, mode.index);
      notifyListeners();
    }
  }

  /// 切换明暗模式
  Future<void> toggleThemeMode() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// 设置语言
  Future<void> setLocale(Locale locale) async {
    if (_locale != locale) {
      _locale = locale;
      final localeString = locale.countryCode != null 
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      await _prefs?.setString(_localeKey, localeString);
      notifyListeners();
    }
  }

  /// 切换语言（中英文）
  Future<void> toggleLanguage() async {
    final newLocale = _locale.languageCode == 'zh' 
        ? const Locale('en', 'US') 
        : const Locale('zh', 'CN');
    await setLocale(newLocale);
  }

  /// 设置默认日记可见性
  Future<void> setDefaultDiaryVisibility(bool isPublic) async {
    if (_defaultDiaryIsPublic != isPublic) {
      _defaultDiaryIsPublic = isPublic;
      await _prefs?.setBool(_defaultDiaryVisibilityKey, isPublic);
      notifyListeners();
    }
  }

  /// 切换默认日记可见性
  Future<void> toggleDefaultDiaryVisibility() async {
    await setDefaultDiaryVisibility(!_defaultDiaryIsPublic);
  }

  /// 设置自动分享功能
  Future<void> setAutoShareEnabled(bool enabled) async {
    if (_autoShareEnabled != enabled) {
      _autoShareEnabled = enabled;
      await _prefs?.setBool(_autoShareEnabledKey, enabled);
      notifyListeners();
    }
  }

  /// 切换自动分享功能
  Future<void> toggleAutoShare() async {
    await setAutoShareEnabled(!_autoShareEnabled);
  }

  /// 重置所有设置
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _locale = const Locale('zh', 'CN');
    _defaultDiaryIsPublic = true;
    _autoShareEnabled = false;

    await _prefs?.remove(_themeModeKey);
    await _prefs?.remove(_localeKey);
    await _prefs?.remove(_defaultDiaryVisibilityKey);
    await _prefs?.remove(_autoShareEnabledKey);

    notifyListeners();
  }

  /// 获取主题模式显示文本
  String getThemeModeDisplayText() {
    switch (_themeMode) {
      case ThemeMode.light:
        return isChineseLocale ? '浅色模式' : 'Light Mode';
      case ThemeMode.dark:
        return isChineseLocale ? '深色模式' : 'Dark Mode';
      case ThemeMode.system:
        return isChineseLocale ? '跟随系统' : 'System';
    }
  }

  /// 获取语言显示文本
  String getLanguageDisplayText() {
    return isChineseLocale ? '中文' : 'English';
  }

  /// 获取默认日记可见性显示文本
  String getDefaultVisibilityDisplayText() {
    if (isChineseLocale) {
      return _defaultDiaryIsPublic ? '公开' : '私有';
    } else {
      return _defaultDiaryIsPublic ? 'Public' : 'Private';
    }
  }
}