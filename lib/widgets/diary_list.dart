import 'package:flutter/material.dart';
import '../models/trading_diary.dart';
import 'diary_detail_page.dart';

/// 日记列表组件
class DiaryList extends StatelessWidget {
  /// 日记列表数据
  final List<TradingDiary> diaries;
  
  /// 空状态组件
  final Widget? emptyWidget;
  
  /// 下拉刷新回调
  final Future<void> Function()? onRefresh;
  
  /// 日记点击回调
  final Function(TradingDiary)? onDiaryTap;

  const DiaryList({
    super.key,
    required this.diaries,
    this.emptyWidget,
    this.onRefresh,
    this.onDiaryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (diaries.isEmpty && emptyWidget != null) {
      return emptyWidget!;
    }

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: _buildList(),
      );
    }

    return _buildList();
  }

  /// 构建列表
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diaries.length,
      itemBuilder: (context, index) {
        final diary = diaries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DiaryCard(
            diary: diary,
            onTap: () => _navigateToDetail(context, diary),
          ),
        );
      },
    );
  }

  /// 导航到日记详情页面
  void _navigateToDetail(BuildContext context, TradingDiary diary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailPage(diary: diary),
      ),
    );
  }
}

/// 日记卡片组件
class DiaryCard extends StatelessWidget {
  final TradingDiary diary;
  final VoidCallback? onTap;

  const DiaryCard({
    super.key,
    required this.diary,
    this.onTap,
  });

  /// 分享日记到Farcaster (功能已移除)
  Future<void> _shareDiary() async {
    // Farcaster share service removed - functionality not available
    // TODO: 实现其他分享方式或显示提示
    debugPrint('分享功能暂不可用');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和类型
              Row(
                children: [
                  Expanded(
                    child: Text(
                      diary.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeChip(),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 内容预览
              Text(
                _getContentPreview(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 标签
              if (diary.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: diary.tags.take(3).map((tag) => _buildTag(tag)).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // 底部信息
              Row(
                children: [
                  // 时间
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(diary.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 交互数据
                  if (diary.likes > 0) ...[
                    Icon(
                      Icons.favorite,
                      size: 14,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${diary.likes}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  if (diary.comments > 0) ...[
                    Icon(
                      Icons.comment,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${diary.comments}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  if (diary.hasAssociatedTrades) ...[
                    Icon(
                      Icons.show_chart,
                      size: 14,
                      color: Colors.blue[400],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${diary.tradeIds.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // 分享按钮
                  InkWell(
                    onTap: _shareDiary,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.share,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建类型标签
  Widget _buildTypeChip() {
    Color color;
    String label = diary.typeDisplayName;
    
    switch (diary.type) {
      case DiaryType.singleTrade:
        color = Colors.blue;
        break;
      case DiaryType.strategySummary:
        color = Colors.green;
        break;
      case DiaryType.freeForm:
        color = Colors.orange;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// 构建标签
  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  /// 获取内容预览
  String _getContentPreview() {
    // 移除Markdown格式符号并截取预览
    String preview = diary.content
        .replaceAll(RegExp(r'[#*`_\[\]()]'), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
    
    if (preview.length > 100) {
      preview = '${preview.substring(0, 100)}...';
    }
    
    return preview;
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) {
      return '${date.month}月${date.day}日';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}