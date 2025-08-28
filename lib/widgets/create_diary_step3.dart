import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import '../theme/eva_theme.dart';
import '../models/hyperliquid_models.dart';
import '../providers/user_provider.dart';
import '../services/cast_diary_service.dart';
import '../services/neynar_service.dart';

/// 写日记第三步：Frame预览和发布
class CreateDiaryStep3 extends StatefulWidget {
  final List<HyperliquidOrder> selectedTrades;
  final double totalPnL;
  final String strategy;
  final String sentiment;
  final List<String> tags;
  final String content;

  const CreateDiaryStep3({
    super.key,
    required this.selectedTrades,
    required this.totalPnL,
    required this.strategy,
    required this.sentiment,
    required this.tags,
    required this.content,
  });

  @override
  State<CreateDiaryStep3> createState() => _CreateDiaryStep3State();
}

class _CreateDiaryStep3State extends State<CreateDiaryStep3> {
  bool _isPublishing = false;
  bool _useFrameFormat = true;
  final CastDiaryService _diaryService = CastDiaryService();

  /// 获取主要交易对
  String get _mainTradingPair {
    if (widget.selectedTrades.length == 1) {
      return widget.selectedTrades.first.symbol;
    }
    final symbolCounts = <String, int>{};
    for (final trade in widget.selectedTrades) {
      symbolCounts[trade.symbol] = (symbolCounts[trade.symbol] ?? 0) + 1;
    }
    final mainSymbol = symbolCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return widget.selectedTrades.length > 1 ? '$mainSymbol等${widget.selectedTrades.length}笔' : mainSymbol;
  }

  /// 获取策略中文名称
  String get _strategyDisplayName {
    switch (widget.strategy) {
      case 'breakout': return '突破交易';
      case 'trend': return '趋势跟随';
      case 'grid': return '网格交易';
      case 'reversal': return '反转交易';
      case 'scalping': return '剥头皮';
      case 'swing': return '摆动交易';
      default: return widget.strategy;
    }
  }

  /// 获取情绪中文名称和图标
  Map<String, dynamic> get _sentimentInfo {
    switch (widget.sentiment) {
      case 'rational': return {'name': '理性', 'icon': '🧠', 'color': EvaTheme.neonGreen};
      case 'confident': return {'name': '自信', 'icon': '😎', 'color': Colors.blue};
      case 'cautious': return {'name': '谨慎', 'icon': '⚠️', 'color': Colors.orange};
      case 'greedy': return {'name': '贪婪', 'icon': '🤑', 'color': Colors.green};
      case 'fearful': return {'name': '恐惧', 'icon': '😰', 'color': Colors.red};
      case 'fomo': return {'name': 'FOMO', 'icon': '🏃', 'color': Colors.purple};
      default: return {'name': widget.sentiment, 'icon': '🤔', 'color': EvaTheme.textGray};
    }
  }

  /// 发布日记
  Future<void> _publishDiary() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // 获取真实的signer_uuid
    final signerUuid = await userProvider.getSignerUuid();
    
    if (signerUuid == null) {
      _showError('未找到发布凭证，请重新登录Farcaster');
      return;
    }

    // 先检查signer状态
    userProvider.addDebugLog('🔍 检查signer状态...');
    final neynarService = NeynarService();
    final signerStatus = await neynarService.getSignerStatus(signerUuid);
    
    if (signerStatus != null) {
      final status = signerStatus['status'] as String?;
      final approvalUrl = signerStatus['signer_approval_url'] as String?;
      
      userProvider.addDebugLog('📊 Signer状态: $status');
      
      if (status == 'pending_approval' && approvalUrl != null) {
        userProvider.addDebugLog('⚠️ Signer需要用户批准');
        userProvider.addDebugLog('🔗 批准URL: $approvalUrl');
        _showError('Signer需要批准，请先批准后再发布');
        return;
      } else if (status != 'approved') {
        userProvider.addDebugLog('❌ Signer状态不可用: $status');
        _showError('Signer状态异常，请重新登录');
        return;
      }
    } else {
      userProvider.addDebugLog('⚠️ 无法获取signer状态');
    }

