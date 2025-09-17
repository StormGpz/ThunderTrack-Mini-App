import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/eva_theme.dart';

/// Farcaster 内置钱包测试页面
class FarcasterWalletTestPage extends StatefulWidget {
  const FarcasterWalletTestPage({super.key});

  @override
  State<FarcasterWalletTestPage> createState() => _FarcasterWalletTestPageState();
}

class _FarcasterWalletTestPageState extends State<FarcasterWalletTestPage> {
  final TextEditingController _messageController = TextEditingController();
  String? _lastSignature;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = 'Hello from ThunderTrack! Timestamp: ${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// 测试消息签名
  Future<void> _testSignMessage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (_messageController.text.trim().isEmpty) {
      _showError('请输入要签名的消息');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastSignature = null;
    });

    try {
      final signature = await userProvider.signMessage(_messageController.text.trim());

      setState(() {
        _lastSignature = signature;
        _isLoading = false;
      });

      if (signature != null) {
        _showSuccess('签名成功！');
      } else {
        _showError('签名失败或被取消');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('签名出错: $e');
    }
  }

  /// 测试 EIP-712 签名
  Future<void> _testSignTypedData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final typedData = userProvider.generateWalletSignatureData(
      address: userProvider.currentUser?.walletAddress ?? '',
      appFid: 12345,
    );

    setState(() {
      _isLoading = true;
      _lastSignature = null;
    });

    try {
      final signature = await userProvider.signTypedData(typedData);

      setState(() {
        _lastSignature = signature;
        _isLoading = false;
      });

      if (signature != null) {
        _showSuccess('EIP-712 签名成功！');
      } else {
        _showError('EIP-712 签名失败或被取消');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('EIP-712 签名出错: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: EvaTheme.deepBlack,
          appBar: AppBar(
            backgroundColor: EvaTheme.deepBlack,
            title: Text(
              'Farcaster 钱包测试',
              style: TextStyle(color: EvaTheme.lightText),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: EvaTheme.lightText),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 环境状态
                _buildStatusCard(userProvider),
                const SizedBox(height: 20),

                // 钱包信息
                _buildWalletInfoCard(userProvider),
                const SizedBox(height: 20),

                // 消息签名测试
                _buildSignMessageCard(),
                const SizedBox(height: 20),

                // EIP-712 签名测试
                _buildSignTypedDataCard(),
                const SizedBox(height: 20),

                // 签名结果
                if (_lastSignature != null) _buildSignatureResultCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(UserProvider userProvider) {
    return Card(
      color: EvaTheme.mechGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔍 环境状态',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusItem('Mini App环境', userProvider.isMiniAppEnvironment),
            _buildStatusItem('SDK可用', userProvider.isMiniAppSdkAvailable),
            _buildStatusItem('内置钱包', userProvider.hasBuiltinWallet),
            _buildStatusItem('用户已登录', userProvider.isAuthenticated),
            _buildStatusItem('Web3钱包连接', userProvider.isWalletConnected),

            const SizedBox(height: 12),
            Text(
              '📋 调试信息',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 显示环境信息
            ...userProvider.environmentInfo.entries.map((entry) {
              if (entry.key == 'userAgent') {
                // 简化显示 userAgent
                final userAgent = entry.value.toString();
                final simplified = userAgent.split(' ').take(3).join(' ');
                return _buildInfoItem(entry.key, simplified);
              }
              return _buildInfoItem(entry.key, entry.value.toString());
            }).toList(),

            // 显示钱包相关信息
            if (userProvider.currentUser?.walletAddress != null)
              _buildInfoItem('walletAddress',
                '${userProvider.currentUser!.walletAddress!.substring(0, 10)}...'),

            // 显示调试日志的最后几条
            const SizedBox(height: 8),
            Text(
              '📋 最近日志',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EvaTheme.deepBlack,
                border: Border.all(color: EvaTheme.primaryPurple),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  userProvider.debugLogs.take(5).join('\n'),
                  style: TextStyle(
                    color: EvaTheme.lightGray,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: EvaTheme.lightGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: EvaTheme.lightGray,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${status ? "是" : "否"}',
            style: TextStyle(color: EvaTheme.lightText),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfoCard(UserProvider userProvider) {
    return Card(
      color: EvaTheme.mechGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💳 钱包信息',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (userProvider.currentUser?.walletAddress != null) ...[
              Text(
                '当前钱包地址:',
                style: TextStyle(color: EvaTheme.lightText, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EvaTheme.deepBlack,
                  border: Border.all(color: EvaTheme.primaryPurple),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  userProvider.currentUser!.walletAddress!,
                  style: TextStyle(
                    color: EvaTheme.lightGray,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '钱包类型:',
                style: TextStyle(color: EvaTheme.lightText, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: userProvider.hasBuiltinWallet
                      ? EvaTheme.neonGreen.withValues(alpha: 0.2)
                      : EvaTheme.warningYellow.withValues(alpha: 0.2),
                  border: Border.all(
                    color: userProvider.hasBuiltinWallet
                        ? EvaTheme.neonGreen
                        : EvaTheme.warningYellow,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  userProvider.hasBuiltinWallet ? 'Farcaster 内置钱包' : 'Web3 钱包',
                  style: TextStyle(
                    color: userProvider.hasBuiltinWallet
                        ? EvaTheme.neonGreen
                        : EvaTheme.warningYellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '签名能力:',
                style: TextStyle(color: EvaTheme.lightText, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    userProvider.hasBuiltinWallet ? Icons.check_circle : Icons.warning,
                    color: userProvider.hasBuiltinWallet ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    userProvider.hasBuiltinWallet
                        ? '支持内置钱包签名'
                        : '需要连接外部钱包',
                    style: TextStyle(
                      color: EvaTheme.lightGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '未检测到钱包地址',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '这可能意味着 custodyAddress 获取失败',
                      style: TextStyle(
                        color: EvaTheme.textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignMessageCard() {
    return Card(
      color: EvaTheme.mechGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✍️ 消息签名测试',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              style: TextStyle(color: EvaTheme.lightText),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '输入要签名的消息',
                hintStyle: TextStyle(color: EvaTheme.textGray),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: EvaTheme.primaryPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: EvaTheme.primaryPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: EvaTheme.neonGreen),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testSignMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvaTheme.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '签名消息',
                        style: TextStyle(color: EvaTheme.lightText),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignTypedDataCard() {
    return Card(
      color: EvaTheme.mechGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔐 EIP-712 签名测试',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '这将测试结构化数据签名，用于 Hyperliquid 交易授权',
              style: TextStyle(color: EvaTheme.textGray, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testSignTypedData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvaTheme.neonGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'EIP-712 签名',
                        style: TextStyle(color: EvaTheme.deepBlack),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureResultCard() {
    return Card(
      color: EvaTheme.mechGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ 签名结果',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EvaTheme.deepBlack,
                border: Border.all(color: EvaTheme.primaryPurple),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _lastSignature!,
                style: TextStyle(
                  color: EvaTheme.lightText,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}