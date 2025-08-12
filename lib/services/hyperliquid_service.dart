import '../models/market_data.dart';
import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import '../utils/api_client.dart';

/// Hyperliquid API服务
class HyperliquidService {
  static final HyperliquidService _instance = HyperliquidService._internal();
  factory HyperliquidService() => _instance;
  HyperliquidService._internal();

  final ApiClient _apiClient = ApiClient();

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
    try {
      final orderData = {
        'coin': symbol,
        'is_buy': side.toLowerCase() == 'buy',
        'sz': size,
        'limit_px': price ?? 0,
        'order_type': orderType,
        'reduce_only': false,
      };

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
          'signature': '', // 需要实现签名逻辑
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