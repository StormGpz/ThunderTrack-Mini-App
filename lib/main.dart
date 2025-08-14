import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'pages/diary_page.dart';
import 'pages/trading_page.dart';
import 'pages/settings_page.dart';
import 'pages/profile_page.dart';

void main() {
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
            title: 'ThunderTrack',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366f1)),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF6366f1),
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
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366f1),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
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
            ),
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
      
      // 调试信息
      print('🔍 用户初始化完成:');
      print('   环境: ${userProvider.isMiniAppEnvironment ? "Farcaster Mini App" : "普通浏览器"}');
      print('   SDK可用: ${userProvider.isMiniAppSdkAvailable}');
      print('   已登录: ${userProvider.isAuthenticated}');
      if (userProvider.isAuthenticated) {
        print('   用户: ${userProvider.currentUser?.displayName ?? userProvider.currentUser?.username}');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                    // 未登录：触发登录
                    _connectFarcaster(userProvider);
                  }
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: userProvider.isAuthenticated 
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.3),
                  child: userProvider.isAuthenticated
                      ? (userProvider.currentUser?.isVerified == true
                          ? const Icon(Icons.verified, color: Colors.white, size: 16)
                          : const Icon(Icons.person, color: Colors.white, size: 16))
                      : const Icon(Icons.person_outline, color: Colors.white, size: 16),
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
                      const SnackBar(content: Text('通知功能待实现')),
                    );
                  },
                ),
              ],
            ],
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.trending_up),
                label: '交易',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1 ? Colors.orange : Colors.orange.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.book, color: Colors.white, size: 20),
                ),
                label: '日记',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: '设置',
              ),
            ],
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
}