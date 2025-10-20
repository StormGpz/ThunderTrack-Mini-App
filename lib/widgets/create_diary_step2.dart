import 'package:flutter/material.dart';
import '../theme/eva_theme.dart';
import '../models/trade.dart';
import 'create_diary_step3.dart';

/// 写日记第二步：分析填写
class CreateDiaryStep2 extends StatefulWidget {
  final List<Trade> selectedTrades;
  final double totalPnL;

  const CreateDiaryStep2({
    super.key,
    required this.selectedTrades,
    required this.totalPnL,
  });

  @override
  State<CreateDiaryStep2> createState() => _CreateDiaryStep2State();
}

class _CreateDiaryStep2State extends State<CreateDiaryStep2> {
  String _selectedStrategy = '';
  String _selectedSentiment = '';
  List<String> _selectedTags = [];
  final TextEditingController _contentController = TextEditingController();
  
  // 预设策略选项
  final List<Map<String, dynamic>> _strategies = [
    {'id': 'breakout', 'name': '突破交易', 'icon': Icons.trending_up, 'desc': '价格突破关键阻力/支撑位'},
    {'id': 'trend', 'name': '趋势跟随', 'icon': Icons.show_chart, 'desc': '跟随市场主要趋势方向'},
    {'id': 'grid', 'name': '网格交易', 'icon': Icons.grid_on, 'desc': '区间震荡中的网格策略'},
    {'id': 'reversal', 'name': '反转交易', 'icon': Icons.swap_horiz, 'desc': '市场超买超卖反转'},
    {'id': 'scalping', 'name': '剥头皮', 'icon': Icons.flash_on, 'desc': '短期快速交易获利'},
    {'id': 'swing', 'name': '摆动交易', 'icon': Icons.waves, 'desc': '中短期波段操作'},
  ];

  // 预设情绪选项
  final List<Map<String, dynamic>> _sentiments = [
    {'id': 'rational', 'name': '理性', 'icon': Icons.psychology, 'color': EvaTheme.neonGreen, 'desc': '冷静分析，严格执行'},
    {'id': 'confident', 'name': '自信', 'icon': Icons.emoji_emotions, 'color': Colors.blue, 'desc': '对策略充满信心'},
    {'id': 'cautious', 'name': '谨慎', 'icon': Icons.warning_amber, 'color': Colors.orange, 'desc': '小心谨慎，控制风险'},
    {'id': 'greedy', 'name': '贪婪', 'icon': Icons.attach_money, 'color': Colors.green, 'desc': '过度追求利润'},
    {'id': 'fearful', 'name': '恐惧', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red, 'desc': '担心害怕，犹豫不决'},
    {'id': 'fomo', 'name': 'FOMO', 'icon': Icons.run_circle, 'color': Colors.purple, 'desc': '害怕错过机会'},
  ];

  // 预设标签
  final List<String> _availableTags = [
    '#DeFi', '#Spot', '#Future', '#Leverage', '#HighVol', '#LowVol',
    '#Altcoin', '#BTC', '#ETH', '#Layer2', '#GameFi', '#AI',
    '#Breakout', '#Support', '#Resistance', '#Pattern', '#Volume', '#RSI',
  ];

  /// 获取主要交易对
  String get _mainTradingPair {
    if (widget.selectedTrades.length == 1) {
      return widget.selectedTrades.first.symbol;
    }
    // 多笔交易时显示主要的交易对
    final symbolCounts = <String, int>{};
    for (final trade in widget.selectedTrades) {
      symbolCounts[trade.symbol] = (symbolCounts[trade.symbol] ?? 0) + 1;
    }
    final mainSymbol = symbolCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return widget.selectedTrades.length > 1 ? '$mainSymbol等${widget.selectedTrades.length}笔' : mainSymbol;
  }

  /// 进入下一步
  void _goToNextStep() {
    if (_selectedStrategy.isEmpty) {
      _showError('请选择交易策略');
      return;
    }
    if (_selectedSentiment.isEmpty) {
      _showError('请选择交易情绪');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDiaryStep3(
          selectedTrades: widget.selectedTrades,
          totalPnL: widget.totalPnL,
          strategy: _selectedStrategy,
          sentiment: _selectedSentiment,
          tags: _selectedTags,
          content: _contentController.text,
        ),
      ),
    );
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EvaTheme.warningYellow,
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
          '写交易日记 - 2/3',
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
                  // 交易概要
                  _buildTradeSummary(),
                  const SizedBox(height: 24),
                  
                  // 策略选择
                  _buildStrategySelection(),
                  const SizedBox(height: 24),
                  
                  // 情绪选择
                  _buildSentimentSelection(),
                  const SizedBox(height: 24),
                  
