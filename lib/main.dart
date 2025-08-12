import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'pages/trading_page.dart';
import 'pages/diary_page.dart';
import 'pages/settings_page.dart';
import 'pages/profile_page.dart';
import 'providers/user_provider.dart';
import 'providers/trading_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化HTTP客户端
  ApiClient().initialize();
  
  // 初始化设置Provider
  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize();
  
  runApp(ThunderTrackApp(settingsProvider: settingsProvider));
}

/// ThunderTrack应用的根组件，配置应用主题和路由
class ThunderTrackApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  
  const ThunderTrackApp({
    super.key,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TradingProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: settings.isChineseLocale ? 'ThunderTrack - 交易日记' : 'ThunderTrack - Trading Diary',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            locale: settings.locale,
            home: const HomePage(),
          );
        },
      ),
    );
  }

  /// 构建浅色主题
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// 构建深色主题
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.grey[850],
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Colors.indigo[300],
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[900],
      ),
    );
  }
}

/// 主页面组件，包含底部导航和页面切换功能
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 当前选中的底部导航索引
  int _currentIndex = 0;
  
  /// 页面控制器，管理页面切换
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // 初始化 Mini App 功能
    _initializeMiniApp();
  }
  
  /// 初始化 Mini App 功能
  void _initializeMiniApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // 初始化用户状态（这里会检查 Mini App 环境）
      await userProvider.initialize();
      
      // 通知 Mini App 准备就绪
      await userProvider.notifyMiniAppReady();
      
      // 在调试模式下显示环境信息
      if (kDebugMode) {
        final envInfo = userProvider.environmentInfo;
        debugPrint('=== Mini App Environment ===');
        envInfo.forEach((key, value) {
          debugPrint('$key: $value');
        });
        debugPrint('===========================');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 处理底部导航栏点击事件，实现页面切换
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
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
        // 直接显示主应用，登录状态影响右上角显示
        return _buildMainApp(userProvider);
      },
    );
  }

  /// 构建主应用界面
  Widget _buildMainApp(UserProvider userProvider) {
    return Scaffold(
      appBar: AppBar(
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
                // 未登录：触发Farcaster连接
                _connectFarcaster(userProvider);
              }
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: userProvider.isAuthenticated 
                  ? Colors.indigo.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.3),
              child: userProvider.isAuthenticated
                  ? (userProvider.currentUser?.isVerified == true
                      ? const Icon(Icons.verified, color: Colors.indigo, size: 16)
                      : const Icon(Icons.person, color: Colors.indigo, size: 16))
                  : const Icon(Icons.person_outline, color: Colors.grey, size: 16),
            ),
          ),
        ),
        title: const Text('⚡ ThunderTrack', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (!userProvider.isAuthenticated) ...[
            // 未登录时显示登录按钮
            TextButton(
              onPressed: () => _connectFarcaster(userProvider),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ] else ...[
            // 已登录时显示通知图标
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: '通知',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('通知功能待实现'))
                );
              },
            ),
          ],
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          TradingPage(),
          DiaryPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), 
            label: '交易'
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentIndex == 1 ? Colors.orange : Colors.orange.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.book, color: Colors.white, size: 20),
            ),
            label: '日记'
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings), 
            label: '设置'
          ),
        ],
      ),
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
            const SnackBar(content: Text('Farcaster 登录成功！'))
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录失败：${userProvider.error ?? "未知错误"}'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录出错：$e'))
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
            Icon(Icons.info_outline, size: 48, color: Colors.orange),
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
                    const SnackBar(content: Text('模拟登录成功！'))
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('登录失败：$e'))
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
}