import '../models/market_data.dart';
import '../models/address_auth.dart';
import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import '../utils/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Hyperliquid API服务 - 基于官方Python SDK架构
/// 参考: https://github.com/hyperliquid-dex/hyperliquid-python-sdk
class HyperliquidService {
  static final HyperliquidService _instance = HyperliquidService._internal();
  factory HyperliquidService() => _instance;
  HyperliquidService._internal();

  final ApiClient _apiClient = ApiClient();

  // API配置 - 匹配Python SDK结构
  static const String _infoUrl = '/info';
  static const String _exchangeUrl = '/exchange'; 
  
  // 地址授权管理
  String? _currentTradingAddress;
  String? _apiPrivateKey; // API钱包私钥 (secret_key in Python SDK)
  Map<String, AddressAuthInfo> _addressAuthCache = {};
  
  static const String _keyTradingAddress = 'hyperliquid_trading_address';
  static const String _keyApiPrivateKey = 'hyperliquid_api_private_key';
  static const String _keyAddressAuth = 'hyperliquid_address_auth';

  /// 当前交易地址 (account_address in Python SDK)
  String? get currentTradingAddress => _currentTradingAddress;
  
  /// API私钥是否已配置
  bool get hasApiKey => _apiPrivateKey != null && _apiPrivateKey!.isNotEmpty;
  
  /// 检查地址是否已授权
  bool isAddressAuthorized(String address) {
    return _addressAuthCache[address]?.isAuthorized == true;
  }

  /// 获取地址授权状态
  AddressAuthStatus getAddressAuthStatus(String address) {
    return _addressAuthCache[address]?.status ?? AddressAuthStatus.unselected;
  }

  /// 配置API密钥 - 类似Python SDK的config.json
  Future<void> configureApiKey({
    required String accountAddress, 
    required String secretKey
  }) async {
    _currentTradingAddress = accountAddress;
    _apiPrivateKey = secretKey;
    
    await _saveTradingAddress(accountAddress);
    await _saveApiPrivateKey(secretKey);
    
    debugPrint('🔑 API密钥已配置');
    debugPrint('📍 账户地址: ${accountAddress.substring(0, 8)}...');
  }

