import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/eva_theme.dart';

/// 钱包连接测试页面
class WalletTestPage extends StatefulWidget {
  const WalletTestPage({super.key});

  @override
  State<WalletTestPage> createState() => _WalletTestPageState();
}

class _WalletTestPageState extends State<WalletTestPage> {
  String _testMessage = "Hello ThunderTrack!";
  String? _lastSignature;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvaTheme.deepBlack,
      appBar: AppBar(
        title: const Text('钱包连接测试'),
        backgroundColor: EvaTheme.deepBlack,
        foregroundColor: EvaTheme.lightText,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Web3环境检测
                _buildStatusCard(
                  title: 'Web3环境检测',
                  icon: Icons.settings_system_daydream,
                  children: [
                    _buildStatusRow('Web3可用', userProvider.isWeb3Available),
                    _buildStatusRow('钱包已连接', userProvider.isWalletConnected),
                    if (userProvider.walletAddress != null)
                      _buildInfoRow('钱包地址', userProvider.walletAddress!),
                    _buildChainInfo(userProvider),
                  ],
                ),

                const SizedBox(height: 20),

                // 用户状态
                _buildStatusCard(
                  title: '用户状态',
                  icon: Icons.person,
                  children: [
                    _buildStatusRow('已登录', userProvider.isAuthenticated),
                    if (userProvider.currentUser != null) ...[
                      _buildInfoRow('用户名', userProvider.currentUser!.username),
                      _buildInfoRow('显示名', userProvider.currentUser!.displayName),
                      if (userProvider.currentUser!.walletAddress != null)
                        _buildInfoRow('关联钱包', userProvider.currentUser!.walletAddress!),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // 操作按钮
                _buildActionButtons(userProvider),

                const SizedBox(height: 20),

                // 签名测试
                _buildSignatureTest(userProvider),

                const SizedBox(height: 20),

                // 调试日志
                _buildDebugLogs(userProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EvaTheme.mechGray.withValues(alpha: 0.3),
            EvaTheme.deepBlack.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvaTheme.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: EvaTheme.neonGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: EvaTheme.lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? EvaTheme.neonGreen : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: EvaTheme.textGray, fontSize: 14),
          ),
          const Spacer(),
          Text(
            status ? '是' : '否',
            style: TextStyle(
              color: status ? EvaTheme.neonGreen : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: EvaTheme.textGray, fontSize: 14),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: EvaTheme.lightText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainInfo(UserProvider userProvider) {
    if (!userProvider.isWalletConnected) return const SizedBox.shrink();

    final chainInfo = userProvider.getChainInfo();
    return Column(
      children: [
        _buildInfoRow('链ID', chainInfo['chainId'] ?? '未知'),
        _buildInfoRow('链名称', chainInfo['chainName'] ?? '未知链'),
      ],
    );
  }

  Widget _buildActionButtons(UserProvider userProvider) {
    return Column(
      children: [
        // 连接/断开钱包
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: userProvider.isLoading
                ? null
                : () async {
                    if (userProvider.isWalletConnected) {
                      await userProvider.disconnectWallet();
                    } else {
                      if (userProvider.isWeb3Available) {
                        final success = await userProvider.signInWithEthereum();
                        _showResult(success ? '钱包连接成功！' : '钱包连接失败');
                      } else {
                        _showResult('Web3不可用，请安装MetaMask');
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: userProvider.isWalletConnected
                  ? Colors.red[600]
                  : EvaTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(
              userProvider.isWalletConnected
                  ? Icons.link_off
                  : Icons.account_balance_wallet,
              color: Colors.white,
            ),
            label: Text(
              userProvider.isWalletConnected ? '断开钱包' : '连接钱包',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 获取余额
        if (userProvider.isWalletConnected)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        final balance = await userProvider.getWalletBalance();
                        if (balance != null) {
                          final ethBalance = (int.parse(balance.substring(2), radix: 16) /
                                           1000000000000000000).toStringAsFixed(6);
                          _showResult('余额: $ethBalance ETH');
                        } else {
                          _showResult('获取余额失败');
                        }
                      } catch (e) {
                        _showResult('获取余额失败: $e');
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: EvaTheme.infoBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.account_balance, color: Colors.white),
              label: Text(
                _isLoading ? '获取中...' : '获取余额',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSignatureTest(UserProvider userProvider) {
    if (!userProvider.isWalletConnected) return const SizedBox.shrink();

    return _buildStatusCard(
      title: '签名测试',
      icon: Icons.edit_document,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: '测试消息',
            labelStyle: TextStyle(color: EvaTheme.textGray),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: EvaTheme.primaryPurple),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: EvaTheme.neonGreen),
            ),
          ),
          style: TextStyle(color: EvaTheme.lightText),
          onChanged: (value) => _testMessage = value,
          controller: TextEditingController(text: _testMessage),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    try {
                      final signature = await userProvider.signMessage(_testMessage);
                      setState(() => _lastSignature = signature);
                      _showResult(signature != null ? '签名成功！' : '签名被取消');
                    } catch (e) {
                      _showResult('签名失败: $e');
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: EvaTheme.neonGreen.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(Icons.edit, color: EvaTheme.deepBlack),
            label: Text(
              _isLoading ? '签名中...' : '签名测试消息',
              style: TextStyle(color: EvaTheme.deepBlack, fontSize: 16),
            ),
          ),
        ),
        if (_lastSignature != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow('最后签名', _lastSignature!),
        ],
      ],
    );
  }

  Widget _buildDebugLogs(UserProvider userProvider) {
    return _buildStatusCard(
      title: '调试日志',
      icon: Icons.bug_report,
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: EvaTheme.primaryPurple.withValues(alpha: 0.3)),
          ),
          child: userProvider.debugLogs.isEmpty
              ? Center(
                  child: Text(
                    '暂无调试日志',
                    style: TextStyle(color: EvaTheme.textGray, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  itemCount: userProvider.debugLogs.length,
                  itemBuilder: (context, index) {
                    final log = userProvider.debugLogs[index];
                    Color textColor = Colors.white;

                    if (log.contains('✅') || log.contains('成功')) {
                      textColor = Colors.green[300]!;
                    } else if (log.contains('❌') || log.contains('失败')) {
                      textColor = Colors.red[300]!;
                    } else if (log.contains('⚠️') || log.contains('警告')) {
                      textColor = Colors.orange[300]!;
                    } else if (log.contains('🔄')) {
                      textColor = Colors.blue[300]!;
                    }

                    return SelectableText(
                      log,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: userProvider.clearDebugLogs,
            icon: Icon(Icons.clear_all, color: EvaTheme.textGray),
            label: Text(
              '清空日志',
              style: TextStyle(color: EvaTheme.textGray),
            ),
          ),
        ),
      ],
    );
  }

  void _showResult(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('成功') ? Colors.green : Colors.red,
      ),
    );
  }
}