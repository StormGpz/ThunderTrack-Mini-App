import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'pages/diary_page.dart';
import 'pages/trading_page.dart';
import 'pages/settings_page.dart';

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
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366f1),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
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

  final List<Widget> _pages = [
    const TradingPage(),
    const DiaryPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // 初始化用户状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: '交易',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '日记',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}