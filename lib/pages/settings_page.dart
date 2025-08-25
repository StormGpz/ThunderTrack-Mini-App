import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/eva_theme.dart';

/// 设置页面 - EVA主题，简化版
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvaTheme.deepBlack,
      appBar: AppBar(
        title: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Text(
              settings.isChineseLocale ? '设置' : 'Settings',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: EvaTheme.deepBlack,
        elevation: 0,
        iconTheme: IconThemeData(color: EvaTheme.neonGreen),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基础设置
                _buildSectionHeader(
                  settings.isChineseLocale ? '基础设置' : 'Basic Settings',
                  Icons.settings_outlined,
                ),
                const SizedBox(height: 8),
                _buildSettingsCard([
                  _buildLanguageSetting(context, settings),
                ]),

                const SizedBox(height: 24),

                // 交易设置
                _buildSectionHeader(
                  settings.isChineseLocale ? '交易设置' : 'Trading Settings', 
                  Icons.trending_up_outlined,
                ),
                const SizedBox(height: 8),
                _buildSettingsCard([
                  _buildTradingNotificationSetting(context, settings),
                  _buildDefaultCurrencySetting(context, settings),
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
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: EvaTheme.neonGreen,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: EvaTheme.neonGreen,
          ),
        ),
      ],
    );
  }

  /// 构建设置卡片
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EvaTheme.mechGray.withOpacity(0.8),
            EvaTheme.deepBlack.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EvaTheme.neonGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// 构建语言设置
  Widget _buildLanguageSetting(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: EvaTheme.neonGreen,
      ),
      title: Text(
        settings.isChineseLocale ? '语言' : 'Language',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: EvaTheme.lightText,
        ),
      ),
      subtitle: Text(
        settings.isChineseLocale ? '中文' : 'English',
        style: TextStyle(color: EvaTheme.textGray),
      ),
      trailing: Icon(Icons.chevron_right, color: EvaTheme.textGray),
      onTap: () => _showLanguageDialog(context, settings),
    );
  }

  /// 构建交易通知设置
  Widget _buildTradingNotificationSetting(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: Icon(
        Icons.notifications_outlined,
        color: EvaTheme.neonGreen,
      ),
      title: Text(
        settings.isChineseLocale ? '交易通知' : 'Trading Notifications',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: EvaTheme.lightText,
        ),
      ),
      subtitle: Text(
        settings.isChineseLocale ? '重要交易事件提醒' : 'Important trading event alerts',
        style: TextStyle(color: EvaTheme.textGray),
      ),
      trailing: Switch(
        value: true, // 默认开启
        onChanged: (value) {
          // TODO: 实现通知开关逻辑
        },
        activeColor: EvaTheme.neonGreen,
      ),
    );
  }

  /// 构建默认货币设置
  Widget _buildDefaultCurrencySetting(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: Icon(
        Icons.attach_money,
        color: EvaTheme.neonGreen,
      ),
      title: Text(
        settings.isChineseLocale ? '默认计价币种' : 'Default Currency',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: EvaTheme.lightText,
        ),
      ),
      subtitle: Text(
        'USDT',
        style: TextStyle(color: EvaTheme.textGray),
      ),
      trailing: Icon(Icons.chevron_right, color: EvaTheme.textGray),
      onTap: () => _showCurrencyDialog(context, settings),
    );
  }

  /// 构建重置按钮
  Widget _buildResetButton(BuildContext context, SettingsProvider settings) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EvaTheme.primaryPurple.withOpacity(0.8),
              EvaTheme.primaryPurple.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: EvaTheme.primaryPurple,
            width: 1,
          ),
        ),
        child: TextButton(
          onPressed: () => _showResetDialog(context, settings),
          child: Text(
            settings.isChineseLocale ? '重置设置' : 'Reset Settings',
            style: TextStyle(
              color: EvaTheme.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
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
            settings.isChineseLocale ? 'ThunderTrack EVA版本' : 'ThunderTrack EVA Version',
            style: TextStyle(
              color: EvaTheme.textGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1.0.0',
            style: TextStyle(
              color: EvaTheme.neonGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// 显示语言选择对话框
  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvaTheme.mechGray,
        title: Text(
          settings.isChineseLocale ? '选择语言' : 'Select Language',
          style: TextStyle(color: EvaTheme.lightText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('中文', style: TextStyle(color: EvaTheme.lightText)),
              leading: Radio<bool>(
                value: true,
                groupValue: settings.isChineseLocale,
                onChanged: (value) {
                  if (value != null && value) {
                    settings.setLocale(const Locale('zh', 'CN'));
                    Navigator.of(context).pop();
                  }
                },
                activeColor: EvaTheme.neonGreen,
              ),
            ),
            ListTile(
              title: const Text('English', style: TextStyle(color: EvaTheme.lightText)),
              leading: Radio<bool>(
                value: false,
                groupValue: settings.isChineseLocale,
                onChanged: (value) {
                  if (value != null && value) {
                    settings.setLocale(const Locale('en', 'US'));
                    Navigator.of(context).pop();
                  }
                },
                activeColor: EvaTheme.neonGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示货币选择对话框
  void _showCurrencyDialog(BuildContext context, SettingsProvider settings) {
    final currencies = ['USDT', 'USD', 'EUR', 'CNY'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvaTheme.mechGray,
        title: Text(
          settings.isChineseLocale ? '选择计价币种' : 'Select Currency',
          style: TextStyle(color: EvaTheme.lightText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) => ListTile(
            title: Text(currency, style: TextStyle(color: EvaTheme.lightText)),
            leading: Radio<String>(
              value: currency,
              groupValue: 'USDT', // 默认选中USDT
              onChanged: (value) {
                // TODO: 实现货币切换逻辑
                Navigator.of(context).pop();
              },
              activeColor: EvaTheme.neonGreen,
            ),
          )).toList(),
        ),
      ),
    );
  }

  /// 显示重置确认对话框
  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvaTheme.mechGray,
        title: Text(
          settings.isChineseLocale ? '重置设置' : 'Reset Settings',
          style: TextStyle(color: EvaTheme.lightText),
        ),
        content: Text(
          settings.isChineseLocale 
            ? '这将重置所有设置到默认状态，是否继续？'
            : 'This will reset all settings to default values. Continue?',
          style: TextStyle(color: EvaTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              settings.isChineseLocale ? '取消' : 'Cancel',
              style: TextStyle(color: EvaTheme.textGray),
            ),
          ),
          TextButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    settings.isChineseLocale ? '设置已重置' : 'Settings have been reset',
                  ),
                  backgroundColor: EvaTheme.neonGreen,
                ),
              );
            },
            child: Text(
              settings.isChineseLocale ? '确认' : 'Confirm',
              style: TextStyle(color: EvaTheme.neonGreen),
            ),
          ),
        ],
      ),
    );
  }
}