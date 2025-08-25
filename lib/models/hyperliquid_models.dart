/// 订单类型枚举
enum OrderType {
  market('市价单', 'market'),
  limit('限价单', 'limit'),
  stopMarket('止损市价单', 'stop_market'),
  stopLimit('止损限价单', 'stop_limit');

  const OrderType(this.displayName, this.value);
  final String displayName;
  final String value;

  static OrderType fromValue(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => OrderType.limit,
    );
  }
}

/// 订单方向枚举
enum OrderSide {
  buy('买入', 'buy'),
  sell('卖出', 'sell');

  const OrderSide(this.displayName, this.value);
  final String displayName;
  final String value;

  static OrderSide fromValue(String value) {
    return values.firstWhere(
      (side) => side.value == value,
      orElse: () => OrderSide.buy,
    );
  }

  bool get isBuy => this == OrderSide.buy;
  bool get isSell => this == OrderSide.sell;
}

/// 订单状态枚举
enum OrderStatus {
  pending('待成交', 'pending'),
  partiallyFilled('部分成交', 'partially_filled'),
  filled('已成交', 'filled'),
  cancelled('已取消', 'cancelled'),
  rejected('已拒绝', 'rejected'),
  expired('已过期', 'expired');

  const OrderStatus(this.displayName, this.value);
  final String displayName;
  final String value;

  static OrderStatus fromValue(String value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  bool get isActive => this == OrderStatus.pending || this == OrderStatus.partiallyFilled;
  bool get isCompleted => this == OrderStatus.filled || this == OrderStatus.cancelled;
}

/// 时效类型枚举  
enum TimeInForce {
  gtc('撤单前有效', 'GTC'),
  ioc('立即成交或取消', 'IOC'),
  fok('全额成交或取消', 'FOK');

  const TimeInForce(this.displayName, this.value);
  final String displayName;
  final String value;

  static TimeInForce fromValue(String value) {
    return values.firstWhere(
      (tif) => tif.value == value,
      orElse: () => TimeInForce.gtc,
    );
  }
}

/// 订单模型
class HyperliquidOrder {
  final String? orderId;
  final String symbol;
  final OrderType type;
  final OrderSide side;
  final double size;
  final double? price;
  final double? stopPrice;
  final TimeInForce timeInForce;
  final bool reduceOnly;
  final OrderStatus status;
  final double filledSize;
  final double averagePrice;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? clientOrderId;
  final String address;
  final double? pnl; // 添加盈亏字段用于测试

  HyperliquidOrder({
    this.orderId,
    required this.symbol,
    required this.type,
    required this.side,
    required this.size,
    this.price,
    this.stopPrice,
    this.timeInForce = TimeInForce.gtc,
    this.reduceOnly = false,
    this.status = OrderStatus.pending,
    this.filledSize = 0.0,
    this.averagePrice = 0.0,
    required this.createdAt,
    this.updatedAt,
    this.clientOrderId,
    required this.address,
    this.pnl,
  });

  /// 剩余数量
  double get remainingSize => size - filledSize;

  /// 填充百分比
  double get fillPercentage => size > 0 ? (filledSize / size) * 100 : 0;

  /// 是否可以取消
  bool get canCancel => status.isActive;

  /// 订单总价值
  double get totalValue {
    if (type == OrderType.market) {
      return averagePrice * filledSize;
    }
    return (price ?? 0) * size;
  }

  /// 显示价格
  String get displayPrice {
    if (type == OrderType.market) {
      return '市价';
    }
    return price?.toStringAsFixed(4) ?? '-';
  }