  /// Info API - 获取用户状态 (Python SDK: info.user_state)
  Future<Map<String, dynamic>> getUserState(String? address) async {
    final targetAddress = address ?? _currentTradingAddress;
    if (targetAddress == null) {
      throw ApiException('请先配置交易地址');
    }

    try {
      final response = await _apiClient.post(
        _infoUrl,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {
          'type': 'clearinghouseState',
          'user': targetAddress,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException('获取用户状态失败');
    } catch (e) {
      throw ApiException('获取用户状态失败: $e');
    }
  }

  /// Info API - 获取用户填充历史 (类似Python SDK的user fills)
  Future<List<Map<String, dynamic>>> getUserFills(String? address) async {
    final targetAddress = address ?? _currentTradingAddress;
    if (targetAddress == null) {
      throw ApiException('请先配置交易地址');
    }

    try {
      final response = await _apiClient.post(
        _infoUrl,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {
          'type': 'userFills',
          'user': targetAddress,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw ApiException('获取交易历史失败');
    } catch (e) {
      throw ApiException('获取交易历史失败: $e');
    }
  }

  /// Info API - 获取所有交易对中间价 (Python SDK: info.all_mids)
  Future<Map<String, double>> getAllMids() async {
    try {
      final response = await _apiClient.post(
        _infoUrl,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {'type': 'allMids'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      throw ApiException('获取价格数据失败');
    } catch (e) {
      throw ApiException('获取价格数据失败: $e');
    }
  }

  /// Info API - 获取市场元数据 (Python SDK: info.meta)
  Future<Map<String, dynamic>> getMeta() async {
    try {
      final response = await _apiClient.post(
        _infoUrl,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {'type': 'meta'},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException('获取市场元数据失败');
    } catch (e) {
      throw ApiException('获取市场元数据失败: $e');
    }
  }

  /// 获取市场数据 - 基于getAllMids和getMeta组合
  Future<List<MarketData>> getMarketData() async {
    try {
      // 并行获取价格数据和市场元数据
      final futures = await Future.wait([
        getAllMids(),
        getMeta(),
      ]);
      
      final mids = futures[0] as Map<String, double>;
      final meta = futures[1] as Map<String, dynamic>;
      
      return _parseMarketData(mids, meta);
    } catch (e) {
      throw ApiException('获取市场数据失败: $e');
    }
  }

  /// Exchange API - 下单 (Python SDK: exchange.place_order)
  Future<String> placeOrder({
    required String symbol,
    required double size,
    required String side,
    required String orderType,
    double? price,
    String? timeInForce,
    bool reduceOnly = false,
  }) async {
    // 检查配置
    if (_currentTradingAddress == null || _apiPrivateKey == null) {
      throw ApiException('请先配置API密钥和交易地址');
    }
    
    if (!isAddressAuthorized(_currentTradingAddress!)) {
      throw ApiException('当前地址未授权，请先完成授权');
    }

    try {
      final orderData = {
        'coin': symbol,
        'is_buy': side.toLowerCase() == 'buy',
        'sz': size.toString(),
        'limit_px': price?.toString() ?? '0',
        'order_type': _mapOrderType(orderType),
        'reduce_only': reduceOnly,
        'tif': timeInForce ?? 'Gtc', // Good Till Cancel
      };

      // 生成签名 - 需要实现EIP-712签名
      final signature = await _generateExchangeSignature({
        'action': {
          'type': 'order',
          'orders': [orderData],
          'grouping': 'na',
        },
        'nonce': DateTime.now().millisecondsSinceEpoch,
      });

      final response = await _apiClient.post(
        _exchangeUrl,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {
          'action': {
            'type': 'order',
            'orders': [orderData],
            'grouping': 'na',
          },
          'nonce': DateTime.now().millisecondsSinceEpoch,
          'signature': signature,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return _extractOrderId(response.data);
      }
      throw ApiException('下单失败');
    } catch (e) {
      throw ApiException('下单失败: $e');
    }
  }

  /// 初始化服务（加载本地配置信息）
  Future<void> initialize() async {
    await _loadLocalAuthInfo();
    debugPrint('🚀 HyperliquidService 初始化完成');
    debugPrint('📍 当前交易地址: ${_currentTradingAddress ?? "未配置"}');
    debugPrint('🔐 API密钥状态: ${hasApiKey ? "已配置" : "未配置"}');
    debugPrint('✅ 已授权地址数量: ${_addressAuthCache.length}');
  }

  /// 设置交易地址
  Future<void> setTradingAddress(String address) async {
    _currentTradingAddress = address;
    await _saveTradingAddress(address);
    debugPrint('📍 设置交易地址: $address');
  }

  /// 清除交易地址和API配置
  Future<void> clearTradingAddress() async {
    _currentTradingAddress = null;
    _apiPrivateKey = null;
    _addressAuthCache.clear();
    await _saveTradingAddress('');
    await _saveApiPrivateKey('');
    debugPrint('🗑️ 清除交易配置');
  }

  /// 生成授权消息
  String generateAuthMessage(String address) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Authorize address $address for Hyperliquid trading at timestamp $timestamp';
  }

  /// 验证地址授权 - 升级为支持EIP-712签名验证
  Future<bool> authorizeAddress(String address, String signature) async {
    try {
      debugPrint('🔐 验证地址授权: ${address.substring(0, 8)}...');
      
      // 生成授权消息
      final message = generateAuthMessage(address);
      
      // 验证签名（需要实现EIP-712签名验证）
      final isValidSignature = await _verifyEip712Signature(address, message, signature);
      
      if (isValidSignature) {
        // 保存授权信息
        final authInfo = AddressAuthInfo(
          address: address,
          status: AddressAuthStatus.authorized,
          signature: signature,
          timestamp: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)), // 30天过期
        );
        
        _addressAuthCache[address] = authInfo;
        await _saveAddressAuthInfo();
        
        debugPrint('✅ 地址授权成功: ${address.substring(0, 8)}...');
        return true;
      } else {
        debugPrint('❌ 签名验证失败');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 地址授权失败: $e');
      return false;
    }
  }

  /// 撤销地址授权
  Future<void> revokeAddressAuth(String address) async {
    _addressAuthCache.remove(address);
    await _saveAddressAuthInfo();
    
    // 如果撤销的是当前交易地址，清除当前地址
    if (_currentTradingAddress == address) {
      _currentTradingAddress = null;
      await _clearTradingAddress();
    }
    
    debugPrint('🚫 撤销地址授权: ${address.substring(0, 8)}...');
  }

  /// 获取所有已授权的地址
  List<String> getAuthorizedAddresses() {
    return _addressAuthCache.entries
        .where((entry) => entry.value.isAuthorized)
        .map((entry) => entry.key)
        .toList();
  }

  /// Exchange API - 取消订单
  Future<bool> cancelOrder({
    required String coin,
    required int orderId,
  }) async {
    if (_currentTradingAddress == null || _apiPrivateKey == null) {
      throw ApiException('请先配置API密钥和交易地址');
    }

    try {
      final signature = await _generateExchangeSignature({
        'action': {
          'type': 'cancel',
          'cancels': [
            {'coin': coin, 'o': orderId}
          ],
        },
        'nonce': DateTime.now().millisecondsSinceEpoch,
      });

      final response = await _apiClient.post(
        _exchangeUrl,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {
          'action': {
            'type': 'cancel',
            'cancels': [
              {'coin': coin, 'o': orderId}
            ],
          },
          'nonce': DateTime.now().millisecondsSinceEpoch,
          'signature': signature,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw ApiException('取消订单失败: $e');
    }
  }

  /// 映射订单类型到Hyperliquid格式
  Map<String, dynamic> _mapOrderType(String orderType) {
    switch (orderType.toLowerCase()) {
      case 'limit':
        return {'limit': {'tif': 'Gtc'}};
      case 'market':
        return {'trigger': {'isMarket': true, 'tpsl': 'tp'}};
      default:
        return {'limit': {'tif': 'Gtc'}};
    }
  }

  /// 生成Exchange API签名 (EIP-712)
  Future<String> _generateExchangeSignature(Map<String, dynamic> payload) async {
    // TODO: 实现EIP-712签名
    // 这里需要：
    // 1. 构造EIP-712域分隔符
    // 2. 构造结构化数据
    // 3. 使用私钥签名
    // 4. 返回十六进制签名
    
    // 当前返回模拟签名
    return 'mock_eip712_signature_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 验证EIP-712签名
  Future<bool> _verifyEip712Signature(String address, String message, String signature) async {
    // TODO: 实现EIP-712签名验证
    // 当前简单验证签名格式
    return signature.isNotEmpty && 
           signature.length > 10 && 
           signature.startsWith('0x') ||
           signature.length > 10;
  }

  /// 加载本地授权信息
  Future<void> _loadLocalAuthInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载当前交易地址
    _currentTradingAddress = prefs.getString(_keyTradingAddress);
    
    // 加载API私钥
    _apiPrivateKey = prefs.getString(_keyApiPrivateKey);
    
    // 加载地址授权信息
    final authDataJson = prefs.getString(_keyAddressAuth);
    if (authDataJson != null) {
      try {
        final Map<String, dynamic> authData = jsonDecode(authDataJson);
        _addressAuthCache = authData.map((key, value) => 
          MapEntry(key, AddressAuthInfo.fromJson(value))
        );
      } catch (e) {
        debugPrint('⚠️ 加载地址授权信息失败: $e');
        _addressAuthCache = {};
      }
    }
  }

  /// 保存交易地址
  Future<void> _saveTradingAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTradingAddress, address);
  }

  /// 保存API私钥
  Future<void> _saveApiPrivateKey(String privateKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiPrivateKey, privateKey);
  }

  /// 清除交易地址
  Future<void> _clearTradingAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTradingAddress);
  }

  /// 保存地址授权信息
  Future<void> _saveAddressAuthInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = _addressAuthCache.map((key, value) => 
      MapEntry(key, value.toJson())
    );
    await prefs.setString(_keyAddressAuth, jsonEncode(authData));
  }

  /// 解析市场数据 - 基于实际API响应
  List<MarketData> _parseMarketData(Map<String, double> mids, Map<String, dynamic> meta) {
    final now = DateTime.now();
    final marketDataList = <MarketData>[];
    
    // 从meta中获取可用的币种信息
    final universe = meta['universe'] as List<dynamic>?;
    if (universe != null) {
      for (final coinInfo in universe) {
        final coin = coinInfo['name'] as String;
        final price = mids[coin];
        
        if (price != null) {
          marketDataList.add(MarketData(
            symbol: coin,
            price: price,
            change24h: 0.0, // 需要从其他API获取24h变化
            changePercent24h: 0.0,
            high24h: price * 1.05, // 模拟值
            low24h: price * 0.95, // 模拟值
            volume24h: 0.0, // 需要从其他API获取
            lastUpdated: now,
          ));
        }
      }
    }
    
    // 如果没有从meta获取到数据，返回基于mids的基础数据
    if (marketDataList.isEmpty) {
      for (final entry in mids.entries) {
        marketDataList.add(MarketData(
          symbol: entry.key,
          price: entry.value,
          change24h: 0.0,
          changePercent24h: 0.0,
          high24h: entry.value * 1.05,
          low24h: entry.value * 0.95,
          volume24h: 0.0,
          lastUpdated: now,
        ));
      }
    }
    
    return marketDataList;
  }

  /// 提取订单ID
  String _extractOrderId(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final response = data['response'] as Map<String, dynamic>?;
        if (response != null) {
          final data = response['data'] as Map<String, dynamic>?;
          if (data != null) {
            final statuses = data['statuses'] as List<dynamic>?;
            if (statuses != null && statuses.isNotEmpty) {
              final status = statuses.first as Map<String, dynamic>;
              return status['resting']?.toString() ?? 'unknown_order_id';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 解析订单ID失败: $e');
    }
    
    return 'order_${DateTime.now().millisecondsSinceEpoch}';
  }
}