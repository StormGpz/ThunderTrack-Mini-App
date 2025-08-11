import 'package:json_annotation/json_annotation.dart';

part 'market_data.g.dart';

/// 市场数据模型
@JsonSerializable()
class MarketData {
  /// 交易对符号
  final String symbol;
  
  /// 当前价格
  final double price;
  
  /// 24小时变化
  final double change24h;
  
  /// 24小时变化百分比
  final double changePercent24h;
  
  /// 24小时最高价
  final double high24h;
  
  /// 24小时最低价
  final double low24h;
  
  /// 24小时交易量
  final double volume24h;
  
  /// 买一价
  final double? bidPrice;
  
  /// 卖一价
  final double? askPrice;
  
  /// 最后更新时间
  final DateTime lastUpdated;

  const MarketData({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    this.bidPrice,
    this.askPrice,
    required this.lastUpdated,
  });

  factory MarketData.fromJson(Map<String, dynamic> json) => _$MarketDataFromJson(json);
  
  Map<String, dynamic> toJson() => _$MarketDataToJson(this);

  /// 是否上涨
  bool get isPositive => change24h > 0;

  /// 是否下跌
  bool get isNegative => change24h < 0;

  /// 获取格式化的价格字符串
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// 获取格式化的变化百分比
  String get formattedChangePercent => '${changePercent24h >= 0 ? '+' : ''}${changePercent24h.toStringAsFixed(2)}%';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketData && runtimeType == other.runtimeType && symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() => 'MarketData(symbol: $symbol, price: $price)';
}