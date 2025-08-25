import 'package:flutter/foundation.dart';
import '../models/trading_diary.dart';
import '../utils/api_client.dart';

/// 基于Farcaster Cast的日记服务
class CastDiaryService {
  static final CastDiaryService _instance = CastDiaryService._internal();
  factory CastDiaryService() => _instance;
  CastDiaryService._internal();

  final ApiClient _apiClient = ApiClient();
  
  // ThunderTrack 日记标签
  static const String _mainTag = '#ThunderTrackDiary';
  static const String _tradeTag = '#TTrade';
  static const String _analysisTag = '#TAnalysis';
  static const String _profitTag = '#TProfit';
  static const String _lossTag = '#TLoss';
  static const String _gridTag = '#TGrid';
  static const String _breakoutTag = '#TBreakout';
  static const String _trendTag = '#TTrend';

  /// 获取用户的交易日记Cast列表
  Future<List<TradingDiary>> getUserDiaries(String fid, {int limit = 50}) async {
    try {
      // 使用Neynar API获取用户的Cast
      final response = await _apiClient.get(
        '/v2/farcaster/casts',
        queryParameters: {
          'fid': fid,
          'limit': limit,
          'include_replies': false,
        },
        baseUrl: 'https://api.neynar.com',
      );

      if (response.data['result']['casts'] != null) {
        final casts = response.data['result']['casts'] as List;
        
        // 筛选包含ThunderTrack标签的Cast
        final diaryDiaries = casts
            .where((cast) => 
                cast['text'] != null && 
                cast['text'].toString().contains(_mainTag))
            .map((cast) => _castToTradingDiary(cast))
            .where((diary) => diary != null)
            .cast<TradingDiary>()
            .toList();

        return diaryDiaries;
      }
      
      return [];
    } catch (e) {
      debugPrint('获取用户日记失败: $e');
      return [];
    }
  }

  /// 获取广场日记（所有用户的交易日记Cast）
  Future<List<TradingDiary>> getPublicDiaries({int limit = 100}) async {
    try {
      // 搜索包含ThunderTrack标签的Cast
      final response = await _apiClient.get(
        '/v2/farcaster/cast/search',
        queryParameters: {
          'q': _mainTag,
          'limit': limit,
          'priority_mode': true,
        },
        baseUrl: 'https://api.neynar.com',
      );

      if (response.data['result']['casts'] != null) {
        final casts = response.data['result']['casts'] as List;
        
        final publicDiaries = casts
            .map((cast) => _castToTradingDiary(cast))
            .where((diary) => diary != null)
            .cast<TradingDiary>()
            .toList();

        return publicDiaries;
      }
      
      return [];
    } catch (e) {
      debugPrint('获取广场日记失败: $e');
      return [];
    }
  }