    setState(() => _isPublishing = true);

    try {
      
      final success = await _diaryService.publishTradingDiary(
        signerUuid: signerUuid,
        tradingPair: _mainTradingPair,
        pnl: widget.totalPnL,
        strategy: _strategyDisplayName,
        sentiment: _sentimentInfo['name'],
        tags: widget.tags,
        content: widget.content,
        frameUrl: _useFrameFormat ? _generateFrameUrl() : null,
        logCallback: (String message) {
          // 将发布日志传递给UserProvider
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.addDebugLog(message);
        },
      );

      if (success) {
        _showSuccess();
      } else {
        _showError('发布失败，请重试');
      }
    } catch (e) {
      _showError('发布失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  /// 分享到Farcaster (使用Intent URL)
  Future<void> _shareToFarcaster() async {
    try {
      // 构建分享文本
      final shareText = _buildShareText();
      final frameUrl = _useFrameFormat ? _generateFrameUrl() : null;
      
      
      // 构建Warpcast分享URL
      final encodedText = Uri.encodeComponent(shareText);
      String warpcastUrl = 'https://warpcast.com/~/compose?text=$encodedText';
      
      if (frameUrl != null && frameUrl.isNotEmpty) {
        final encodedFrame = Uri.encodeComponent(frameUrl);
        // 尝试不同的参数格式
        warpcastUrl += '&embeds[]=$encodedFrame';
        // 或者尝试: warpcastUrl += '&embed=$encodedFrame';
      }
      
      
      // 在Web环境中打开新窗口
      if (kIsWeb) {
        // 使用window.open在新窗口中打开
        html.window.open(warpcastUrl, '_blank');
        _showSuccess();
      } else {
        // 移动端可以使用url_launcher
        _showError('请在Web版本中使用此功能');
      }
    } catch (e) {
      _showError('分享失败，请重试');
    }
  }

  /// 构建分享文本
  String _buildShareText() {
    final buffer = StringBuffer();
    
    // 标题和标签
    buffer.writeln('🔥 交易复盘 #ThunderTrack #TTrade');
    buffer.writeln();
    
    // 交易信息
    buffer.writeln('📊 主要交易对: $_mainTradingPair');
    
    // 盈亏信息
    final pnlEmoji = widget.totalPnL >= 0 ? '💰' : '📉';
    final pnlSign = widget.totalPnL >= 0 ? '+' : '';
    buffer.writeln('$pnlEmoji 总盈亏: $pnlSign\$${widget.totalPnL.toStringAsFixed(2)}');
    buffer.writeln();
    
    // 策略和情绪
    buffer.writeln('🎯 策略: $_strategyDisplayName');
    buffer.writeln('😊 心情: ${_sentimentInfo['name']}');
    buffer.writeln();
    
    // 用户内容
    if (widget.content.isNotEmpty) {
      buffer.writeln('📝 复盘心得:');
      buffer.writeln(widget.content);
      buffer.writeln();
    }
    
    // 标签
    if (widget.tags.isNotEmpty) {
      buffer.write('🏷️ ');
      buffer.writeln(widget.tags.map((tag) => '#$tag').join(' '));
    }
    
    return buffer.toString().trim();
  }

  /// 生成Frame URL (暂时使用主页，先实现基本功能)
  String _generateFrameUrl() {
    // 暂时先使用主页URL，确保Frame分享功能正常
    // 后续可以考虑其他方案来实现动态内容
    return 'https://thundertrack-miniapp.vercel.app/';
  }

  /// 显示成功消息
  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: EvaTheme.mechGray,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: EvaTheme.neonGreen, size: 24),
            const SizedBox(width: 8),
            Text('发布成功！', style: TextStyle(color: EvaTheme.neonGreen)),
          ],
        ),
        content: Text(
          '您的交易日记已成功发布到Farcaster！\n其他用户现在可以在广场中看到您的分享。',
          style: TextStyle(color: EvaTheme.lightText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              Navigator.of(context).popUntil((route) => route.isFirst); // 返回主页
            },
            child: Text('完成', style: TextStyle(color: EvaTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  /// 显示错误消息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvaTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: EvaTheme.deepBlack,
        elevation: 0,
        title: Text(
          '写交易日记 - 3/3',
          style: TextStyle(
            color: EvaTheme.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: EvaTheme.neonGreen),
      ),
      body: Column(
        children: [
          // 步骤指示器
          _buildStepIndicator(),
          
          // 主要内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frame格式选择
                  _buildFormatSelection(),
                  const SizedBox(height: 24),
                  
                  // 预览区域
                  if (_useFrameFormat)
                    _buildFramePreview()
                  else
                    _buildTextPreview(),
                    
                  const SizedBox(height: 24),
                  
                  // 发布说明
                  _buildPublishNote(),
                ],
              ),
            ),
          ),
          
          // 底部操作栏
          _buildBottomActions(),
        ],
      ),
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EvaTheme.mechGray.withValues(alpha: 0.8),
            EvaTheme.deepBlack.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EvaTheme.neonGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildStepDot(1, false, true), // completed
          Expanded(child: _buildStepLine(true)), // completed
          _buildStepDot(2, false, true), // completed
          Expanded(child: _buildStepLine(true)), // completed
          _buildStepDot(3, true, false), // active
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, bool isActive, bool isCompleted) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted 
          ? EvaTheme.neonGreen 
          : (isActive ? EvaTheme.neonGreen : EvaTheme.textGray.withValues(alpha: 0.3)),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted || isActive ? EvaTheme.neonGreen : EvaTheme.textGray,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
          ? Icon(Icons.check, color: EvaTheme.deepBlack, size: 16)
          : Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? EvaTheme.deepBlack : EvaTheme.textGray,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: isActive ? EvaTheme.neonGreen : EvaTheme.textGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  /// 构建格式选择
  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.view_module, color: EvaTheme.neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              '🎨 选择发布格式',
              style: TextStyle(
                color: EvaTheme.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormatOption(
                title: 'Frame格式',
                subtitle: '可视化交互界面',
                icon: Icons.dashboard_customize,
                isSelected: _useFrameFormat,
                onTap: () => setState(() => _useFrameFormat = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatOption(
                title: '文本格式',
                subtitle: '简洁文字描述',
                icon: Icons.text_fields,
                isSelected: !_useFrameFormat,
                onTap: () => setState(() => _useFrameFormat = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
            ? LinearGradient(colors: [
                EvaTheme.neonGreen.withValues(alpha: 0.2),
                EvaTheme.neonGreen.withValues(alpha: 0.1),
              ])
            : LinearGradient(colors: [
                EvaTheme.mechGray.withValues(alpha: 0.6),
                EvaTheme.deepBlack.withValues(alpha: 0.8),
              ]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? EvaTheme.neonGreen : EvaTheme.lightText,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: EvaTheme.textGray,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建Frame预览
  Widget _buildFramePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.preview, color: EvaTheme.neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              '📱 Frame预览',
              style: TextStyle(
                color: EvaTheme.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Frame模拟预览
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                EvaTheme.mechGray.withValues(alpha: 0.9),
                EvaTheme.deepBlack,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EvaTheme.neonGreen.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Frame头部
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EvaTheme.neonGreen.withValues(alpha: 0.2),
                      EvaTheme.neonGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EvaTheme.neonGreen.withValues(alpha: 0.2),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Frame内容
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 交易对和盈亏
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📊 ${_mainTradingPair}',
                              style: TextStyle(
                                color: EvaTheme.lightText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🎯 $_strategyDisplayName',
                              style: TextStyle(
                                color: EvaTheme.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: widget.totalPnL >= 0
                              ? LinearGradient(colors: [
                                  EvaTheme.neonGreen.withValues(alpha: 0.8),
                                  EvaTheme.neonGreen.withValues(alpha: 0.6),
                                ])
                              : LinearGradient(colors: [
                                  Colors.red.withValues(alpha: 0.8),
                                  Colors.red.withValues(alpha: 0.6),
                                ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                widget.totalPnL >= 0 ? '盈利' : '亏损',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${widget.totalPnL >= 0 ? '+' : ''}\$${widget.totalPnL.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (widget.content.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EvaTheme.deepBlack.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '💭 ${widget.content}',
                          style: TextStyle(
                            color: EvaTheme.lightText,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // 情绪和标签
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_sentimentInfo['color'] as Color).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _sentimentInfo['color'],
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_sentimentInfo['icon']} ${_sentimentInfo['name']}',
                            style: TextStyle(
                              color: _sentimentInfo['color'],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.tags.isNotEmpty)
                          Expanded(
                            child: Text(
                              widget.tags.take(3).join(' '),
                              style: TextStyle(
                                color: EvaTheme.textGray,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Frame按钮
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: EvaTheme.neonGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFrameButton('👍 赞', EvaTheme.neonGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFrameButton('🔄 转发', Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFrameButton('💬 评论', Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrameButton(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建文本预览
  Widget _buildTextPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.text_snippet, color: EvaTheme.neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              '📝 文本预览',
              style: TextStyle(
                color: EvaTheme.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EvaTheme.mechGray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: EvaTheme.neonGreen.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _generateCastText(),
                style: TextStyle(
                  color: EvaTheme.lightText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 生成Cast文本内容
  String _generateCastText() {
    final buffer = StringBuffer();
    
    buffer.writeln('🔥 交易复盘 #ThunderTrackDiary #TTrade');
    buffer.writeln();
    buffer.writeln('📊 交易对: ${_mainTradingPair}');
    
    final pnlEmoji = widget.totalPnL >= 0 ? '💰' : '📉';
    final pnlSign = widget.totalPnL >= 0 ? '+' : '';
    buffer.writeln('$pnlEmoji 盈亏: $pnlSign\$${widget.totalPnL.toStringAsFixed(2)}');
    
    buffer.writeln('🎯 策略: $_strategyDisplayName');
    buffer.writeln('💭 情绪: ${_sentimentInfo['name']}');
    
    if (widget.content.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 心得:');
      buffer.writeln(widget.content);
    }
    
    buffer.writeln();
    
    // 添加标签
    final allTags = [
      '#Hyperliquid',
      ...widget.tags,
    ];
    
    buffer.write(allTags.join(' '));

    return buffer.toString().trim();
  }

  /// 构建发布说明
  Widget _buildPublishNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EvaTheme.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EvaTheme.primaryPurple.withValues(alpha: 0.3),
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
                  '发布说明',
                  style: TextStyle(
                    color: EvaTheme.primaryPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• 您的日记将发布到Farcaster网络\n'
                  '• 其他用户可以在ThunderTrack广场看到\n'
                  '• 发布后无法删除，请确认内容正确',
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
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            EvaTheme.deepBlack.withValues(alpha: 0.8),
            EvaTheme.deepBlack,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: EvaTheme.neonGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: EvaTheme.textGray),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: _isPublishing ? null : () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: EvaTheme.textGray, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '上一步',
                    style: TextStyle(color: EvaTheme.textGray),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // 发布按钮
          Container(
            decoration: BoxDecoration(
              gradient: _isPublishing
                ? LinearGradient(colors: [
                    EvaTheme.textGray.withValues(alpha: 0.5),
                    EvaTheme.textGray.withValues(alpha: 0.3),
                  ])
                : EvaTheme.neonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _shareToFarcaster,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: _isPublishing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: EvaTheme.textGray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '发布中...',
                        style: TextStyle(
                          color: EvaTheme.textGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        color: EvaTheme.deepBlack,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '分享到Farcaster',
                        style: TextStyle(
                          color: EvaTheme.deepBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}