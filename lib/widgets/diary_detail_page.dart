import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trading_diary.dart';
import 'package:intl/intl.dart';

/// 日记详情页面
class DiaryDetailPage extends StatefulWidget {
  final TradingDiary diary;
  
  const DiaryDetailPage({
    super.key,
    required this.diary,
  });

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  bool _isLiked = false;
  int _currentLikes = 0;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.diary.likes;
  }

  /// 点赞/取消点赞
  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _currentLikes--;
        _isLiked = false;
      } else {
        _currentLikes++;
        _isLiked = true;
      }
    });

    // TODO: 调用后端API更新点赞状态
    HapticFeedback.lightImpact();
  }

  /// 分享日记 (功能已移除)
  Future<void> _shareDiary() async {
    // Farcaster share service removed - functionality not available
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分享功能暂不可用'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 复制内容到剪贴板
  void _copyContent() {
    Clipboard.setData(ClipboardData(text: widget.diary.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('内容已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 自定义AppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.diary.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _shareDiary,
                icon: const Icon(Icons.share),
                tooltip: '分享到 Farcaster',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'copy':
                      _copyContent();
                      break;
                    case 'report':
                      _showReportDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('复制内容'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: ListTile(
                      leading: Icon(Icons.report_outlined),
                      title: Text('举报'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // 内容区域
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 日记类型和时间信息
                _buildInfoCard(),
                
                const SizedBox(height: 16),
                
                // 标签
                if (widget.diary.tags.isNotEmpty) ...[
                  _buildTagsSection(),
                  const SizedBox(height: 16),
                ],
                
                // 日记内容
                _buildContentCard(),
                
                const SizedBox(height: 16),
                
                // 关联交易（如果有）
                if (widget.diary.hasAssociatedTrades) ...[
                  _buildAssociatedTrades(),
                  const SizedBox(height: 16),
                ],
                
                // 图片（如果有）
                if (widget.diary.imageUrls.isNotEmpty) ...[
                  _buildImagesSection(),
                  const SizedBox(height: 16),
                ],
                
                // 交互按钮区域
                _buildActionButtons(),
                
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 类型标识
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getTypeColor().withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getTypeEmoji(),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.diary.typeDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // 评分（如果有）
                if (widget.diary.rating != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        widget.diary.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 时间和其他信息
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('yyyy年M月d日 HH:mm').format(widget.diary.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                if (widget.diary.periodDescription != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.date_range,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.diary.periodDescription!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            
            // 主要交易币种（如果有）
            if (widget.diary.symbol != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '主要币种: ${widget.diary.symbol}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建标签区域
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标签',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.diary.tags.map((tag) => Chip(
            label: Text(
              tag,
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.grey[100],
            side: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          )).toList(),
        ),
      ],
    );
  }

  /// 构建内容卡片
  Widget _buildContentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '日记内容',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              widget.diary.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
            
            // 总结（如果有）
            if (widget.diary.summary != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '核心总结',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.diary.summary!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建关联交易区域
  Widget _buildAssociatedTrades() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  size: 20,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '关联交易',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.diary.tradeIds.length} 笔',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                children: widget.diary.tradeIds.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tradeId = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < widget.diary.tradeIds.length - 1 ? 8 : 0),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.blue[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '交易 ID: $tradeId',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '相关图片',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.diary.imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: index < widget.diary.imageUrls.length - 1 ? 12 : 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.diary.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建交互按钮区域
  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 点赞按钮
            Expanded(
              child: InkWell(
                onTap: _toggleLike,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isLiked ? Colors.red[50] : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isLiked ? Colors.red[200]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_currentLikes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isLiked ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 评论按钮
            Expanded(
              child: InkWell(
                onTap: () {
                  // TODO: 实现评论功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('评论功能即将推出')),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.diary.comments}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 分享按钮
            Expanded(
              child: InkWell(
                onTap: _shareDiary,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.share,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '分享',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取类型颜色
  Color _getTypeColor() {
    switch (widget.diary.type) {
      case DiaryType.singleTrade:
        return Colors.blue;
      case DiaryType.strategySummary:
        return Colors.green;
      case DiaryType.freeForm:
        return Colors.orange;
    }
  }

  /// 获取类型Emoji
  String _getTypeEmoji() {
    switch (widget.diary.type) {
      case DiaryType.singleTrade:
        return '📊';
      case DiaryType.strategySummary:
        return '🎯';
      case DiaryType.freeForm:
        return '📝';
    }
  }

  /// 显示举报对话框
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('举报内容'),
        content: const Text('请选择举报理由：'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('感谢您的反馈，我们会尽快处理')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}