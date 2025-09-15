import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';

/// Web3钱包连接服务 (仅支持Web平台)
class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  String? _currentAccount;
  bool _isConnected = false;
  String? _chainId;

  // Getters
  String? get currentAccount => _currentAccount;
  bool get isConnected => _isConnected;
  String? get chainId => _chainId;

  /// 检查是否在Web平台且有以太坊提供者
  bool get isWeb3Available {
    if (!kIsWeb) return false;
    return js.context.hasProperty('ethereum');
  }

  /// 检查MetaMask是否已安装
  bool get isMetaMaskInstalled {
    if (!isWeb3Available) return false;
    final ethereum = js.context['ethereum'];
    return ethereum != null && ethereum['isMetaMask'] == true;
  }

  /// 检查是否已有连接的账户 (初始化时检测)
  Future<void> checkExistingConnection() async {
    if (!isWeb3Available) return;

    try {
      debugPrint('🔍 检查已连接的账户...');
      final ethereum = js.context['ethereum'];

      // 获取当前已连接的账户
      final accounts = await js_util.promiseToFuture(
        ethereum.callMethod('request', [
          js.JsObject.jsify({
            'method': 'eth_accounts', // 注意：这里用 eth_accounts 而不是 eth_requestAccounts
          })
        ])
      );

      if (accounts != null && accounts.length > 0) {
        _currentAccount = accounts[0];
        _isConnected = true;

        debugPrint('✅ 发现已连接账户: $_currentAccount');

        // 获取当前链ID
        await _getCurrentChainId();

        // 设置事件监听器
        _setupEventListeners();
      } else {
        debugPrint('ℹ️ 未发现已连接的账户');
      }
    } catch (e) {
      debugPrint('❌ 检查连接状态失败: $e');
    }
  }

  /// 连接钱包
  Future<String?> connectWallet() async {
    if (!isWeb3Available) {
      debugPrint('❌ Web3不可用，请在支持的浏览器中使用');
      throw Exception('Web3不可用，请在支持的浏览器中使用');
    }

    try {
      debugPrint('🔄 开始连接钱包...');
      final ethereum = js.context['ethereum'];

      // 请求账户访问权限
      final accounts = await js_util.promiseToFuture(
        ethereum.callMethod('request', [
          js.JsObject.jsify({
            'method': 'eth_requestAccounts',
          })
        ])
      );

      if (accounts != null && accounts.length > 0) {
        _currentAccount = accounts[0];
        _isConnected = true;

        debugPrint('✅ 钱包连接成功: $_currentAccount');

        // 获取当前链ID
        await _getCurrentChainId();

        // 设置事件监听器
        _setupEventListeners();

        return _currentAccount;
      }

      return null;
    } catch (e) {
      debugPrint('❌ 连接钱包失败: $e');
      throw Exception('连接钱包失败: $e');
    }
  }

  /// 获取当前链ID
  Future<void> _getCurrentChainId() async {
    if (!isWeb3Available) return;

    try {
      final ethereum = js.context['ethereum'];
      final chainId = await js_util.promiseToFuture(
        ethereum.callMethod('request', [
          js.JsObject.jsify({
            'method': 'eth_chainId',
          })
        ])
      );

      _chainId = chainId?.toString();
      debugPrint('🔗 当前链ID: $_chainId');
    } catch (e) {
      debugPrint('❌ 获取链ID失败: $e');
    }
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    if (!isWeb3Available) return;

    try {
      final ethereum = js.context['ethereum'];

      // 监听账户变化
      ethereum.callMethod('on', [
        'accountsChanged',
        js.allowInterop((accounts) {
          debugPrint('📱 账户已变化: $accounts');
          if (accounts != null && accounts.length > 0) {
            _currentAccount = accounts[0];
            debugPrint('✅ 新账户: $_currentAccount');
          } else {
            _currentAccount = null;
            _isConnected = false;
            debugPrint('❌ 账户已断开连接');
          }
        })
      ]);

      // 监听链变化
      ethereum.callMethod('on', [
        'chainChanged',
        js.allowInterop((chainId) {
          _chainId = chainId?.toString();
          debugPrint('🔗 链已切换: $_chainId');
        })
      ]);

      // 监听连接状态
      ethereum.callMethod('on', [
        'connect',
        js.allowInterop((connectInfo) {
          debugPrint('✅ 钱包已连接: $connectInfo');
          _isConnected = true;
        })
      ]);

      ethereum.callMethod('on', [
        'disconnect',
        js.allowInterop((error) {
          debugPrint('❌ 钱包已断开: $error');
          _isConnected = false;
          _currentAccount = null;
          _chainId = null;
        })
      ]);

    } catch (e) {
      debugPrint('❌ 设置事件监听器失败: $e');
    }
  }

  /// 断开钱包连接
  Future<void> disconnectWallet() async {
    _currentAccount = null;
    _isConnected = false;
    _chainId = null;
    debugPrint('✅ 钱包已断开连接');
  }

  /// 切换到以太坊主网
  Future<bool> switchToMainnet() async {
    return await switchToChain('0x1'); // 以太坊主网
  }

  /// 切换到指定链
  Future<bool> switchToChain(String chainId) async {
    if (!isWeb3Available || !_isConnected) {
      debugPrint('❌ 钱包未连接，无法切换链');
      return false;
    }

    try {
      final ethereum = js.context['ethereum'];

      await js_util.promiseToFuture(
        ethereum.callMethod('request', [
          js.JsObject.jsify({
            'method': 'wallet_switchEthereumChain',
            'params': [
              {'chainId': chainId}
            ]
          })
        ])
      );

      debugPrint('✅ 成功切换到链: $chainId');
      return true;
    } catch (e) {
      debugPrint('❌ 切换链失败: $e');
      return false;
    }
  }

  /// 签名消息 (用于EIP-712签名)
  Future<String?> signMessage(String message) async {
    if (!isWeb3Available || !_isConnected || _currentAccount == null) {
      debugPrint('❌ 钱包未连接，无法签名');
      return null;
    }

    try {
      debugPrint('🔏 开始签名消息...');
      final ethereum = js.context['ethereum'];

      final signature = await js_util.promiseToFuture(
        ethereum.callMethod('request', [
          js.JsObject.jsify({
            'method': 'personal_sign',
            'params': [message, _currentAccount]
          })
        ])
      );

      debugPrint('✅ 消息签名成功');
      return signature?.toString();
    } catch (e) {
      debugPrint('❌ 消息签名失败: $e');
      return null;
    }
  }

  /// EIP-712 结构化数据签名 (用于Hyperliquid)
  Future<String?> signTypedData(Map<String, dynamic> typedData) async {
    if (!isWeb3Available || !_isConnected || _currentAccount == null) {
      debugPrint('❌ 钱包未连接，无法签名');
      return null;
    }

    try {
      debugPrint('🔏 开始EIP-712签名...');
      final ethereum = js.context['ethereum'];

      final signature = await js_util.promiseToFuture(
        ethereum.callMethod('request', [
          js.JsObject.jsify({
            'method': 'eth_signTypedData_v4',
            'params': [_currentAccount, js.JsObject.jsify(typedData)]
          })
        ])
      );

      debugPrint('✅ EIP-712签名成功');
      return signature?.toString();
    } catch (e) {
      debugPrint('❌ EIP-712签名失败: $e');
      return null;
    }
  }

  /// 获取钱包余额 (ETH)
  Future<String?> getBalance() async {
    if (!isWeb3Available || !_isConnected || _currentAccount == null) {
      return null;
    }

    try {
      final ethereum = js.context['ethereum'];

      final balance = await js_util.promiseToFuture(
        ethereum.callMethod('request', [
          js.JsObject.jsify({
            'method': 'eth_getBalance',
            'params': [_currentAccount, 'latest']
          })
        ])
      );

      return balance?.toString();
    } catch (e) {
      debugPrint('❌ 获取余额失败: $e');
      return null;
    }
  }

  /// 检查是否已连接到指定链
  bool isConnectedToChain(String targetChainId) {
    return _chainId == targetChainId;
  }

  /// 获取链信息
  Map<String, String> getChainInfo() {
    final chainInfo = <String, String>{
      '0x1': '以太坊主网',
      '0x89': 'Polygon 主网',
      '0xa4b1': 'Arbitrum One',
      '0xa': 'Optimism',
    };

    return {
      'chainId': _chainId ?? '未知',
      'chainName': chainInfo[_chainId] ?? '未知链',
    };
  }
}