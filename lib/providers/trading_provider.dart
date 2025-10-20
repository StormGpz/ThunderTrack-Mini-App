import 'package:flutter/foundation.dart';
import '../models/trade.dart';
import '../models/market_data.dart';

/// 交易状态管理Provider
class TradingProvider extends ChangeNotifier {
  static final TradingProvider _instance = TradingProvider._internal();
  factory TradingProvider() => _instance;
  TradingProvider._internal();

  List<MarketData> _marketData = [];
  List<Trade> _userTrades = [];
  List<Trade> _activeTrades = [];
  Map<String, double> _positions = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<MarketData> get marketData => _marketData;
  List<Trade> get userTrades => _userTrades;
  List<Trade> get activeTrades => _activeTrades;
  Map<String, double> get positions => _positions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初始化交易数据
  Future<void> initialize() async {
    await Future.wait([
      loadMarketData(),
      // loadUserTrades(), // 需要用户登录后才能加载
    ]);
  }

  /// 加载市场数据
  Future<void> loadMarketData() async {
    _setLoading(true);
    try {
      // TODO: 实现市场数据加载
      // 暂时使用空数据
      _marketData = [];
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('加载市场数据失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载用户交易记录
  Future<void> loadUserTrades(String userAddress) async {
    _setLoading(true);
    try {
      // TODO: 实现用户交易加载
      // 暂时使用空数据
      _parseUserTrades({});
      _parseUserPositions({});

      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('加载用户交易失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 下单
  Future<bool> placeOrder({
    required String symbol,
    required double size,
    required String side,
    required String orderType,
    double? price,
  }) async {
    try {
      // TODO: 实现下单功能
      debugPrint('📋 模拟下单: $symbol $size $side');

      // 创建交易记录
      final trade = Trade(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        symbol: symbol,
        price: price ?? _getMarketPrice(symbol),
        size: size,
        side: side,
        orderType: orderType,
        status: 'pending',
        timestamp: DateTime.now(),
        userFid: '', // 从用户Provider获取
      );

      _activeTrades.add(trade);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('下单失败: $e');
      return false;
    }
  }

  /// 取消订单
  Future<bool> cancelOrder(String orderId, {String? coin}) async {
    try {
      // TODO: 实现取消订单功能
      debugPrint('📋 模拟取消订单: $orderId');

      _activeTrades.removeWhere((trade) => trade.id == orderId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('取消订单失败: $e');
      return false;
    }
  }

  /// 获取特定交易对的市场数据
  MarketData? getMarketDataBySymbol(String symbol) {
    try {
      return _marketData.firstWhere((data) => data.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  /// 获取用户特定交易对的持仓
  double getPositionBySymbol(String symbol) {
    return _positions[symbol] ?? 0.0;
  }

  /// 获取总持仓价值
  double get totalPortfolioValue {
    double total = 0.0;
    for (final entry in _positions.entries) {
      final marketData = getMarketDataBySymbol(entry.key);
      if (marketData != null) {
        total += entry.value * marketData.price;
      }
    }
    return total;
  }

  /// 获取今日盈亏
  double get todayPnl {
    double pnl = 0.0;
    final today = DateTime.now();
    
    for (final trade in _userTrades) {
      if (trade.timestamp.year == today.year &&
          trade.timestamp.month == today.month &&
          trade.timestamp.day == today.day) {
        pnl += trade.pnl ?? 0.0;
      }
    }
    return pnl;
  }

  /// 刷新所有数据
  Future<void> refreshAll({String? userAddress}) async {
    await Future.wait([
      loadMarketData(),
      if (userAddress != null) loadUserTrades(userAddress),
    ]);
  }

  /// 解析用户交易记录
  void _parseUserTrades(Map<String, dynamic> userState) {
    // 这里需要根据Hyperliquid API的实际响应格式实现解析
    _userTrades = [];
    _activeTrades = [];
  }

  /// 解析用户持仓
  void _parseUserPositions(Map<String, dynamic> userState) {
    // 这里需要根据Hyperliquid API的实际响应格式实现解析
    _positions = {};
  }

  /// 获取市场价格
  double _getMarketPrice(String symbol) {
    final marketData = getMarketDataBySymbol(symbol);
    return marketData?.price ?? 0.0;
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }
}