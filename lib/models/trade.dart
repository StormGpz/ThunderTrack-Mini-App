import 'package:json_annotation/json_annotation.dart';

part 'trade.g.dart';

/// 交易数据模型
@JsonSerializable()
class Trade {
  /// 交易唯一标识
  final String id;
  
  /// 交易对符号
  final String symbol;
  
  /// 交易价格
  final double price;
  
  /// 交易数量
  final double size;
  
  /// 交易方向 (buy/sell)
  final String side;
  
  /// 订单类型 (market/limit)
  final String orderType;
  
  /// 交易状态 (pending/filled/cancelled)
  final String status;
  
  /// 交易时间
  final DateTime timestamp;
  
  /// 用户FID (交易者)
  final String userFid;
  
  /// 手续费
  final double? fee;
  
  /// 盈亏
  final double? pnl;
  
  /// 是否为开仓交易
  final bool isOpen;
  
  /// 关联的日记ID (可选)
  final String? diaryId;

  const Trade({
    required this.id,
    required this.symbol,
    required this.price,
    required this.size,
    required this.side,
    required this.orderType,
    required this.status,
    required this.timestamp,
    required this.userFid,
    this.fee,
    this.pnl,
    this.isOpen = true,
    this.diaryId,
  });

  factory Trade.fromJson(Map<String, dynamic> json) => _$TradeFromJson(json);
  
  Map<String, dynamic> toJson() => _$TradeToJson(this);

  /// 复制对象并更新部分字段
  Trade copyWith({
    String? id,
    String? symbol,
    double? price,
    double? size,
    String? side,
    String? orderType,
    String? status,
    DateTime? timestamp,
    String? userFid,
    double? fee,
    double? pnl,
    bool? isOpen,
    String? diaryId,
  }) {
    return Trade(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      size: size ?? this.size,
      side: side ?? this.side,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      userFid: userFid ?? this.userFid,
      fee: fee ?? this.fee,
      pnl: pnl ?? this.pnl,
      isOpen: isOpen ?? this.isOpen,
      diaryId: diaryId ?? this.diaryId,
    );
  }

  /// 计算交易价值
  double get notionalValue => price * size;

  /// 是否为买入交易
  bool get isBuy => side.toLowerCase() == 'buy';

  /// 是否为卖出交易
  bool get isSell => side.toLowerCase() == 'sell';

  /// 是否为已完成交易
  bool get isFilled => status.toLowerCase() == 'filled';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trade && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Trade(id: $id, symbol: $symbol, side: $side, price: $price)';
}