  factory HyperliquidOrder.fromJson(Map<String, dynamic> json) {
    return HyperliquidOrder(
      orderId: json['order_id'] as String?,
      symbol: json['symbol'] as String,
      type: OrderType.fromValue(json['type'] as String),
      side: OrderSide.fromValue(json['side'] as String),
      size: (json['size'] as num).toDouble(),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      stopPrice: json['stop_price'] != null ? (json['stop_price'] as num).toDouble() : null,
      timeInForce: TimeInForce.fromValue(json['time_in_force'] as String? ?? 'GTC'),
      reduceOnly: json['reduce_only'] as bool? ?? false,
      status: OrderStatus.fromValue(json['status'] as String),
      filledSize: (json['filled_size'] as num? ?? 0).toDouble(),
      averagePrice: (json['average_price'] as num? ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      clientOrderId: json['client_order_id'] as String?,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (orderId != null) 'order_id': orderId,
      'symbol': symbol,
      'type': type.value,
      'side': side.value,
      'size': size,
      if (price != null) 'price': price,
      if (stopPrice != null) 'stop_price': stopPrice,
      'time_in_force': timeInForce.value,
      'reduce_only': reduceOnly,
      'status': status.value,
      'filled_size': filledSize,
      'average_price': averagePrice,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (clientOrderId != null) 'client_order_id': clientOrderId,
      'address': address,
    };
  }

  HyperliquidOrder copyWith({
    String? orderId,
    String? symbol,
    OrderType? type,
    OrderSide? side,
    double? size,
    double? price,
    double? stopPrice,
    TimeInForce? timeInForce,
    bool? reduceOnly,
    OrderStatus? status,
    double? filledSize,
    double? averagePrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientOrderId,
    String? address,
    double? pnl,
  }) {
    return HyperliquidOrder(
      orderId: orderId ?? this.orderId,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      side: side ?? this.side,
      size: size ?? this.size,
      price: price ?? this.price,
      stopPrice: stopPrice ?? this.stopPrice,
      timeInForce: timeInForce ?? this.timeInForce,
      reduceOnly: reduceOnly ?? this.reduceOnly,
      status: status ?? this.status,
      filledSize: filledSize ?? this.filledSize,
      averagePrice: averagePrice ?? this.averagePrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientOrderId: clientOrderId ?? this.clientOrderId,
      address: address ?? this.address,
      pnl: pnl ?? this.pnl,
    );
  }

  @override
  String toString() {
    return 'HyperliquidOrder(${side.displayName} ${size} ${symbol} @ ${displayPrice}, ${status.displayName})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HyperliquidOrder &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId;

  @override
  int get hashCode => orderId?.hashCode ?? super.hashCode;
}

/// 持仓模型
class Position {
  final String symbol;
  final double size;
  final double entryPrice;
  final double markPrice;
  final double unrealizedPnl;
  final double realizedPnl;
  final double margin;
  final double marginRatio;
  final DateTime updatedAt;
  final String address;

  Position({
    required this.symbol,
    required this.size,
    required this.entryPrice,
    required this.markPrice,
    required this.unrealizedPnl,
    required this.realizedPnl,
    required this.margin,
    required this.marginRatio,
    required this.updatedAt,
    required this.address,
  });

  /// 是否是多头持仓
  bool get isLong => size > 0;
  
  /// 是否是空头持仓
  bool get isShort => size < 0;

  /// 持仓方向文字
  String get sideText => isLong ? '多头' : '空头';

  /// 持仓价值
  double get notionalValue => size.abs() * markPrice;

  /// 盈亏百分比
  double get pnlPercentage {
    if (entryPrice == 0) return 0;
    return ((markPrice - entryPrice) / entryPrice) * 100 * (isLong ? 1 : -1);
  }

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      symbol: json['symbol'] as String,
      size: (json['size'] as num).toDouble(),
      entryPrice: (json['entry_price'] as num).toDouble(),
      markPrice: (json['mark_price'] as num).toDouble(),
      unrealizedPnl: (json['unrealized_pnl'] as num).toDouble(),
      realizedPnl: (json['realized_pnl'] as num? ?? 0).toDouble(),
      margin: (json['margin'] as num).toDouble(),
      marginRatio: (json['margin_ratio'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'size': size,
      'entry_price': entryPrice,
      'mark_price': markPrice,
      'unrealized_pnl': unrealizedPnl,
      'realized_pnl': realizedPnl,
      'margin': margin,
      'margin_ratio': marginRatio,
      'updated_at': updatedAt.toIso8601String(),
      'address': address,
    };
  }

  @override
  String toString() {
    return 'Position($sideText ${size.abs()} $symbol, PnL: ${unrealizedPnl.toStringAsFixed(2)})';
  }
}