import 'package:flutter/material.dart';
import '../theme/eva_theme.dart';

/// Frame分享的交易复盘详情页
class FrameDiaryDetailPage extends StatelessWidget {
  final String diaryId;
  final String? pair;
  final double? pnl;
  final String? strategy;
  final String? sentiment;

  const FrameDiaryDetailPage({
    super.key,
    required this.diaryId,
    this.pair,
    this.pnl,
    this.strategy,
    this.sentiment,
  });

  /// 获取情绪信息
  Map<String, dynamic> get _sentimentInfo {
    switch (sentiment) {
      case '理性': return {'name': '理性', 'icon': '🧠', 'color': EvaTheme.neonGreen};
      case '自信': return {'name': '自信', 'icon': '😎', 'color': Colors.blue};
      case '谨慎': return {'name': '谨慎', 'icon': '⚠️', 'color': Colors.orange};
      case '贪婪': return {'name': '贪婪', 'icon': '🤑', 'color': Colors.green};
      case '恐惧': return {'name': '恐惧', 'icon': '😰', 'color': Colors.red};
      case 'FOMO': return {'name': 'FOMO', 'icon': '🏃', 'color': Colors.purple};
      default: return {'name': sentiment ?? '未知', 'icon': '🤔', 'color': EvaTheme.textGray};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvaTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: EvaTheme.deepBlack,
        elevation: 0,
        title: Text(
          '交易复盘详情',
          style: TextStyle(
            color: EvaTheme.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: EvaTheme.neonGreen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日记ID信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EvaTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: EvaTheme.primaryPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bookmark, color: EvaTheme.primaryPurple, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'ID: $diaryId',
                    style: TextStyle(
                      color: EvaTheme.primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 主要内容卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    EvaTheme.mechGray.withOpacity(0.9),
                    EvaTheme.deepBlack,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EvaTheme.neonGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: EvaTheme.neonGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚡ ThunderTrack',
                          style: TextStyle(
                            color: EvaTheme.neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '交易复盘',
                        style: TextStyle(
                          color: EvaTheme.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 交易信息
                  if (pair != null) ...[
                    _buildInfoRow('📊 交易对', pair!, EvaTheme.neonGreen),
                    const SizedBox(height: 16),
                  ],
                  
                  if (pnl != null) ...[
                    _buildInfoRow(
                      '💰 盈亏', 
                      '${pnl! >= 0 ? '+' : ''}\$${pnl!.toStringAsFixed(2)}',
                      pnl! >= 0 ? EvaTheme.neonGreen : Colors.red,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (strategy != null) ...[
                    _buildInfoRow('🎯 策略', strategy!, EvaTheme.lightText),
                    const SizedBox(height: 16),
                  ],
                  
                  if (sentiment != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '💭 情绪',
                          style: TextStyle(
                            color: EvaTheme.lightText,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_sentimentInfo['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _sentimentInfo['color'],
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_sentimentInfo['icon']} ${_sentimentInfo['name']}',
                            style: TextStyle(
                              color: _sentimentInfo['color'],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 操作提示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EvaTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EvaTheme.primaryPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: EvaTheme.primaryPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '来自Farcaster Frame',
                          style: TextStyle(
                            color: EvaTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '这是一个来自Farcaster Frame的交易复盘分享。你可以在ThunderTrack中查看更多详细信息和创建自己的交易日记。',
                          style: TextStyle(
                            color: EvaTheme.textGray,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: EvaTheme.lightText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}