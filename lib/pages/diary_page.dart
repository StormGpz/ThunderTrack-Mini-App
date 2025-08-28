import 'package:flutter/material.dart';
import '../models/trading_diary.dart';
import '../widgets/diary_list.dart';
import '../widgets/create_diary_step1.dart';
import '../services/cast_diary_service.dart';
import '../theme/eva_theme.dart';

/// 交易日记页面，展示自己的日记和广场内容
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<TradingDiary> _myDiaries = [];
  final List<TradingDiary> _publicDiaries = [];
  bool _isLoading = false;
  final CastDiaryService _castService = CastDiaryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDiaries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载日记数据
  Future<void> _loadDiaries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 并行加载我的日记和广场日记
      final futures = await Future.wait([
        _castService.getUserDiaries('123', limit: 50), // TODO: 使用真实的用户FID
        _castService.getPublicDiaries(limit: 100),
      ]);
      
      if (mounted) {
        setState(() {
          _myDiaries.clear();
          _myDiaries.addAll(futures[0]);
          
          _publicDiaries.clear();
          _publicDiaries.addAll(futures[1]);
        });
      }
    } catch (e) {
      debugPrint('加载日记失败: $e');
      // 如果API调用失败，添加一些模拟数据用于展示
      if (mounted) {
        setState(() {
          _addMockDiaries();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 添加模拟日记数据
  void _addMockDiaries() {
    final now = DateTime.now();
    
    // 我的日记示例
    _myDiaries.addAll([
      TradingDiary(
        id: 'mock1',
        authorFid: '123',
        title: 'ETH/USDT 突破交易复盘',
        content: '今天ETH突破了2450关键阻力位，果断入场。市场情绪转强，成交量放大确认突破有效。这次交易让我深刻体会到突破交易的重要性，严格按照策略执行获得了不错的收益。',
        type: DiaryType.singleTrade,
        symbol: 'ETH/USDT',
        tags: ['#Breakout', '#ETH', '#DeFi', '#Profit'],
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        isPublic: true,
        rating: 4.5,
      ),
      TradingDiary(
        id: 'mock2',
        authorFid: '123',
        title: 'SOL网格策略本周总结',
        content: 'SOL在95-105区间震荡，网格策略表现不错。市场缺乏明确方向，适合低频套利。本周通过网格交易获得稳定收益，验证了区间交易策略的有效性。',
        type: DiaryType.strategySummary,
        symbol: 'SOL/USDT',
        tags: ['#Grid', '#SOL', '#Range', '#Strategy'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        isPublic: true,
        rating: 4.0,
        periodStart: now.subtract(const Duration(days: 7)),
        periodEnd: now.subtract(const Duration(days: 1)),
      ),
    ]);
    
    // 广场日记示例
    _publicDiaries.addAll([
      ..._myDiaries, // 包含自己的
      TradingDiary(
        id: 'public1',
        authorFid: '456',
        title: 'BTC趋势跟随策略分享',
        content: 'BTC重回上升趋势，45000是关键支撑。机构资金持续流入，看好后市。分享一些趋势跟随的心得体会...',
        type: DiaryType.freeForm,
        symbol: 'BTC/USDT',
        tags: ['#BTC', '#Trend', '#Bullish'],
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        isPublic: true,
        likes: 12,
        comments: 3,
        reposts: 2,
      ),
      TradingDiary(
        id: 'public2',
        authorFid: '789',
        title: 'LINK反转交易心得',
        content: 'LINK严重超卖，技术面显示反转信号。14.5附近是强支撑，适合抄底。这次反转交易让我学到了耐心等待的重要性。',
        type: DiaryType.singleTrade,
        symbol: 'LINK/USDT',
        tags: ['#LINK', '#Reversal', '#Oversold'],
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 8)),
        isPublic: true,
        likes: 8,
        comments: 5,
        reposts: 1,
        rating: 3.5,
      ),
    ]);
  }

  /// 导航到写日记流程
  void _showCreateDiaryOptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateDiaryStep1(),
      ),
    ).then((_) {
      // 从写日记页面返回后刷新数据
      _loadDiaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvaTheme.deepBlack,
      body: Column(
        children: [
          // 自定义Tab栏
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EvaTheme.mechGray.withValues(alpha: 0.9),
                  EvaTheme.deepBlack,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: EvaTheme.neonGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: EvaTheme.neonGreen.withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('我的日记'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public, size: 20),
                      SizedBox(width: 8),
                      Text('广场'),
                    ],
                  ),
                ),
              ],
              labelColor: EvaTheme.neonGreen,
              unselectedLabelColor: EvaTheme.textGray,
              indicatorColor: EvaTheme.neonGreen,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
            ),
          ),
          // Tab内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 我的日记
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DiaryList(
                        diaries: _myDiaries,
                        emptyWidget: _buildEmptyMyDiary(),
                        onRefresh: _loadDiaries,
                      ),
                // 广场日记
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DiaryList(
                        diaries: _publicDiaries,
                        emptyWidget: _buildEmptyPublicDiary(),
                        onRefresh: _loadDiaries,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建我的日记空状态
  Widget _buildEmptyMyDiary() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: EvaTheme.textGray,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有日记',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: EvaTheme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '记录您的交易心得和市场观察',
            style: TextStyle(
              color: EvaTheme.textGray.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: EvaTheme.neonGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton.icon(
              onPressed: _showCreateDiaryOptions,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                '写第一篇日记',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建广场空状态
  Widget _buildEmptyPublicDiary() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public_off,
            size: 80,
            color: EvaTheme.textGray,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无广场内容',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: EvaTheme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '成为第一个分享交易日记的人',
            style: TextStyle(
              color: EvaTheme.textGray.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}