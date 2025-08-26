import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/trading_pair.dart';
import '../models/trade.dart';
import '../models/address_auth.dart';
import '../widgets/trade_form.dart';
import '../widgets/address_selection_widget.dart';
import '../widgets/eva_mech_decoration.dart';
import '../services/hyperliquid_service.dart';
import '../theme/eva_theme.dart';

/// 交易页面 - 类似中心化交易所的行情页面
class TradingPage extends StatefulWidget {
  const TradingPage({super.key});

  @override
  State<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final HyperliquidService _hyperliquidService = HyperliquidService();
  
  List<TradingPair> _allTradingPairs = [];
  List<TradingPair> _filteredTradingPairs = [];
  final List<Trade> _userTrades = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  // 地址管理相关状态
  AddressOption? _currentTradingAddress;
  bool _isAddressAuthorized = false;
  bool _showAddressSelection = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
    _loadTradingPairs();
    _loadUserTrades();
  }

  /// 初始化服务
  Future<void> _initializeServices() async {
    await _hyperliquidService.initialize();
    _checkCurrentTradingAddress();
  }

  /// 检查当前交易地址状态
  void _checkCurrentTradingAddress() {
    final currentAddress = _hyperliquidService.currentTradingAddress;
    if (currentAddress != null) {
      _isAddressAuthorized = _hyperliquidService.isAddressAuthorized(currentAddress);
      setState(() {
        _currentTradingAddress = AddressOption(
          address: currentAddress,
          type: _isAddressAuthorized ? '已授权钱包' : '钱包地址',
          isConnected: _isAddressAuthorized,
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 加载交易对数据
  Future<void> _loadTradingPairs() async {
    setState(() => _isLoading = true);
    
    // 模拟加载延迟
    await Future.delayed(const Duration(milliseconds: 800));
    
    // 使用模拟数据
    final mockPairs = TradingPair.getMockData();
    
    setState(() {
      _allTradingPairs = mockPairs;
      _filteredTradingPairs = mockPairs;
      _isLoading = false;
    });
  }

  /// 加载用户交易记录
  Future<void> _loadUserTrades() async {
    // 添加一些模拟交易数据
    final mockTrades = [
      Trade(
        id: '1',
        userFid: 'demo_user',
        symbol: 'BTC/USDT',
        side: 'buy',
        orderType: 'market',
        size: 0.05,
        price: 65000.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'filled',
        fee: 16.25,
      ),
      Trade(
        id: '2',
        userFid: 'demo_user',
        symbol: 'ETH/USDT',
        side: 'sell',
        orderType: 'limit',
        size: 1.5,
        price: 2850.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'filled',
        fee: 4.275,
      ),
    ];
    
    setState(() {
      _userTrades.addAll(mockTrades);
    });
  }

  /// 搜索交易对
  void _searchTradingPairs(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        _filteredTradingPairs = _allTradingPairs;
      } else {
        _filteredTradingPairs = _allTradingPairs
            .where((pair) =>
                pair.symbol.toLowerCase().contains(_searchQuery) ||
                pair.baseAsset.toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
  }

  /// 切换关注状态
  void _toggleFavorite(TradingPair pair) {
    setState(() {
      final index = _allTradingPairs.indexWhere((p) => p.symbol == pair.symbol);
      if (index != -1) {
        _allTradingPairs[index] = pair.copyWith(isFavorite: !pair.isFavorite);
        _searchTradingPairs(_searchQuery); // 重新应用搜索过滤
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pair.isFavorite ? '已取消关注 ${pair.symbol}' : '已关注 ${pair.symbol}'),
        duration: const Duration(seconds: 2),
      ),
    );
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
                Text('请先登录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('登录后即可查看和记录交易', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 钱包地址状态栏
            _buildWalletStatusBar(),
            
            // 地址选择组件（可展开）
            if (_showAddressSelection) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: AddressSelectionWidget(
                  onAddressSelected: _onAddressSelected,
                  onAddressAuthorized: _onAddressAuthorized,
                ),
              ),
            ],
            
            // 搜索栏
            _buildSearchBar(),
            
            // Tab导航
            _buildTabBar(),
            
            // Tab内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 关注列表/全部交易对
                  _buildTradingPairsTab(),
                  
                  // 我的交易记录
                  _buildMyTradesTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建搜索栏
  /// 构建钱包地址状态栏
  Widget _buildWalletStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // 减小垂直内边距
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EvaTheme.mechGray.withOpacity(0.8),
            EvaTheme.deepBlack.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EvaTheme.neonGreen.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: EvaTheme.neonGreen.withOpacity(_isAddressAuthorized ? 0.1 : 0.05),
            blurRadius: 20,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: EvaTheme.primaryPurple.withOpacity(_isAddressAuthorized ? 0.05 : 0.02),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          // 钱包图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: _isAddressAuthorized 
                ? EvaTheme.neonGradient
                : LinearGradient(
                    colors: [
                      EvaTheme.warningYellow.withOpacity(0.3),
                      EvaTheme.warningYellow.withOpacity(0.1),
                    ],
                  ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isAddressAuthorized ? EvaTheme.neonGreen : EvaTheme.warningYellow,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isAddressAuthorized ? EvaTheme.neonGreen : EvaTheme.warningYellow)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              _isAddressAuthorized ? Icons.account_balance_wallet : Icons.warning_rounded,
              color: _isAddressAuthorized ? EvaTheme.neonGreen : EvaTheme.warningYellow,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          
          // 地址信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _currentTradingAddress != null ? '交易钱包' : '未设置钱包',
                      style: TextStyle(
                        color: EvaTheme.lightText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 发光装饰线
                    EvaMechDecoration.glowLine(
                      width: 30,
                      height: 1,
                      animated: _isAddressAuthorized,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentTradingAddress != null
                    ? _formatAddress(_currentTradingAddress!.address)
                    : '点击设置钱包地址',
                  style: TextStyle(
                    color: EvaTheme.lightGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 状态指示和操作按钮
          if (_currentTradingAddress != null) ...[
            // 状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: EvaMechDecoration.techBorder(
                color: _isAddressAuthorized ? EvaTheme.neonGreen : EvaTheme.warningYellow,
                glowIntensity: _isAddressAuthorized ? 1.0 : 0.7,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isAddressAuthorized ? '已授权' : '未授权',
                style: TextStyle(
                  color: _isAddressAuthorized ? EvaTheme.neonGreen : EvaTheme.warningYellow,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // 如果已授权，显示断开连接按钮
            if (_isAddressAuthorized) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.3),
                      Colors.red.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: _disconnectWallet,
                  icon: Icon(
                    Icons.power_settings_new,
                    color: Colors.red,
                    size: 16,
                  ),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(24, 24),
                  ),
                  tooltip: '断开连接',
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
          
          // 设置按钮
          Container(
            decoration: BoxDecoration(
              gradient: EvaTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EvaTheme.primaryPurple.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _toggleAddressSelection,
              icon: Icon(
                _showAddressSelection ? Icons.expand_less : Icons.expand_more,
                color: EvaTheme.lightText,
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // 减小垂直内边距
      decoration: BoxDecoration(
        color: EvaTheme.mechGray,
        border: Border(
          bottom: BorderSide(color: EvaTheme.neonGreen.withOpacity(0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: EvaTheme.neonGreen.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchTradingPairs,
        style: const TextStyle(color: EvaTheme.pureWhite),
        decoration: InputDecoration(
          hintText: '搜索交易对 (如: BTC, ETH)',
          hintStyle: TextStyle(color: EvaTheme.textGray),
          prefixIcon: Icon(Icons.search, color: EvaTheme.neonGreen),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: EvaTheme.neonGreen),
                  onPressed: () {
                    _searchController.clear();
                    _searchTradingPairs('');
                  },
                )
              : Icon(Icons.trending_up, color: EvaTheme.textGray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: EvaTheme.borderGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: EvaTheme.neonGreen, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: EvaTheme.borderGray),
          ),
          filled: true,
          fillColor: EvaTheme.deepBlack,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // 减小垂直内边距
        ),
      ),
    );
  }

  /// 构建Tab栏
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: EvaTheme.mechGray,
        border: Border(
          bottom: BorderSide(color: EvaTheme.neonGreen.withOpacity(0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: EvaTheme.neonGreen,
        labelColor: EvaTheme.neonGreen,
        unselectedLabelColor: EvaTheme.textGray,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, size: 18, color: EvaTheme.evaYellow),
                const SizedBox(width: 8),
                Text(
                  '关注列表 (${_allTradingPairs.where((p) => p.isFavorite).length})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 18),
                SizedBox(width: 8),
                Text('我的交易', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建交易对列表标签页
  Widget _buildTradingPairsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayPairs = _searchQuery.isEmpty 
        ? _filteredTradingPairs.where((p) => p.isFavorite).toList()
        : _filteredTradingPairs;

    if (displayPairs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.star_border : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '还没有关注的交易对' : '未找到匹配的交易对',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty ? '搜索并关注感兴趣的交易对' : '尝试其他搜索关键词',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displayPairs.length,
      itemBuilder: (context, index) {
        return _buildTradingPairTile(displayPairs[index]);
      },
    );
  }

  /// 构建交易对列表项
  Widget _buildTradingPairTile(TradingPair pair) {
    final priceColor = pair.isPriceUp
        ? EvaTheme.neonGreen  // 上涨用荧光绿
        : pair.isPriceDown
            ? EvaTheme.errorRed  // 下跌用错误红
            : EvaTheme.textGray;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: pair.isFavorite 
            ? Border.all(color: EvaTheme.neonGreen.withOpacity(0.3), width: 1)
            : null,
        boxShadow: pair.isFavorite ? [
          BoxShadow(
            color: EvaTheme.neonGreen.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // 减小垂直内边距
        leading: CircleAvatar(
          backgroundColor: pair.isFavorite 
              ? EvaTheme.neonGreen.withOpacity(0.2)
              : EvaTheme.primaryPurple.withOpacity(0.2),
          child: Text(
            pair.baseAsset.substring(0, 1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pair.isFavorite ? EvaTheme.neonGreen : EvaTheme.primaryPurple,
              fontFamily: 'monospace',
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pair.symbol,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: pair.isFavorite ? EvaTheme.neonGreen : EvaTheme.pureWhite,
                    fontFamily: 'monospace',
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Vol: ${pair.formattedVolume}',
                  style: const TextStyle(color: EvaTheme.textGray, fontSize: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${pair.formattedPrice}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: priceColor,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priceColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: priceColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    pair.formattedPriceChangePercent,
                    style: TextStyle(
                      color: priceColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            pair.isFavorite ? Icons.star : Icons.star_border,
            color: pair.isFavorite ? EvaTheme.evaYellow : EvaTheme.textGray,
            size: 24,
          ),
          onPressed: () => _toggleFavorite(pair),
        ),
        onTap: () {
          // TODO: 导航到交易详情页面
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('点击了 ${pair.symbol} - 功能开发中'),
              backgroundColor: EvaTheme.primaryPurple,
            ),
          );
        },
        onLongPress: () {
          // TODO: 显示编辑选项
          _showTradingPairOptions(pair);
        },
      ),
    );
  }

  /// 显示交易对选项
  void _showTradingPairOptions(TradingPair pair) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                pair.isFavorite ? Icons.star_border : Icons.star,
                color: Colors.amber,
              ),
              title: Text(pair.isFavorite ? '取消关注' : '添加关注'),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(pair);
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart, color: Colors.blue),
              title: const Text('查看图表'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('查看 ${pair.symbol} 图表 - 功能开发中')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
              title: const Text('快速交易'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${pair.symbol} 快速交易 - 功能开发中')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建我的交易标签页
  Widget _buildMyTradesTab() {
    return Column(
      children: [
        // 添加交易按钮
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: EvaTheme.techGradient,
              boxShadow: [
                BoxShadow(
                  color: EvaTheme.neonGreen.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _showAddTradeDialog,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                '手动记录交易',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: EvaTheme.deepBlack,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        
        // 交易记录列表
        Expanded(
          child: _userTrades.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: EvaTheme.textGray),
                      const SizedBox(height: 16),
                      Text(
                        '还没有交易记录',
                        style: TextStyle(fontSize: 18, color: EvaTheme.textGray),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '连接钱包后将自动同步链上交易',
                        style: TextStyle(color: EvaTheme.textGray),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _userTrades.length,
                  itemBuilder: (context, index) {
                    return _buildTradeItem(_userTrades[index]);
                  },
                ),
        ),
      ],
    );
  }

  /// 构建交易记录项
  Widget _buildTradeItem(Trade trade) {
    final sideColor = trade.side == 'buy' ? EvaTheme.neonGreen : EvaTheme.errorRed;
    final sideText = trade.side == 'buy' ? '买入' : '卖出';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: EvaTheme.mechGray,
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sideColor.withOpacity(0.2)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: sideColor.withOpacity(0.2),
            child: Icon(
              trade.side == 'buy' ? Icons.trending_up : Icons.trending_down,
              color: sideColor,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trade.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: EvaTheme.pureWhite,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                sideText,
                style: TextStyle(
                  color: sideColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '数量: ${trade.size}',
                    style: const TextStyle(color: EvaTheme.textGray),
                  ),
                  Text(
                    '价格: \$${trade.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: EvaTheme.pureWhite,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '时间: ${_formatTime(trade.timestamp)}',
                    style: const TextStyle(color: EvaTheme.textGray),
                  ),
                  Text(
                    '手续费: \$${trade.fee?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(color: EvaTheme.textGray),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trade.status == 'filled' 
                  ? EvaTheme.neonGreen.withOpacity(0.2) 
                  : EvaTheme.warningOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: trade.status == 'filled' 
                    ? EvaTheme.neonGreen.withOpacity(0.5)
                    : EvaTheme.warningOrange.withOpacity(0.5),
              ),
            ),
            child: Text(
              trade.status == 'filled' ? '已成交' : '待成交',
              style: TextStyle(
                color: trade.status == 'filled' ? EvaTheme.neonGreen : EvaTheme.warningOrange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 切换地址选择面板显示状态
  void _toggleAddressSelection() {
    setState(() {
      _showAddressSelection = !_showAddressSelection;
    });
  }

  /// 地址选择回调
  void _onAddressSelected(AddressOption address) {
    setState(() {
      _currentTradingAddress = address;
      _isAddressAuthorized = _hyperliquidService.isAddressAuthorized(address.address);
    });
    
    // 设置为当前交易地址
    _hyperliquidService.setTradingAddress(address.address);
  }

  /// 断开钱包连接
  void _disconnectWallet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvaTheme.mechGray,
        title: Text(
          '断开连接',
          style: TextStyle(color: EvaTheme.lightText),
        ),
        content: Text(
          '确定要断开当前钱包连接吗？这将清除当前的交易地址设置。',
          style: TextStyle(color: EvaTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(color: EvaTheme.textGray),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentTradingAddress = null;
                _isAddressAuthorized = false;
                _showAddressSelection = false;
              });
              
              // 清除Hyperliquid服务中的地址设置
              _hyperliquidService.clearTradingAddress();
              
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('钱包连接已断开'),
                  backgroundColor: EvaTheme.neonGreen,
                ),
              );
            },
            child: Text(
              '确认',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 地址授权成功回调
  void _onAddressAuthorized(String address) {
    setState(() {
      _isAddressAuthorized = true;
      _showAddressSelection = false; // 授权成功后收起面板
    });
    
    // 刷新当前地址状态
    _checkCurrentTradingAddress();
  }

  /// 格式化地址显示
  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}