/// 交易对模型
class TradingPair {
  /// 交易对符号 (如: BTC/USDT)
  final String symbol;
  
  /// 基础资产 (如: BTC)
  final String baseAsset;
  
  /// 报价资产 (如: USDT)
  final String quoteAsset;
  
  /// 当前价格
  final double currentPrice;
  
  /// 24小时价格变化百分比
  final double priceChangePercent;
  
  /// 24小时价格变化值
  final double priceChange;
  
  /// 24小时最高价
  final double highPrice24h;
  
  /// 24小时最低价
  final double lowPrice24h;
  
  /// 24小时成交量
  final double volume24h;
  
  /// 是否已关注
  final bool isFavorite;
  
  /// 最后更新时间
  final DateTime lastUpdated;

  const TradingPair({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.currentPrice,
    required this.priceChangePercent,
    required this.priceChange,
    required this.highPrice24h,
    required this.lowPrice24h,
    required this.volume24h,
    this.isFavorite = false,
    required this.lastUpdated,
  });

  /// 创建副本并更新部分字段
  TradingPair copyWith({
    String? symbol,
    String? baseAsset,
    String? quoteAsset,
    double? currentPrice,
    double? priceChangePercent,
    double? priceChange,
    double? highPrice24h,
    double? lowPrice24h,
    double? volume24h,
    bool? isFavorite,
    DateTime? lastUpdated,
  }) {
    return TradingPair(
      symbol: symbol ?? this.symbol,
      baseAsset: baseAsset ?? this.baseAsset,
      quoteAsset: quoteAsset ?? this.quoteAsset,
      currentPrice: currentPrice ?? this.currentPrice,
      priceChangePercent: priceChangePercent ?? this.priceChangePercent,
      priceChange: priceChange ?? this.priceChange,
      highPrice24h: highPrice24h ?? this.highPrice24h,
      lowPrice24h: lowPrice24h ?? this.lowPrice24h,
      volume24h: volume24h ?? this.volume24h,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 价格是否上涨
  bool get isPriceUp => priceChangePercent > 0;
  
  /// 价格是否下跌
  bool get isPriceDown => priceChangePercent < 0;

  /// 格式化价格显示
  String get formattedPrice {
    if (currentPrice >= 1000) {
      return currentPrice.toStringAsFixed(0);
    } else if (currentPrice >= 1) {
      return currentPrice.toStringAsFixed(2);
    } else {
      return currentPrice.toStringAsFixed(6);
    }
  }

  /// 格式化价格变化百分比
  String get formattedPriceChangePercent {
    final sign = priceChangePercent >= 0 ? '+' : '';
    return '$sign${priceChangePercent.toStringAsFixed(2)}%';
  }

  /// 格式化成交量
  String get formattedVolume {
    if (volume24h >= 1000000) {
      return '${(volume24h / 1000000).toStringAsFixed(1)}M';
    } else if (volume24h >= 1000) {
      return '${(volume24h / 1000).toStringAsFixed(1)}K';
    } else {
      return volume24h.toStringAsFixed(2);
    }
  }

  @override
  String toString() => 'TradingPair(symbol: $symbol, price: $currentPrice, change: $priceChangePercent%)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradingPair && runtimeType == other.runtimeType && symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;

  /// 创建模拟数据
  static List<TradingPair> getMockData() {
    final now = DateTime.now();
    return [
      TradingPair(
        symbol: 'BTC/USDT',
        baseAsset: 'BTC',
        quoteAsset: 'USDT',
        currentPrice: 65234.50,
        priceChangePercent: 2.45,
        priceChange: 1556.30,
        highPrice24h: 66000.00,
        lowPrice24h: 63500.00,
        volume24h: 45678900,
        isFavorite: true,
        lastUpdated: now,
      ),
      TradingPair(
        symbol: 'ETH/USDT',
        baseAsset: 'ETH',
        quoteAsset: 'USDT',
        currentPrice: 2845.75,
        priceChangePercent: -1.32,
        priceChange: -38.09,
        highPrice24h: 2890.00,
        lowPrice24h: 2820.00,
        volume24h: 23456780,
        isFavorite: true,
        lastUpdated: now,
      ),
      TradingPair(
        symbol: 'SOL/USDT',
        baseAsset: 'SOL',
        quoteAsset: 'USDT',
        currentPrice: 156.89,
        priceChangePercent: 5.67,
        priceChange: 8.42,
        highPrice24h: 160.50,
        lowPrice24h: 148.20,
        volume24h: 12345600,
        lastUpdated: now,
      ),
      TradingPair(
        symbol: 'AVAX/USDT',
        baseAsset: 'AVAX',
        quoteAsset: 'USDT',
        currentPrice: 34.56,
        priceChangePercent: -3.21,
        priceChange: -1.15,
        highPrice24h: 36.80,
        lowPrice24h: 33.90,
        volume24h: 8765432,
        lastUpdated: now,
      ),
      TradingPair(
        symbol: 'ARB/USDT',
        baseAsset: 'ARB',
        quoteAsset: 'USDT',
        currentPrice: 0.8234,
        priceChangePercent: 1.89,
        priceChange: 0.0153,
        highPrice24h: 0.8456,
        lowPrice24h: 0.8001,
        volume24h: 5432100,
        lastUpdated: now,
      ),
      TradingPair(
        symbol: 'MATIC/USDT',
        baseAsset: 'MATIC',
        quoteAsset: 'USDT',
        currentPrice: 0.4567,
        priceChangePercent: -2.45,
        priceChange: -0.0115,
        highPrice24h: 0.4789,
        lowPrice24h: 0.4434,
        volume24h: 3210987,
        lastUpdated: now,
      ),
    ];
  }
}