  /// 发布交易日记Cast
  Future<bool> publishTradingDiary({
    required String signerUuid,
    required String tradingPair,
    required double pnl,
    required String strategy,
    required String sentiment,
    required List<String> tags,
    required String content,
    String? frameUrl,
  }) async {
    try {
      // 构建Cast文本内容
      final castText = _buildCastText(
        tradingPair: tradingPair,
        pnl: pnl,
        strategy: strategy,
        sentiment: sentiment,
        tags: tags,
        content: content,
      );

      final Map<String, dynamic> castData = {
        'signer_uuid': signerUuid,
        'text': castText,
      };

      // 如果有Frame URL，添加到Cast中
      if (frameUrl != null && frameUrl.isNotEmpty) {
        castData['embeds'] = [
          {'url': frameUrl}
        ];
      }

      final response = await _apiClient.post(
        '/v2/farcaster/casts',
        data: castData,
        baseUrl: 'https://api.neynar.com',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('发布交易日记失败: $e');
      return false;
    }
  }

  /// 构建Cast文本内容
  String _buildCastText({
    required String tradingPair,
    required double pnl,
    required String strategy,
    required String sentiment,
    required List<String> tags,
    required String content,
  }) {
    final buffer = StringBuffer();
    
    // 标题和基础信息
    buffer.writeln('🔥 交易复盘 $_mainTag $_tradeTag');
    buffer.writeln();
    
    // 交易信息
    buffer.writeln('📊 交易对: $tradingPair');
    
    // 盈亏信息
    final pnlEmoji = pnl >= 0 ? '💰' : '📉';
    final pnlSign = pnl >= 0 ? '+' : '';
    buffer.writeln('$pnlEmoji 盈亏: $pnlSign\$${pnl.toStringAsFixed(2)}');
    
    // 策略标签
    buffer.writeln('🎯 策略: $strategy');
    
    // 情绪标签
    buffer.writeln('💭 情绪: $sentiment');
    buffer.writeln();
    
    // 用户内容
    if (content.isNotEmpty) {
      buffer.writeln('📝 心得:');
      buffer.writeln(content);
      buffer.writeln();
    }
    
    // 标签
    final allTags = [
      _getStrategyTag(strategy),
      pnl >= 0 ? _profitTag : _lossTag,
      ...tags,
    ].where((tag) => tag.isNotEmpty).toList();
    
    if (allTags.isNotEmpty) {
      buffer.write(allTags.join(' '));
    }

    return buffer.toString().trim();
  }

  /// 获取策略对应的标签
  String _getStrategyTag(String strategy) {
    switch (strategy.toLowerCase()) {
      case 'breakout':
      case '突破':
        return _breakoutTag;
      case 'trend':
      case '趋势':
        return _trendTag;
      case 'grid':
      case '网格':
        return _gridTag;
      default:
        return _analysisTag;
    }
  }

  /// 将Cast转换为TradingDiary对象
  TradingDiary? _castToTradingDiary(Map<String, dynamic> cast) {
    try {
      final text = cast['text'] as String? ?? '';
      final author = cast['author'] as Map<String, dynamic>? ?? {};
      final hash = cast['hash'] as String? ?? '';
      final timestamp = cast['timestamp'] as String? ?? DateTime.now().toIso8601String();

      // 解析Cast内容
      final tradingInfo = _parseCastContent(text);
      if (tradingInfo == null) return null;

      return TradingDiary(
        id: hash,
        authorFid: author['fid']?.toString() ?? '',
        title: '${tradingInfo['pair'] ?? 'Trading'} 复盘',
        content: tradingInfo['content'] ?? text,
        type: DiaryType.singleTrade,
        symbol: tradingInfo['pair'],
        tags: tradingInfo['tags'] ?? [],
        createdAt: DateTime.parse(timestamp),
        updatedAt: DateTime.parse(timestamp),
        isPublic: true, // Cast都是公开的
        rating: _calculateRatingFromPnL(tradingInfo['pnl']),
      );
    } catch (e) {
      debugPrint('解析Cast失败: $e');
      return null;
    }
  }

  /// 根据PnL计算评分
  double? _calculateRatingFromPnL(double? pnl) {
    if (pnl == null) return null;
    if (pnl >= 500) return 5.0;
    if (pnl >= 200) return 4.5;
    if (pnl >= 50) return 4.0;
    if (pnl >= 0) return 3.5;
    if (pnl >= -50) return 3.0;
    if (pnl >= -200) return 2.5;
    return 2.0;
  }

  /// 解析Cast内容，提取交易信息
  Map<String, dynamic>? _parseCastContent(String text) {
    if (!text.contains(_mainTag)) return null;

    final result = <String, dynamic>{};
    
    // 解析交易对
    final pairMatch = RegExp(r'📊 交易对[：:]\s*([A-Z]+[\/\-][A-Z]+)').firstMatch(text);
    if (pairMatch != null) {
      result['pair'] = pairMatch.group(1);
    }

    // 解析盈亏
    final pnlMatch = RegExp(r'[💰📉] 盈亏[：:]\s*([+\-]?\$?[\d,]+\.?\d*)').firstMatch(text);
    if (pnlMatch != null) {
      final pnlStr = pnlMatch.group(1)?.replaceAll(RegExp(r'[\$,]'), '') ?? '0';
      result['pnl'] = double.tryParse(pnlStr) ?? 0.0;
    }

    // 解析策略
    final strategyMatch = RegExp(r'🎯 策略[：:]\s*([^\n]+)').firstMatch(text);
    if (strategyMatch != null) {
      result['strategy'] = strategyMatch.group(1)?.trim() ?? '';
    }

    // 解析心得内容
    final contentMatch = RegExp(r'📝 心得[：:]\s*\n(.*?)(?=\n#|$)', dotAll: true).firstMatch(text);
    if (contentMatch != null) {
      result['content'] = contentMatch.group(1)?.trim() ?? '';
    }

    // 解析标签
    final tags = RegExp(r'#[A-Za-z]\w*').allMatches(text)
        .map((match) => match.group(0) ?? '')
        .where((tag) => tag != _mainTag) // 排除主标签
        .toList();
    result['tags'] = tags;

    return result.isNotEmpty ? result : null;
  }
}