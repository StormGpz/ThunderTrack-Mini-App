import '../models/market_data.dart';
import '../models/address_auth.dart';
import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import '../utils/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Hyperliquid API服务
class HyperliquidService {
  static final HyperliquidService _instance = HyperliquidService._internal();
  factory HyperliquidService() => _instance;
  HyperliquidService._internal();

  final ApiClient _apiClient = ApiClient();

  // 地址授权管理
  String? _currentTradingAddress;
  Map<String, AddressAuthInfo> _addressAuthCache = {};
  
  static const String _keyTradingAddress = 'hyperliquid_trading_address';
  static const String _keyAddressAuth = 'hyperliquid_address_auth';

  /// 当前交易地址
  String? get currentTradingAddress => _currentTradingAddress;
  
  /// 检查地址是否已授权
  bool isAddressAuthorized(String address) {
    return _addressAuthCache[address]?.isAuthorized == true;
  }

  /// 获取地址授权状态
  AddressAuthStatus getAddressAuthStatus(String address) {
    return _addressAuthCache[address]?.status ?? AddressAuthStatus.unselected;
  }

  /// 获取用户账户状态
  Future<Map<String, dynamic>> getUserState(String address) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.hyperliquidUserState,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {
          'type': 'clearinghouseState',
          'user': address,
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

  /// 获取所有交易对的中间价
  Future<Map<String, double>> getAllMids() async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.hyperliquidAllMids,
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

  /// 获取市场数据
  Future<List<MarketData>> getMarketData() async {
    try {
      // 这里应该调用真实的Hyperliquid API
      // 由于API文档限制，这里提供基础框架
      final response = await _apiClient.post(
        ApiEndpoints.hyperliquidInfo,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {'type': 'meta'},
      );

      if (response.statusCode == 200 && response.data != null) {
        // 解析市场数据
        // 这里需要根据实际API响应格式进行调整
        return _parseMarketData(response.data);
      }
      throw ApiException('获取市场数据失败');
    } catch (e) {
      throw ApiException('获取市场数据失败: $e');
    }
  }

  /// 下单
  Future<String> placeOrder({
    required String symbol,
    required double size,
    required String side,
    required String orderType,
    double? price,
    String? timeInForce,
  }) async {
    // 检查当前交易地址是否已授权
    if (_currentTradingAddress == null) {
      throw ApiException('请先选择交易地址');
    }
    
    if (!isAddressAuthorized(_currentTradingAddress!)) {
      throw ApiException('当前地址未授权，请先完成授权');
    }

    try {
      final orderData = {
        'coin': symbol,
        'is_buy': side.toLowerCase() == 'buy',
        'sz': size,
        'limit_px': price ?? 0,
        'order_type': orderType,
        'reduce_only': false,
      };

      // 生成签名
      final signature = await _generateOrderSignature(orderData, _currentTradingAddress!);

      final response = await _apiClient.post(
        ApiEndpoints.hyperliquidOrder,
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
        // 解析订单响应，返回订单ID
        return _extractOrderId(response.data);
      }
      throw ApiException('下单失败');
    } catch (e) {
      throw ApiException('下单失败: $e');
    }
  }

  /// 初始化服务（加载本地授权信息）
  Future<void> initialize() async {
    await _loadLocalAuthInfo();
    debugPrint('🚀 HyperliquidService 初始化完成');
    debugPrint('📍 当前交易地址: ${_currentTradingAddress ?? "未设置"}');
    debugPrint('🔐 已授权地址数量: ${_addressAuthCache.length}');
  }

  /// 设置交易地址
  Future<void> setTradingAddress(String address) async {
    _currentTradingAddress = address;
    await _saveTradingAddress(address);
    debugPrint('📍 设置交易地址: $address');
  }

  /// 清除交易地址
  Future<void> clearTradingAddress() async {
    _currentTradingAddress = null;
    _addressAuthCache.clear();
    await _saveTradingAddress('');
    debugPrint('🗑️ 清除交易地址');
  }

  /// 生成授权消息
  String generateAuthMessage(String address) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Authorize address $address for Hyperliquid trading at timestamp $timestamp';
  }

  /// 验证地址授权
  Future<bool> authorizeAddress(String address, String signature) async {
    try {
      debugPrint('🔐 验证地址授权: ${address.substring(0, 8)}...');
      
      // 生成授权消息
      final message = generateAuthMessage(address);
      
      // 验证签名（这里需要根据实际签名验证逻辑实现）
      final isValidSignature = await _verifySignature(address, message, signature);
      
      if (isValidSignature) {
        // 保存授权信息
        final authInfo = AddressAuthInfo(
          address: address,
          status: AddressAuthStatus.authorized,
          signature: signature,
          timestamp: DateTime.now(),
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

  /// 生成订单签名
  Future<String> _generateOrderSignature(Map<String, dynamic> orderData, String address) async {
    // 这里需要实现实际的签名逻辑
    // 目前返回模拟签名，实际需要调用钱包签名
    final authInfo = _addressAuthCache[address];
    if (authInfo != null) {
      return authInfo.signature; // 使用授权时的签名作为基础
    }
    return 'mock_signature_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 验证签名
  Future<bool> _verifySignature(String address, String message, String signature) async {
    // 这里需要实现实际的签名验证逻辑
    // 目前简单验证签名不为空
    return signature.isNotEmpty && signature.length > 10;
  }

  /// 加载本地授权信息
  Future<void> _loadLocalAuthInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载当前交易地址
    _currentTradingAddress = prefs.getString(_keyTradingAddress);
    
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

  /// 取消订单
  Future<bool> cancelOrder(String orderId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.hyperliquidCancel,
        baseUrl: AppConfig.hyperliquidBaseUrl,
        data: {
          'action': {
            'type': 'cancel',
            'cancels': [
              {'coin': '', 'o': orderId} // 需要提供完整的取消信息
            ],
          },
          'nonce': DateTime.now().millisecondsSinceEpoch,
          'signature': '', // 需要实现签名逻辑
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw ApiException('取消订单失败: $e');
    }
  }

  /// 解析市场数据
  List<MarketData> _parseMarketData(dynamic data) {
    // 这里需要根据实际API响应格式实现解析逻辑
    // 当前返回模拟数据
    final now = DateTime.now();
    return [
      MarketData(
        symbol: 'ETH',
        price: 3500.0,
        change24h: 150.0,
        changePercent24h: 4.47,
        high24h: 3600.0,
        low24h: 3300.0,
        volume24h: 1500000.0,
        lastUpdated: now,
      ),
      MarketData(
        symbol: 'BTC',
        price: 65000.0,
        change24h: -1200.0,
        changePercent24h: -1.81,
        high24h: 66500.0,
        low24h: 64000.0,
        volume24h: 800000.0,
        lastUpdated: now,
      ),
    ];
  }

  /// 提取订单ID
  String _extractOrderId(dynamic data) {
    // 这里需要根据实际API响应格式实现
    return 'order_${DateTime.now().millisecondsSinceEpoch}';
  }
}