                  // 标签选择
                  _buildTagSelection(),
                  const SizedBox(height: 24),
                  
                  // 心得输入
                  _buildContentInput(),
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
          Expanded(child: _buildStepLine(true)),
          _buildStepDot(2, true, false), // active
          Expanded(child: _buildStepLine(false)),
          _buildStepDot(3, false, false),
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

  /// 构建交易概要
  Widget _buildTradeSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: EvaTheme.neonGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                '交易概要',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '交易对',
                    style: TextStyle(color: EvaTheme.textGray, fontSize: 12),
                  ),
                  Text(
                    _mainTradingPair,
                    style: TextStyle(
                      color: EvaTheme.lightText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '总盈亏',
                    style: TextStyle(color: EvaTheme.textGray, fontSize: 12),
                  ),
                  Text(
                    '${widget.totalPnL >= 0 ? '+' : ''}\$${widget.totalPnL.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: widget.totalPnL >= 0 ? EvaTheme.neonGreen : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建策略选择
  Widget _buildStrategySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: EvaTheme.neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              '🎯 选择交易策略',
              style: TextStyle(
                color: EvaTheme.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _strategies.length,
          itemBuilder: (context, index) {
            final strategy = _strategies[index];
            final isSelected = _selectedStrategy == strategy['id'];
            
            return GestureDetector(
              onTap: () => setState(() => _selectedStrategy = strategy['id']),
              child: Container(
                padding: const EdgeInsets.all(12),
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      strategy['icon'],
                      color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            strategy['name'],
                            style: TextStyle(
                              color: isSelected ? EvaTheme.neonGreen : EvaTheme.lightText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            strategy['desc'],
                            style: TextStyle(
                              color: EvaTheme.textGray,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 构建情绪选择
  Widget _buildSentimentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mood, color: EvaTheme.neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              '💭 交易时的情绪状态',
              style: TextStyle(
                color: EvaTheme.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _sentiments.length,
          itemBuilder: (context, index) {
            final sentiment = _sentiments[index];
            final isSelected = _selectedSentiment == sentiment['id'];
            
            return GestureDetector(
              onTap: () => setState(() => _selectedSentiment = sentiment['id']),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isSelected
                    ? LinearGradient(colors: [
                        (sentiment['color'] as Color).withValues(alpha: 0.2),
                        (sentiment['color'] as Color).withValues(alpha: 0.1),
                      ])
                    : LinearGradient(colors: [
                        EvaTheme.mechGray.withValues(alpha: 0.6),
                        EvaTheme.deepBlack.withValues(alpha: 0.8),
                      ]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? sentiment['color'] : EvaTheme.textGray.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      sentiment['icon'],
                      color: isSelected ? sentiment['color'] : EvaTheme.textGray,
                      size: 16,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sentiment['name'],
                      style: TextStyle(
                        color: isSelected ? sentiment['color'] : EvaTheme.lightText,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 构建标签选择
  Widget _buildTagSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer, color: EvaTheme.neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              '🏷️ 相关标签 (可选)',
              style: TextStyle(
                color: EvaTheme.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag, style: TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              backgroundColor: EvaTheme.mechGray.withValues(alpha: 0.5),
              selectedColor: EvaTheme.neonGreen.withValues(alpha: 0.2),
              checkmarkColor: EvaTheme.neonGreen,
              labelStyle: TextStyle(
                color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray.withValues(alpha: 0.3),
                width: 1,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建内容输入
  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, color: EvaTheme.neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              '📝 交易心得 (可选)',
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
          decoration: BoxDecoration(
            color: EvaTheme.mechGray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: EvaTheme.neonGreen.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _contentController,
            maxLines: 4,
            style: TextStyle(color: EvaTheme.lightText),
            decoration: InputDecoration(
              hintText: '分享一下这次交易的心得体会、市场观察或策略思考...',
              hintStyle: TextStyle(color: EvaTheme.textGray),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActions() {
    final isComplete = _selectedStrategy.isNotEmpty && _selectedSentiment.isNotEmpty;
    
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
              onPressed: () => Navigator.pop(context),
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
          
          // 下一步按钮
          Container(
            decoration: BoxDecoration(
              gradient: isComplete
                ? EvaTheme.neonGradient
                : LinearGradient(colors: [
                    EvaTheme.textGray.withValues(alpha: 0.3),
                    EvaTheme.textGray.withValues(alpha: 0.2),
                  ]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: isComplete ? _goToNextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '下一步',
                    style: TextStyle(
                      color: isComplete ? EvaTheme.deepBlack : EvaTheme.textGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: isComplete ? EvaTheme.deepBlack : EvaTheme.textGray,
                    size: 18,
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