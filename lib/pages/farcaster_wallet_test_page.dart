import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/eva_theme.dart';
import '../services/farcaster_miniapp_service.dart';
import 'dart:js' as js;
import 'dart:async';

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

                // 钱包连接测试
                _buildWalletConnectionCard(),
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
            Row(
              children: [
                Text(
                  '📋 最近日志',
                  style: TextStyle(
                    color: EvaTheme.lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);

                    // 清除旧的调试日志
                    userProvider.clearDebugLogs();
                    userProvider.addDebugLog('🔄 手动刷新用户数据开始...');

                    try {
                      // 重新初始化用户状态，这会触发自动登录
                      await userProvider.initialize();
                      userProvider.addDebugLog('✅ 用户数据刷新完成');
                    } catch (e) {
                      userProvider.addDebugLog('❌ 刷新失败: $e');
                    }

                    setState(() {});
                  },
                  child: Text(
                    '刷新',
                    style: TextStyle(color: EvaTheme.neonGreen, fontSize: 12),
                  ),
                ),
              ],
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

  Widget _buildWalletConnectionCard() {
    return Card(
      color: EvaTheme.mechGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔗 钱包连接测试',
              style: TextStyle(
                color: EvaTheme.lightText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试通过不同方式连接和获取钱包地址',
              style: TextStyle(color: EvaTheme.textGray, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // SDK 钱包连接按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testSDKWalletConnection,
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
                        '测试 SDK 钱包连接',
                        style: TextStyle(color: EvaTheme.lightText),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // 以太坊提供者测试按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testEthereumProvider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvaTheme.neonGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  '测试以太坊提供者',
                  style: TextStyle(color: EvaTheme.deepBlack),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 请求钱包权限按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestWalletPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvaTheme.warningYellow,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  '请求钱包权限',
                  style: TextStyle(color: EvaTheme.deepBlack),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 深度钱包地址调试按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deepWalletAddressDebug,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvaTheme.primaryPurple.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  '深度调试钱包地址',
                  style: TextStyle(color: EvaTheme.lightText),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 刷新钱包地址按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _refreshWalletAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvaTheme.neonGreen.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  '刷新钱包地址',
                  style: TextStyle(color: EvaTheme.deepBlack),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 测试 SDK 钱包连接
  Future<void> _testSDKWalletConnection() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      userProvider.addDebugLog('🔗 开始测试 SDK 钱包连接...');

      // 检查 SDK 是否可用
      if (!userProvider.isMiniAppSdkAvailable) {
        userProvider.addDebugLog('❌ Farcaster SDK 不可用');
        _showError('Farcaster SDK 不可用');
        return;
      }

      // 获取以太坊提供者
      final provider = userProvider.getEthereumProvider();
      if (provider == null) {
        userProvider.addDebugLog('❌ 未找到以太坊提供者');
        _showError('未找到以太坊提供者');
        return;
      }

      userProvider.addDebugLog('✅ 找到以太坊提供者');

      // 尝试获取账户
      try {
        final accounts = await _callProviderMethod(provider, 'eth_accounts');
        userProvider.addDebugLog('📋 当前账户: $accounts');

        if (accounts != null && accounts is List && accounts.isNotEmpty) {
          final address = accounts.first.toString();
          userProvider.addDebugLog('🔑 获取到钱包地址: $address');
          _showSuccess('获取到钱包地址: ${address.substring(0, 10)}...');
        } else {
          userProvider.addDebugLog('⚠️ 没有已连接的账户，尝试请求连接...');
          await _requestWalletConnection(provider);
        }
      } catch (e) {
        userProvider.addDebugLog('❌ 获取账户失败: $e');
        _showError('获取账户失败: $e');
      }
    } catch (e) {
      userProvider.addDebugLog('❌ SDK 钱包连接测试失败: $e');
      _showError('测试失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试以太坊提供者
  Future<void> _testEthereumProvider() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      userProvider.addDebugLog('🔍 开始测试以太坊提供者...');

      final provider = userProvider.getEthereumProvider();
      if (provider == null) {
        userProvider.addDebugLog('❌ 未找到以太坊提供者');
        _showError('未找到以太坊提供者');
        return;
      }

      // 测试各种方法
      final methods = [
        'eth_accounts',
        'eth_requestAccounts',
        'eth_coinbase',
        'net_version',
        'eth_chainId',
      ];

      for (final method in methods) {
        try {
          final result = await _callProviderMethod(provider, method);
          userProvider.addDebugLog('✅ $method: $result');
        } catch (e) {
          userProvider.addDebugLog('❌ $method 失败: $e');
        }
      }

      _showSuccess('以太坊提供者测试完成，查看日志');
    } catch (e) {
      userProvider.addDebugLog('❌ 以太坊提供者测试失败: $e');
      _showError('测试失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 请求钱包权限
  Future<void> _requestWalletPermissions() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      userProvider.addDebugLog('🔐 开始请求钱包权限...');

      final provider = userProvider.getEthereumProvider();
      if (provider == null) {
        userProvider.addDebugLog('❌ 未找到以太坊提供者');
        _showError('未找到以太坊提供者');
        return;
      }

      await _requestWalletConnection(provider);

      // 不要重新初始化用户数据，避免覆盖正确的钱包地址
      userProvider.addDebugLog('✅ 钱包权限请求完成，保持当前钱包地址');

      _showSuccess('钱包权限请求完成');
    } catch (e) {
      userProvider.addDebugLog('❌ 请求钱包权限失败: $e');
      _showError('请求权限失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 请求钱包连接
  Future<void> _requestWalletConnection(dynamic provider) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      userProvider.addDebugLog('🔗 请求钱包连接...');

      final accounts = await _callProviderMethod(provider, 'eth_requestAccounts');
      userProvider.addDebugLog('✅ 钱包连接成功: $accounts');

      if (accounts != null && accounts is List && accounts.isNotEmpty) {
        final address = accounts.first.toString();
        userProvider.addDebugLog('🔑 新连接的钱包地址: $address');
      }
    } catch (e) {
      userProvider.addDebugLog('❌ 钱包连接请求失败: $e');
      rethrow;
    }
  }

  /// 调用提供者方法
  Future<dynamic> _callProviderMethod(dynamic provider, String method, [List? params]) async {
    try {
      if (provider == null) return null;

      // 使用 dart:js 调用以太坊提供者方法
      final request = provider['request'];
      if (request == null) {
        throw Exception('Provider 没有 request 方法');
      }

      final requestData = js.JsObject.jsify({
        'method': method,
        'params': params ?? [],
      });

      final result = request.apply([requestData]);

      // 检查是否是 Promise
      if (result != null && result['then'] != null) {
        // 这是一个Promise，需要等待完成
        final completer = Completer<dynamic>();

        final onSuccess = js.allowInterop((dynamic value) {
          if (!completer.isCompleted) {
            completer.complete(value);
          }
        });

        final onError = js.allowInterop((dynamic error) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Promise rejected: $error'));
          }
        });

        result.callMethod('then', [onSuccess]).callMethod('catch', [onError]);

        // 设置超时
        Timer(const Duration(seconds: 5), () {
          if (!completer.isCompleted) {
            completer.completeError(TimeoutException('Request timeout'));
          }
        });

        return await completer.future;
      }

      return result;
    } catch (e) {
      throw Exception('调用 $method 失败: $e');
    }
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

  /// 深度调试钱包地址 - 专门查找内置钱包地址
  Future<void> _deepWalletAddressDebug() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      userProvider.addDebugLog('🔍 开始全面深度钱包地址调试...');

      // 调用增强版的调试方法
      final miniAppService = FarcasterMiniAppService();
      final walletDebugResult = await miniAppService.debugBuiltinWalletAddress();

      if (walletDebugResult != null) {
        userProvider.addDebugLog('✅ 钱包调试完成！');

        // 首先显示总结信息
        final addressCount = walletDebugResult['address_count'] ?? 0;
        final allAddresses = walletDebugResult['all_unique_addresses'] as List<dynamic>? ?? [];

        userProvider.addDebugLog('📊 总共发现 $addressCount 个唯一地址');

        // 显示所有发现的地址
        if (allAddresses.isNotEmpty) {
          userProvider.addDebugLog('🎯 所有发现的地址:');
          for (int i = 0; i < allAddresses.length; i++) {
            final addr = allAddresses[i].toString();
            final isTarget = addr.startsWith('0x7122');
            userProvider.addDebugLog(
              '   ${i + 1}. $addr ${isTarget ? '⭐ (匹配目标地址!)' : ''}'
            );
          }
        }

        userProvider.addDebugLog('');
        userProvider.addDebugLog('📋 详细调试信息:');

        // 按类别显示详细信息
        final categories = {
          'SDK Wallet': 'sdk_wallet_',
          'SDK Ethereum': 'sdk_ethereum_',
          'Context User': 'context_user_',
          'Context其他': 'context_',
          'SDK其他': 'sdk_',
          'Provider': 'provider_',
          '全局对象': 'global_',
        };

        categories.forEach((categoryName, prefix) {
          final categoryItems = walletDebugResult.entries
              .where((entry) => entry.key.startsWith(prefix))
              .toList();

          if (categoryItems.isNotEmpty) {
            userProvider.addDebugLog('');
            userProvider.addDebugLog('📂 $categoryName:');

            for (final item in categoryItems) {
              final key = item.key.substring(prefix.length);
              final value = item.value.toString();

              // 检查是否是地址
              final isAddress = value.length == 42 &&
                              value.startsWith('0x') &&
                              RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(value);

              if (isAddress) {
                final isTarget = value.startsWith('0x7122');
                userProvider.addDebugLog(
                  '   🔑 $key: $value ${isTarget ? '⭐' : ''}'
                );
              } else if (key.toLowerCase().contains('address') ||
                        key.toLowerCase().contains('wallet') ||
                        key.toLowerCase().contains('account')) {
                userProvider.addDebugLog('   🔍 $key: $value');
              } else if (value.length < 100) {
                userProvider.addDebugLog('   📝 $key: $value');
              } else {
                userProvider.addDebugLog('   📝 $key: ${value.substring(0, 50)}...');
              }
            }
          }
        });

        // 特别检查目标地址
        final targetAddresses = allAddresses
            .where((addr) => addr.toString().startsWith('0x7122'))
            .toList();

        if (targetAddresses.isNotEmpty) {
          userProvider.addDebugLog('');
          userProvider.addDebugLog('🎉 找到目标地址 (0x7122开头):');
          for (final addr in targetAddresses) {
            userProvider.addDebugLog('⭐ $addr');
          }
        } else {
          userProvider.addDebugLog('');
          userProvider.addDebugLog('❓ 未找到以0x7122开头的地址');
          userProvider.addDebugLog('💡 建议检查其他可能的地址来源或字段');
        }

      } else {
        userProvider.addDebugLog('❌ 钱包调试失败或未找到钱包信息');
        userProvider.addDebugLog('💡 可能原因:');
        userProvider.addDebugLog('   1. 未在Farcaster Mini App环境中运行');
        userProvider.addDebugLog('   2. SDK未正确加载');
        userProvider.addDebugLog('   3. 用户未登录');
      }

      _showSuccess('钱包地址调试完成，请查看日志');
    } catch (e) {
      userProvider.addDebugLog('❌ 深度钱包地址调试失败: $e');
      _showError('深度调试失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 刷新钱包地址 - 使用最新的eth_accounts方法
  Future<void> _refreshWalletAddress() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      userProvider.addDebugLog('🔄 开始刷新钱包地址...');

      if (userProvider.currentUser == null) {
        userProvider.addDebugLog('❌ 没有当前用户，无法刷新钱包地址');
        _showError('请先登录');
        return;
      }

      // 通过eth_accounts获取最新的钱包地址
      final miniAppService = FarcasterMiniAppService();
      final newWalletAddress = await miniAppService.getBuiltinWalletAddress();

      if (newWalletAddress != null && newWalletAddress.isNotEmpty) {
        userProvider.addDebugLog('✅ 获取到新的钱包地址: $newWalletAddress');

        // 检查是否与当前地址不同
        if (userProvider.currentUser!.walletAddress != newWalletAddress) {
          userProvider.addDebugLog('🔄 钱包地址有变化，更新用户信息...');
          userProvider.addDebugLog('   旧地址: ${userProvider.currentUser!.walletAddress ?? "无"}');
          userProvider.addDebugLog('   新地址: $newWalletAddress');

          // 更新用户的钱包地址
          await userProvider.updateUserWalletAddress(newWalletAddress);
          userProvider.addDebugLog('✅ 钱包地址已更新');
          _showSuccess('钱包地址已刷新: ${newWalletAddress.substring(0, 10)}...');
        } else {
          userProvider.addDebugLog('ℹ️ 钱包地址没有变化');
          _showSuccess('钱包地址已是最新');
        }
      } else {
        userProvider.addDebugLog('❌ 无法获取钱包地址');
        _showError('无法获取钱包地址，请检查连接');
      }

    } catch (e) {
      userProvider.addDebugLog('❌ 刷新钱包地址失败: $e');
      _showError('刷新失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 记录 JS 对象的所有属性
  void _logAllProperties(dynamic jsObject, String objectName, UserProvider userProvider) {
    try {
      // 使用 Object.keys 获取所有属性名
      final keys = js.context['Object'].callMethod('keys', [jsObject]);
      if (keys != null) {
        final keyList = List<String>.from(keys);
        userProvider.addDebugLog('🔑 $objectName 的属性: ${keyList.join(', ')}');

        // 遍历每个属性并记录其值
        for (final key in keyList) {
          try {
            final value = jsObject[key];
            if (value != null) {
              final valueStr = value.toString();
              final displayValue = valueStr.length > 100 ? '${valueStr.substring(0, 100)}...' : valueStr;
              userProvider.addDebugLog('   $objectName.$key = $displayValue');

              // 如果是地址相关的属性，特别标记
              if (key.toLowerCase().contains('address') || key.toLowerCase().contains('account')) {
                userProvider.addDebugLog('🔑 *** 发现地址属性: $objectName.$key = $displayValue ***');
              }
            }
          } catch (e) {
            userProvider.addDebugLog('   $objectName.$key = [访问失败: $e]');
          }
        }
      }

      // 检查一些常见的嵌套属性
      final commonNestedProps = ['address', 'selectedAddress', 'accounts', 'custodyAddress'];
      for (final prop in commonNestedProps) {
        try {
          final value = jsObject[prop];
          if (value != null) {
            userProvider.addDebugLog('🎯 $objectName.$prop = ${value.toString()}');
          }
        } catch (e) {
          // 忽略访问错误
        }
      }
    } catch (e) {
      userProvider.addDebugLog('❌ 无法获取 $objectName 的属性: $e');
    }
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