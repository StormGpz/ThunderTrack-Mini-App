import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'pages/diary_page.dart';
import 'pages/trading_page.dart';
import 'pages/settings_page.dart';
import 'pages/profile_page.dart';
import 'pages/hyperliquid_test_page.dart';
import 'widgets/frame_diary_detail_page.dart';
import 'utils/api_client.dart';
import 'services/hyperliquid_service.dart';
import 'widgets/eva_floating_bottom_bar.dart';
import 'widgets/eva_mech_decoration.dart';
import 'theme/eva_theme.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 API 客户端
  ApiClient().initialize();
  
  // 初始化 Hyperliquid 服务
  await HyperliquidService().initialize();
  
  runApp(const ThunderTrackApp());
}

class ThunderTrackApp extends StatelessWidget {
  const ThunderTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'ThunderTrack - EVA Edition',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: EvaTheme.lightTheme,
            darkTheme: EvaTheme.darkTheme,
            locale: settings.locale,
            home: const MainPage(),
          );
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1; // 默认显示日记页面
  late final PageController _pageController;

  final List<EvaTabItem> _tabItems = const [
    EvaTabItem(icon: Icons.trending_up, label: '交易'),
    EvaTabItem(icon: Icons.book, label: '日记'),
    EvaTabItem(icon: Icons.settings, label: '设置'),
  ];

  final List<Widget> _pages = [
    const TradingPage(),
    const DiaryPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    
    // 初始化用户状态
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initialize();
      
      // 通知 Mini App 准备就绪（关键！）
      await userProvider.notifyMiniAppReady();
      
      // 检查URL参数，如果有diary参数则跳转到详情页
      await _checkUrlParameters();
      
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 检查URL参数并处理Frame跳转
  Future<void> _checkUrlParameters() async {
    try {
      final currentUrl = Uri.base.toString();
      final uri = Uri.parse(currentUrl);
      
      // 检查是否有pair参数（来自Frame点击）
      if (uri.queryParameters.containsKey('pair')) {
        final pair = uri.queryParameters['pair'];
        final pnl = double.tryParse(uri.queryParameters['pnl'] ?? '0');
        final strategy = uri.queryParameters['strategy'];
        final sentiment = uri.queryParameters['sentiment'];
        
        if (pair != null && mounted) {
          // 生成日记ID
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final diaryId = '${pair.replaceAll('/', '')}-$timestamp';
          
          
          // 延迟一下确保页面已初始化
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FrameDiaryDetailPage(
                  diaryId: diaryId,
                  pair: pair,
                  pnl: pnl,
                  strategy: strategy,
                  sentiment: sentiment,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Ignore URL parsing errors during app initialization
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: EvaTheme.deepBlack,
          extendBody: true, // 让内容延伸到底部导航栏下方
          appBar: _buildEvaAppBar(userProvider, context),
          body: Stack(
            children: [
              // 机甲背景装饰
              EvaMechDecoration.mechLinesBackground(
                opacity: 0.08,
                animated: true,
              ),
              
              // 主要内容
              PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _selectedIndex = index),
                children: _pages,
              ),
              
              // 角落装饰
              EvaMechDecoration.cornerDecoration(
                size: 40,
                alignment: Alignment.topLeft,
              ),
              EvaMechDecoration.cornerDecoration(
                size: 40,
                alignment: Alignment.bottomRight,
              ),
            ],
          ),
          bottomNavigationBar: EvaFloatingBottomBar(
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
            items: _tabItems,
          ),
        );
      },
    );
  }

  /// 触发Farcaster连接
  void _connectFarcaster(UserProvider userProvider) {
    // 检查是否在 Mini App 环境中
    if (userProvider.isMiniAppEnvironment && userProvider.isMiniAppSdkAvailable) {
      // 在 Mini App 环境中，直接尝试获取用户信息
      _performFarcasterLogin(userProvider);
    } else {
      // 不在 Mini App 环境中，显示模拟登录对话框
      _showSimulationDialog(userProvider);
    }
  }

  /// 执行真实的 Farcaster 登录
  void _performFarcasterLogin(UserProvider userProvider) async {
    try {
      final success = await userProvider.loginFromFarcaster();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Farcaster 登录成功！')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录失败：${userProvider.error ?? "未知错误"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录出错：$e')),
        );
      }
    }
  }

  /// 显示模拟登录对话框
  void _showSimulationDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('连接 Farcaster'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('未检测到 Farcaster Mini App 环境'),
            const SizedBox(height: 8),
            Text(
              '当前环境：${userProvider.environmentInfo['platform']} - ${userProvider.environmentInfo['userAgent']?.toString().split(' ').first ?? 'Unknown'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '使用模拟登录进行测试',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                // 使用模拟登录
                await userProvider.simulateLogin('demo_farcaster_user');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('模拟登录成功！')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('登录失败：$e')),
                  );
                }
              }
            },
            child: const Text('模拟登录'),
          ),
        ],
      ),
    );
  }

  /// 显示调试面板
  void _showDebugPanel(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report, size: 20),
            const SizedBox(width: 8),
            const Text('调试信息'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.clear_all, size: 18),
              tooltip: '清空日志',
              onPressed: () {
                userProvider.clearDebugLogs();
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 环境状态
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 环境状态', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Mini App: ${userProvider.isMiniAppEnvironment ? "✅" : "❌"}'),
                    Text('SDK可用: ${userProvider.isMiniAppSdkAvailable ? "✅" : "❌"}'),
                    Text('已登录: ${userProvider.isAuthenticated ? "✅" : "❌"}'),
                    Text('平台: ${userProvider.environmentInfo['platform']}'),
                    if (userProvider.isAuthenticated && userProvider.currentUser != null)
                      Text('用户: ${userProvider.currentUser!.displayName}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 调试日志
              const Text('📝 调试日志:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: userProvider.debugLogs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无调试日志\n尝试点击登录或刷新页面',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: userProvider.debugLogs.length,
                          itemBuilder: (context, index) {
                            final log = userProvider.debugLogs[index];
                            Color textColor = Colors.white;
                            
                            // 根据日志内容设置颜色
                            if (log.contains('✅') || log.contains('成功')) {
                              textColor = Colors.green[300]!;
                            } else if (log.contains('❌') || log.contains('失败') || log.contains('错误')) {
                              textColor = Colors.red[300]!;
                            } else if (log.contains('⚠️') || log.contains('警告')) {
                              textColor = Colors.orange[300]!;
                            } else if (log.contains('🔍') || log.contains('🔄')) {
                              textColor = Colors.blue[300]!;
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: SelectableText(
                                log,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
          if (!userProvider.isAuthenticated && userProvider.isMiniAppEnvironment)
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _connectFarcaster(userProvider);
              },
              child: const Text('尝试登录'),
            ),
        ],
      ),
    );
  }

  /// 构建EVA风格的AppBar
  AppBar _buildEvaAppBar(UserProvider userProvider, BuildContext context) {
    return AppBar(
      backgroundColor: EvaTheme.deepBlack,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            if (userProvider.isAuthenticated) {
              // 已登录：跳转个人页面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            } else {
              // 未登录：触发登录
              _connectFarcaster(userProvider);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: userProvider.isAuthenticated 
                ? EvaTheme.neonGradient
                : LinearGradient(
                    colors: [
                      EvaTheme.primaryPurple.withValues(alpha: 0.5),
                      EvaTheme.primaryPurple.withValues(alpha: 0.2),
                    ],
                  ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: userProvider.isAuthenticated 
                  ? EvaTheme.neonGreen 
                  : EvaTheme.primaryPurple,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (userProvider.isAuthenticated 
                    ? EvaTheme.neonGreen 
                    : EvaTheme.primaryPurple).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              backgroundImage: userProvider.isAuthenticated && 
                              userProvider.currentUser?.avatarUrl != null
                  ? NetworkImage(userProvider.currentUser!.avatarUrl!)
                  : null,
              child: userProvider.isAuthenticated && 
                     userProvider.currentUser?.avatarUrl == null
                  ? (userProvider.currentUser?.isVerified == true
                      ? Icon(Icons.verified, 
                          color: EvaTheme.neonGreen, size: 16)
                      : Icon(Icons.person, 
                          color: EvaTheme.neonGreen, size: 16))
                  : (!userProvider.isAuthenticated 
                      ? Icon(Icons.person_outline, 
                          color: EvaTheme.primaryPurple, size: 16)
                      : null),
            ),
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EvaTheme.mechGray.withValues(alpha: 0.8),
              EvaTheme.deepBlack.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: EvaTheme.neonGreen.withValues(alpha: 0.5), 
            width: 1
          ),
          boxShadow: [
            BoxShadow(
              color: EvaTheme.neonGreen.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: EvaTheme.primaryPurple.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 闪电图标带动画效果
            ShaderMask(
              shaderCallback: (bounds) => EvaTheme.techGradient.createShader(bounds),
              child: Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            // 应用标题 - 去掉横线，调整字体大小防止溢出
            Flexible(
              child: ShaderMask(
                shaderCallback: (bounds) => EvaTheme.techGradient.createShader(bounds),
                child: Text(
                  'THUNDERTRACK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // 减小字体避免溢出
                    letterSpacing: 1.5, // 减小字母间距
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        // 调试面板按钮（仅在开发环境或Farcaster环境显示）
        if (kDebugMode || userProvider.isMiniAppEnvironment)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: EvaTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EvaTheme.primaryPurple.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.bug_report, 
                color: EvaTheme.lightText, size: 20),
              tooltip: '调试日志',
              onPressed: () => _showDebugPanel(context, userProvider),
            ),
          ),
        
        if (!userProvider.isAuthenticated) ...[
          // 未登录时显示登录按钮
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: EvaTheme.neonGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: EvaTheme.neonGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextButton(
              onPressed: () => _connectFarcaster(userProvider),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'LOGIN',
                style: TextStyle(
                  color: EvaTheme.deepBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ] else ...[
          // 已登录时显示通知图标
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  EvaTheme.primaryPurple.withValues(alpha: 0.3),
                  EvaTheme.primaryPurple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EvaTheme.primaryPurple.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications, 
                color: EvaTheme.lightText),
              tooltip: '通知',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('通知功能待实现'),
                    backgroundColor: EvaTheme.primaryPurple,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}