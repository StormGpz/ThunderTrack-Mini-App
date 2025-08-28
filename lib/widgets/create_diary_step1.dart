import 'package:flutter/material.dart';
import '../theme/eva_theme.dart';
import '../models/hyperliquid_models.dart';
import 'create_diary_step2.dart';

/// 写日记第一步：选择交易
class CreateDiaryStep1 extends StatefulWidget {
  const CreateDiaryStep1({super.key});

  @override
  State<CreateDiaryStep1> createState() => _CreateDiaryStep1State();
}

class _CreateDiaryStep1State extends State<CreateDiaryStep1> {
  List<HyperliquidOrder> _recentTrades = [];
  List<HyperliquidOrder> _selectedTrades = [];
  bool _isLoading = true;
  String _timeRange = '24h';
  
  final List<String> _timeRanges = ['1h', '4h', '12h', '24h', '3d', '7d'];

  @override
  void initState() {
    super.initState();
    _loadRecentTrades();
  }

  /// 加载最近的交易记录
  Future<void> _loadRecentTrades() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: 从HyperliquidService获取真实交易数据
      // 这里先用模拟数据
      await Future.delayed(const Duration(milliseconds: 800));
      
      _recentTrades = _getMockTrades();
    } catch (e) {
      debugPrint('加载交易记录失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 模拟交易数据
  List<HyperliquidOrder> _getMockTrades() {
    final now = DateTime.now();
    return [
      // 最近的盈利交易
      HyperliquidOrder(
        orderId: '1',
        symbol: 'ETH/USDT',
        type: OrderType.market,
        side: OrderSide.buy,
        size: 0.8,
        price: 2450.50,
        filledSize: 0.8,
        averagePrice: 2450.50,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        address: '0x123...',
        pnl: 195.80,
      ),
      
      // BTC短线交易
      HyperliquidOrder(
        orderId: '2',
        symbol: 'BTC/USDT',
        type: OrderType.limit,
        side: OrderSide.sell,
        size: 0.05,
        price: 43250.00,
        filledSize: 0.05,
        averagePrice: 43280.00,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(hours: 3, minutes: 15)),
        address: '0x123...',
        pnl: -67.30,
      ),
      
      // SOL突破交易
      HyperliquidOrder(
        orderId: '3',
        symbol: 'SOL/USDT',
        type: OrderType.market,
        side: OrderSide.buy,
        size: 15.0,
        price: 98.75,
        filledSize: 15.0,
        averagePrice: 98.90,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(hours: 6, minutes: 45)),
        address: '0x123...',
        pnl: 234.50,
      ),
      
      // ARB Layer2概念
      HyperliquidOrder(
        orderId: '4',
        symbol: 'ARB/USDT',
        type: OrderType.limit,
        side: OrderSide.buy,
        size: 50.0,
        price: 1.85,
        filledSize: 50.0,
        averagePrice: 1.84,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(hours: 8, minutes: 20)),
        address: '0x123...',
        pnl: 12.50,
      ),
      
      // MATIC网格交易亏损
      HyperliquidOrder(
        orderId: '5',
        symbol: 'MATIC/USDT',
        type: OrderType.market,
        side: OrderSide.sell,
        size: 200.0,
        price: 0.72,
        filledSize: 200.0,
        averagePrice: 0.715,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(hours: 12, minutes: 10)),
        address: '0x123...',
        pnl: -23.80,
      ),
      
      // AVAX DeFi概念
      HyperliquidOrder(
        orderId: '6',
        symbol: 'AVAX/USDT',
        type: OrderType.market,
        side: OrderSide.buy,
        size: 8.0,
        price: 35.20,
        filledSize: 8.0,
        averagePrice: 35.15,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(hours: 18, minutes: 30)),
        address: '0x123...',
        pnl: 48.60,
      ),
      
      // DOT波卡生态
      HyperliquidOrder(
        orderId: '7',
        symbol: 'DOT/USDT',
        type: OrderType.limit,
        side: OrderSide.sell,
        size: 25.0,
        price: 6.80,
        filledSize: 25.0,
        averagePrice: 6.78,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(hours: 22, minutes: 45)),
        address: '0x123...',
        pnl: -18.90,
      ),
      
      // LINK预言机龙头大单
      HyperliquidOrder(
        orderId: '8',
        symbol: 'LINK/USDT',
        type: OrderType.market,
        side: OrderSide.buy,
        size: 12.0,
        price: 14.25,
        filledSize: 12.0,
        averagePrice: 14.30,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        address: '0x123...',
        pnl: 86.40,
      ),
      
      // ADA cardano生态小仓位
      HyperliquidOrder(
        orderId: '9',
        symbol: 'ADA/USDT',
        type: OrderType.limit,
        side: OrderSide.buy,
        size: 100.0,
        price: 0.48,
        filledSize: 100.0,
        averagePrice: 0.485,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
        address: '0x123...',
        pnl: 7.20,
      ),
      
      // UNI DEX龙头反弹
      HyperliquidOrder(
        orderId: '10',
        symbol: 'UNI/USDT',
        type: OrderType.market,
        side: OrderSide.buy,
        size: 6.0,
        price: 8.90,
        filledSize: 6.0,
        averagePrice: 8.95,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        address: '0x123...',
        pnl: 125.70,
      ),
      
      // ATOM cosmos生态
      HyperliquidOrder(
        orderId: '11',
        symbol: 'ATOM/USDT',
        type: OrderType.limit,
        side: OrderSide.sell,
        size: 18.0,
        price: 10.15,
        filledSize: 18.0,
        averagePrice: 10.12,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(days: 2, hours: 14)),
        address: '0x123...',
        pnl: -31.50,
      ),
      
      // FTM fantom生态抄底
      HyperliquidOrder(
        orderId: '12',
        symbol: 'FTM/USDT',
        type: OrderType.market,
        side: OrderSide.buy,
        size: 150.0,
        price: 0.32,
        filledSize: 150.0,
        averagePrice: 0.318,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(days: 3, hours: 6)),
        address: '0x123...',
        pnl: 45.90,
      ),
    ];
  }

  /// 计算选中交易的总盈亏
  double get _totalPnL {
    return _selectedTrades.fold(0.0, (sum, trade) => sum + (trade.pnl ?? 0.0));
  }

  /// 进入下一步
  void _goToNextStep() {
    if (_selectedTrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请至少选择一笔交易'),
          backgroundColor: EvaTheme.warningYellow,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDiaryStep2(
          selectedTrades: _selectedTrades,
          totalPnL: _totalPnL,
        ),
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
          '写交易日记 - 1/3',
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
          
          // 时间范围选择
          _buildTimeRangeSelector(),
          
          // 交易列表
          Expanded(
            child: _buildTradesList(),
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
          _buildStepDot(1, true),
          Expanded(child: _buildStepLine(false)),
          _buildStepDot(2, false),
          Expanded(child: _buildStepLine(false)),
          _buildStepDot(3, false),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? EvaTheme.neonGreen : EvaTheme.textGray.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? EvaTheme.neonGreen : EvaTheme.textGray,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
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

  /// 构建时间范围选择器
  Widget _buildTimeRangeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 选择要复盘的交易',
            style: TextStyle(
              color: EvaTheme.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '时间范围:',
                style: TextStyle(
                  color: EvaTheme.lightText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _timeRanges.map((range) => 
                      _buildTimeRangeChip(range)
                    ).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String range) {
    final isSelected = _timeRange == range;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(range),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _timeRange = range;
              _loadRecentTrades(); // 重新加载数据
            });
          }
        },
        backgroundColor: EvaTheme.mechGray.withValues(alpha: 0.5),
        selectedColor: EvaTheme.neonGreen.withValues(alpha: 0.2),
        checkmarkColor: EvaTheme.neonGreen,
        labelStyle: TextStyle(
          color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );
  }

  /// 构建交易列表
  Widget _buildTradesList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: EvaTheme.neonGreen),
            const SizedBox(height: 16),
            Text(
              '加载交易记录中...',
              style: TextStyle(color: EvaTheme.textGray),
            ),
          ],
        ),
      );
    }

    if (_recentTrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: EvaTheme.textGray),
            const SizedBox(height: 16),
            Text(
              '该时间范围内暂无交易记录',
              style: TextStyle(
                color: EvaTheme.textGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentTrades.length,
      itemBuilder: (context, index) => _buildTradeItem(_recentTrades[index]),
    );
  }

  /// 构建交易项
  Widget _buildTradeItem(HyperliquidOrder trade) {
    final isSelected = _selectedTrades.contains(trade);
    final isProfitable = (trade.pnl ?? 0) >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isSelected 
              ? EvaTheme.neonGreen.withValues(alpha: 0.1)
              : EvaTheme.mechGray.withValues(alpha: 0.8),
            isSelected
              ? EvaTheme.neonGreen.withValues(alpha: 0.05)
              : EvaTheme.deepBlack.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? EvaTheme.neonGreen
            : EvaTheme.textGray.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isProfitable 
              ? LinearGradient(colors: [
                  EvaTheme.neonGreen.withValues(alpha: 0.8),
                  EvaTheme.neonGreen.withValues(alpha: 0.6),
                ])
              : LinearGradient(colors: [
                  Colors.red.withValues(alpha: 0.8),
                  Colors.red.withValues(alpha: 0.6),
                ]),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isProfitable ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              trade.symbol,
              style: TextStyle(
                color: EvaTheme.lightText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              trade.side == OrderSide.buy ? '买入' : '卖出',
              style: TextStyle(
                color: trade.side == OrderSide.buy 
                  ? EvaTheme.neonGreen 
                  : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '数量: ${trade.size.toStringAsFixed(4)}',
                  style: TextStyle(color: EvaTheme.textGray, fontSize: 12),
                ),
                Text(
                  '价格: \$${(trade.price ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(color: EvaTheme.textGray, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimeAgo(trade.createdAt),
                  style: TextStyle(color: EvaTheme.textGray, fontSize: 11),
                ),
                Text(
                  isProfitable 
                    ? '+\$${(trade.pnl ?? 0.0).toStringAsFixed(2)}'
                    : '\$${(trade.pnl ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isProfitable ? EvaTheme.neonGreen : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedTrades.add(trade);
              } else {
                _selectedTrades.remove(trade);
              }
            });
          },
          activeColor: EvaTheme.neonGreen,
          checkColor: EvaTheme.deepBlack,
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTrades.remove(trade);
            } else {
              _selectedTrades.add(trade);
            }
          });
        },
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
          // 选中信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '已选择 ${_selectedTrades.length} 笔交易',
                  style: TextStyle(
                    color: EvaTheme.lightText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedTrades.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '总盈亏: ${_totalPnL >= 0 ? '+' : ''}\$${_totalPnL.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _totalPnL >= 0 ? EvaTheme.neonGreen : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 下一步按钮
          Container(
            decoration: BoxDecoration(
              gradient: _selectedTrades.isNotEmpty
                ? EvaTheme.neonGradient
                : LinearGradient(colors: [
                    EvaTheme.textGray.withValues(alpha: 0.3),
                    EvaTheme.textGray.withValues(alpha: 0.2),
                  ]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _selectedTrades.isNotEmpty ? _goToNextStep : null,
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
                      color: _selectedTrades.isNotEmpty 
                        ? EvaTheme.deepBlack 
                        : EvaTheme.textGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: _selectedTrades.isNotEmpty 
                      ? EvaTheme.deepBlack 
                      : EvaTheme.textGray,
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

  /// 格式化时间
  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}