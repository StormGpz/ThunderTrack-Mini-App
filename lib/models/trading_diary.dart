import 'package:json_annotation/json_annotation.dart';

part 'trading_diary.g.dart';

/// 日记类型枚举
enum DiaryType {
  @JsonValue('single_trade')
  singleTrade,
  
  @JsonValue('strategy_summary')
  strategySummary,
  
  @JsonValue('free_form')
  freeForm,
}

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
  
  /// 日记类型
  final DiaryType type;
  
  /// 关联的交易ID列表
  final List<String> tradeIds;
  
  /// 主要交易币种
  final String? symbol;
  
  /// 时间范围开始
  final DateTime? periodStart;
  
  /// 时间范围结束
  final DateTime? periodEnd;
  
  /// 相关标签
  final List<String> tags;
  
  /// 图片URL列表
  final List<String> imageUrls;
  
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
  
  /// Farcaster发布数据
  final Map<String, dynamic>? farcasterPost;

  const TradingDiary({
    required this.id,
    required this.authorFid,
    required this.title,
    required this.content,
    required this.type,
    this.tradeIds = const [],
    this.symbol,
    this.periodStart,
    this.periodEnd,
    this.tags = const [],
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.isPublic = true,
    this.ipfsHash,
    this.summary,
    this.rating,
    this.farcasterPost,
  });

  factory TradingDiary.fromJson(Map<String, dynamic> json) => _$TradingDiaryFromJson(json);
  
  Map<String, dynamic> toJson() => _$TradingDiaryToJson(this);

  /// 复制对象并更新部分字段
  TradingDiary copyWith({
    String? id,
    String? authorFid,
    String? title,
    String? content,
    DiaryType? type,
    List<String>? tradeIds,
    String? symbol,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<String>? tags,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    int? comments,
    int? reposts,
    bool? isPublic,
    String? ipfsHash,
    String? summary,
    double? rating,
    Map<String, dynamic>? farcasterPost,
  }) {
    return TradingDiary(
      id: id ?? this.id,
      authorFid: authorFid ?? this.authorFid,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      tradeIds: tradeIds ?? this.tradeIds,
      symbol: symbol ?? this.symbol,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      reposts: reposts ?? this.reposts,
      isPublic: isPublic ?? this.isPublic,
      ipfsHash: ipfsHash ?? this.ipfsHash,
      summary: summary ?? this.summary,
      rating: rating ?? this.rating,
      farcasterPost: farcasterPost ?? this.farcasterPost,
    );
  }

  /// 获取日记类型显示名称
  String get typeDisplayName {
    switch (type) {
      case DiaryType.singleTrade:
        return '单笔复盘';
      case DiaryType.strategySummary:
        return '策略总结';
      case DiaryType.freeForm:
        return '自由记录';
    }
  }

  /// 获取时间范围描述
  String? get periodDescription {
    if (periodStart == null) return null;
    if (periodEnd == null) return periodStart!.toString().split(' ')[0];
    
    final start = periodStart!.toString().split(' ')[0];
    final end = periodEnd!.toString().split(' ')[0];
    return '$start 至 $end';
  }

  /// 是否有关联交易
  bool get hasAssociatedTrades => tradeIds.isNotEmpty;

  /// 是否有交易数据
  bool get hasTrades => tradeIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradingDiary && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TradingDiary(id: $id, title: $title, author: $authorFid)';
}