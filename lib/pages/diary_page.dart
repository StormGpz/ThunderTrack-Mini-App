import 'package:flutter/material.dart';
import '../models/trading_diary.dart';
import '../services/diary_template_service.dart';
import '../widgets/diary_list.dart';
import '../widgets/create_diary_page.dart';
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

    // TODO: 从IPFS或本地存储加载日记
    // 模拟数据
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示创建日记模板选择
  void _showCreateDiaryOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖拽指示器
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '选择日记模板',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...DiaryTemplateService.getAllTemplates().map(
              (template) => _buildTemplateOption(template),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 构建模板选项
  Widget _buildTemplateOption(DiaryTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              template.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          template.description,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _navigateToCreateDiary(template);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  /// 导航到创建日记页面
  void _navigateToCreateDiary(DiaryTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDiaryPage(
          template: template,
          onDiaryCreated: (diary) {
            setState(() {
              _myDiaries.insert(0, diary);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 自定义Tab栏
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EvaTheme.mechGray.withOpacity(0.9),
                  EvaTheme.deepBlack,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: EvaTheme.neonGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: EvaTheme.neonGreen.withOpacity(0.1),
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
                // 广场
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有日记',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '记录交易心得，分享策略思考',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateDiaryOptions,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('写第一篇日记'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
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
            Icons.public_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无公开日记',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '成为第一个分享交易心得的人',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}