import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Text(settings.isChineseLocale ? '设置' : 'Settings');
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 外观设置
                _buildSectionHeader(
                  context,
                  settings.isChineseLocale ? '外观' : 'Appearance',
                  Icons.palette_outlined,
                ),
                const SizedBox(height: 8),
                _buildSettingsCard([
                  _buildThemeSetting(context, settings),
                  _buildLanguageSetting(context, settings),
                ]),

                const SizedBox(height: 24),

                // 日记设置
                _buildSectionHeader(
                  context,
                  settings.isChineseLocale ? '日记设置' : 'Diary Settings',
                  Icons.book_outlined,
                ),
                const SizedBox(height: 8),
                _buildSettingsCard([
                  _buildDefaultVisibilitySetting(context, settings),
                  _buildAutoShareSetting(context, settings),
                ]),

                const SizedBox(height: 32),

                // 重置设置按钮
                _buildResetButton(context, settings),

                const SizedBox(height: 16),

                // 版本信息
                _buildVersionInfo(context, settings),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建节标题
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  /// 构建设置卡片
  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: children,
      ),
    );
  }

  /// 构建主题设置
  Widget _buildThemeSetting(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: Icon(
        settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        settings.isChineseLocale ? '主题模式' : 'Theme Mode',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(settings.getThemeModeDisplayText()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeModeDialog(context, settings),
    );
  }

  /// 构建语言设置
  Widget _buildLanguageSetting(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        settings.isChineseLocale ? '语言' : 'Language',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(settings.getLanguageDisplayText()),
      trailing: Switch(
        value: settings.isChineseLocale,
        onChanged: (value) => settings.toggleLanguage(),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  /// 构建默认可见性设置
  Widget _buildDefaultVisibilitySetting(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: Icon(
        settings.defaultDiaryIsPublic ? Icons.public : Icons.lock_outline,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        settings.isChineseLocale ? '默认日记可见性' : 'Default Diary Visibility',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        settings.isChineseLocale 
            ? '新建日记时的默认可见性设置'
            : 'Default visibility for new diaries',
      ),
      trailing: Switch(
        value: settings.defaultDiaryIsPublic,
        onChanged: (value) => settings.setDefaultDiaryVisibility(value),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  /// 构建自动分享设置
  Widget _buildAutoShareSetting(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: Icon(
        Icons.share,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        settings.isChineseLocale ? '自动分享到Farcaster' : 'Auto Share to Farcaster',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        settings.isChineseLocale 
            ? '创建公开日记时自动开启分享选项'
            : 'Auto enable sharing when creating public diaries',
      ),
      trailing: Switch(
        value: settings.autoShareEnabled,
        onChanged: (value) => settings.setAutoShareEnabled(value),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  /// 构建重置按钮
  Widget _buildResetButton(BuildContext context, SettingsProvider settings) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _showResetDialog(context, settings),
        icon: const Icon(Icons.restore, size: 18),
        label: Text(
          settings.isChineseLocale ? '重置所有设置' : 'Reset All Settings',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  /// 构建版本信息
  Widget _buildVersionInfo(BuildContext context, SettingsProvider settings) {
    return Center(
      child: Column(
        children: [
          Text(
            'ThunderTrack',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            settings.isChineseLocale 
                ? '⚡ 去中心化交易日记应用'
                : '⚡ Decentralized Trading Diary App',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 显示主题模式对话框
  void _showThemeModeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            settings.isChineseLocale ? '选择主题模式' : 'Choose Theme Mode',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text(settings.isChineseLocale ? '浅色模式' : 'Light Mode'),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(settings.isChineseLocale ? '深色模式' : 'Dark Mode'),
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(settings.isChineseLocale ? '跟随系统' : 'Follow System'),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(settings.isChineseLocale ? '取消' : 'Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// 显示重置对话框
  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            settings.isChineseLocale ? '重置设置' : 'Reset Settings',
          ),
          content: Text(
            settings.isChineseLocale 
                ? '确定要重置所有设置到默认值吗？此操作无法撤销。'
                : 'Are you sure you want to reset all settings to default values? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(settings.isChineseLocale ? '取消' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                settings.resetToDefaults();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      settings.isChineseLocale 
                          ? '设置已重置' 
                          : 'Settings have been reset',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(settings.isChineseLocale ? '重置' : 'Reset'),
            ),
          ],
        );
      },
    );
  }
}