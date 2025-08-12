import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/trade.dart';
import '../widgets/trade_form.dart';
import '../widgets/trade_list.dart';
import '../widgets/market_overview.dart';

/// 交易页面，显示市场活跃交易和买卖操作
class TradingPage extends StatefulWidget {
  const TradingPage({super.key});

  @override
  State<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<Trade> _userTrades = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserTrades();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载用户交易记录
  Future<void> _loadUserTrades() async {
    setState(() => _isLoading = true);
    
    // 模拟加载延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 添加一些模拟交易数据用于展示
    final mockTrades = [
      Trade(
        id: '1',
        userFid: 'demo_user',
        symbol: 'ETH/USDT',
        side: 'buy',
        orderType: 'market',
        size: 0.5,
        price: 2850.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'filled',
        fee: 1.425,
      ),
      Trade(
        id: '2',
        userFid: 'demo_user',
        symbol: 'BTC/USDT',
        side: 'sell',
        orderType: 'limit',
        size: 0.01,
        price: 65000.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'filled',
        fee: 0.65,
        diaryId: 'diary_123',
      ),
    ];
    
    setState(() {
      _userTrades.addAll(mockTrades);
      _isLoading = false;
    });
  }

  /// 添加新交易
  void _addTrade(Trade trade) {
    setState(() {
      _userTrades.insert(0, trade);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('交易记录已添加: ${trade.symbol}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 显示添加交易对话框
  void _showAddTradeDialog() {
    showDialog(
      context: context,
      builder: (context) => TradeForm(
        onTradeSubmitted: _addTrade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isAuthenticated) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '请先登录',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '登录后即可查看和记录交易',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 市场概览卡片
            const MarketOverview(),
            
            // Tab导航
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '我的交易', icon: Icon(Icons.list)),
                  Tab(text: '市场数据', icon: Icon(Icons.analytics)),
                  Tab(text: '实时报价', icon: Icon(Icons.trending_up)),
                ],
              ),
            ),
            
            // Tab内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 我的交易记录
                  _buildMyTradesTab(),
                  
                  // 市场数据
                  _buildMarketDataTab(),
                  
                  // 实时报价
                  _buildLivePricesTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建我的交易标签页
  Widget _buildMyTradesTab() {
    return CustomScrollView(
      slivers: [
        // 添加交易按钮
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddTradeDialog,
                icon: const Icon(Icons.add),
                label: const Text('记录新交易'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
        
        // 交易列表
        _isLoading
            ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            : TradeList.sliver(trades: _userTrades),
      ],
    );
  }

  /// 构建市场数据标签页
  Widget _buildMarketDataTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            '市场数据分析',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('即将推出 - 深度市场分析和图表'),
        ],
      ),
    );
  }

  /// 构建实时报价标签页
  Widget _buildLivePricesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            '实时报价',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('即将推出 - Hyperliquid API 实时价格'),
        ],
      ),
    );
  }
}