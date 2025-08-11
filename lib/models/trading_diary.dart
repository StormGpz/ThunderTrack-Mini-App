import 'package:json_annotation/json_annotation.dart';
import 'trade.dart';

part 'trading_diary.g.dart';

/// 交易日记数据模型
@JsonSerializable()
class TradingDiary {
  /// 日记唯一标识
  final String id;
  
  /// 作者Farcaster ID
  final String authorFid;
  
  /// 日记标题
  final String title;
  
  /// 日记内容
  final String content;
  
  /// 日记分类
  final String category;
  
  /// 相关标签
  final List<String> tags;
  
  /// 图片URL列表
  final List<String> imageUrls;
  
  /// 关联的交易列表
  final List<Trade> trades;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime? updatedAt;
  
  /// 点赞数
  final int likes;
  
  /// 评论数
  final int comments;
  
  /// 转发数
  final int reposts;
  
  /// 是否公开
  final bool isPublic;
  
  /// IPFS哈希值
  final String? ipfsHash;
  
  /// 心得总结
  final String? summary;
  
  /// 交易表现评分 (1-5)
  final double? rating;

  const TradingDiary({
    required this.id,
    required this.authorFid,
    required this.title,
    required this.content,
    required this.category,
    this.tags = const [],
    this.imageUrls = const [],
    this.trades = const [],
    required this.createdAt,
    this.updatedAt,
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.isPublic = true,
    this.ipfsHash,
    this.summary,
    this.rating,
  });

  factory TradingDiary.fromJson(Map<String, dynamic> json) => _$TradingDiaryFromJson(json);
  
  Map<String, dynamic> toJson() => _$TradingDiaryToJson(this);

  /// 复制对象并更新部分字段
  TradingDiary copyWith({
    String? id,
    String? authorFid,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    List<String>? imageUrls,
    List<Trade>? trades,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    int? comments,
    int? reposts,
    bool? isPublic,
    String? ipfsHash,
    String? summary,
    double? rating,
  }) {
    return TradingDiary(
      id: id ?? this.id,
      authorFid: authorFid ?? this.authorFid,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      trades: trades ?? this.trades,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      reposts: reposts ?? this.reposts,
      isPublic: isPublic ?? this.isPublic,
      ipfsHash: ipfsHash ?? this.ipfsHash,
      summary: summary ?? this.summary,
      rating: rating ?? this.rating,
    );
  }

  /// 获取总交易价值
  double get totalTradeValue {
    return trades.fold(0.0, (sum, trade) => sum + trade.notionalValue);
  }

  /// 获取总盈亏
  double get totalPnl {
    return trades.fold(0.0, (sum, trade) => sum + (trade.pnl ?? 0.0));
  }

  /// 是否包含交易
  bool get hasTrades => trades.isNotEmpty;

  /// 获取主要交易对
  String? get primarySymbol {
    if (trades.isEmpty) return null;
    // 返回交易量最大的交易对
    final symbolGroups = <String, double>{};
    for (final trade in trades) {
      symbolGroups[trade.symbol] = (symbolGroups[trade.symbol] ?? 0) + trade.notionalValue;
    }
    return symbolGroups.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradingDiary && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TradingDiary(id: $id, title: $title, author: $authorFid)';
}