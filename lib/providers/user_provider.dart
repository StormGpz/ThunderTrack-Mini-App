import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../models/user.dart';
import '../services/neynar_service.dart';
import '../services/farcaster_miniapp_service.dart';
import '../services/wallet_service.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户状态管理Provider
class UserProvider extends ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();
  factory UserProvider() => _instance;
  UserProvider._internal() {
    // 监听钱包服务状态变化
    _walletService.addListener(_onWalletStateChanged);
  }

  final NeynarService _neynarService = NeynarService();
  final FarcasterMiniAppService _miniAppService = FarcasterMiniAppService();
  final WalletService _walletService = WalletService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  
  // 调试日志列表
  final List<String> _debugLogs = [];
  final int _maxLogs = 20; // 最多保存20条日志

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  List<String> get debugLogs => List.unmodifiable(_debugLogs);
  
  // Mini App 相关 getters
  bool get isMiniAppEnvironment => _miniAppService.isMiniAppEnvironment;
  bool get isMiniAppSdkAvailable => _miniAppService.isSdkAvailable;
  bool get hasBuiltinWallet => _miniAppService.hasBuiltinWallet;
  Map<String, dynamic> get environmentInfo => _miniAppService.getEnvironmentInfo();

  // 钱包相关 getters
  String? get walletAddress => _walletService.currentAccount;
  bool get isWalletConnected => _walletService.isConnected;
  String get walletStatusText => _walletService.isConnected
      ? '已连接: ${_walletService.currentAccount?.substring(0, 6)}...${_walletService.currentAccount?.substring(38)}'
      : '未连接';
  bool get isWeb3Available => _walletService.isWeb3Available;

  /// 钱包状态变化处理
  void _onWalletStateChanged() {
    addDebugLog('🔄 钱包状态发生变化');
    addDebugLog('连接状态: ${_walletService.isConnected}');
    if (_walletService.currentAccount != null) {
      addDebugLog('钱包地址: ${_walletService.currentAccount}');
    }

    // 如果钱包连接但用户未登录，尝试自动登录
    if (_walletService.isConnected && !_isAuthenticated) {
      addDebugLog('🚀 检测到钱包连接，尝试自动登录...');
      _autoLoginWithWallet(); // 改为异步方法
    }

    // 如果钱包断开连接，清除钱包用户
    if (!_walletService.isConnected && _currentUser?.walletAddress != null) {
      addDebugLog('🔌 钱包已断开，清除钱包地址');
      if (_currentUser!.fid.startsWith('wallet_')) {
        // 如果是纯钱包用户，退出登录
        logout();
      } else {
        // 如果是关联用户，只清除钱包地址
        _currentUser = _currentUser!.copyWith(walletAddress: null);
        _saveUserToLocal(_currentUser!);
      }
    }

    notifyListeners();
  }

  /// 自动钱包登录（异步处理）
  Future<void> _autoLoginWithWallet() async {
    try {
      if (_walletService.currentAccount != null) {
        addDebugLog('🔄 开始自动钱包登录...');
        final success = await _signInWithWalletAddress(_walletService.currentAccount!);
        addDebugLog(success ? '✅ 自动钱包登录成功' : '❌ 自动钱包登录失败');
      }
    } catch (e) {
      addDebugLog('❌ 自动钱包登录异常: $e');
    }
  }

  /// 使用钱包地址登录（不触发连接）
  Future<bool> _signInWithWalletAddress(String walletAddress) async {
    try {
      addDebugLog('📋 使用钱包地址登录: $walletAddress');

      // 通过钱包地址查找Farcaster账户
      final farcasterUser = await _neynarService.getUserByWalletAddress(walletAddress);

      if (farcasterUser != null) {
        // 找到关联账户
        addDebugLog('✅ 找到关联的Farcaster账户: ${farcasterUser.username}');
        final user = farcasterUser.copyWith(walletAddress: walletAddress);

        await _saveUserToLocal(user);
        _currentUser = user;
        _isAuthenticated = true;

        addDebugLog('🎉 Farcaster关联用户登录完成: ${user.username}');
        notifyListeners();
        return true;
      } else {
        // 创建钱包用户
        addDebugLog('⚠️ 钱包地址未关联Farcaster账户，创建钱包用户');
        final walletUser = User(
          fid: 'wallet_${walletAddress.substring(2, 8)}',
          username: walletAddress.substring(0, 10),
          displayName: '${walletAddress.substring(0, 6)}...${walletAddress.substring(38)}',
          avatarUrl: null,
          bio: '钱包用户 - 可进行交易操作',
          walletAddress: walletAddress,
          followers: [],
          following: [],
          isVerified: false,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        await _saveUserToLocal(walletUser);
        _currentUser = walletUser;
        _isAuthenticated = true;

        addDebugLog('✅ 钱包用户登录完成');
        notifyListeners();
        return true;
      }
    } catch (e) {
      addDebugLog('❌ 钱包地址登录失败: $e');
      return false;
    }
  }

  /// 添加调试日志
  void addDebugLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    
    _debugLogs.insert(0, logMessage); // 新日志在顶部
    
    // 限制日志数量
    if (_debugLogs.length > _maxLogs) {
      _debugLogs.removeRange(_maxLogs, _debugLogs.length);
    }
    
    debugPrint(logMessage); // 同时输出到控制台
    notifyListeners(); // 通知UI更新
  }
  
  /// 清空调试日志
  void clearDebugLogs() {
    _debugLogs.clear();
    notifyListeners();
  }

  /// 初始化用户状态
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // 记录环境信息用于调试
      _miniAppService.logEnvironmentInfo();

      // 🔑 优先检查已连接的钱包
      addDebugLog('🔍 检查已连接的钱包...');
      await _walletService.checkExistingConnection();

      if (_walletService.isConnected) {
        addDebugLog('✅ 发现已连接钱包: ${_walletService.currentAccount}');
        // 尝试通过钱包地址查找关联的Farcaster用户
        final farcasterUser = await _neynarService.getUserByWalletAddress(_walletService.currentAccount!);
        if (farcasterUser != null) {
          addDebugLog('🎉 找到关联的Farcaster用户: ${farcasterUser.username}');
          final user = farcasterUser.copyWith(walletAddress: _walletService.currentAccount);
          await _saveUserToLocal(user);
          _currentUser = user;
          _isAuthenticated = true;
          _setLoading(false);
          notifyListeners();
          return;
        } else {
          addDebugLog('⚠️ 钱包未关联Farcaster账户，创建钱包用户');
          // 创建钱包用户
          final walletUser = User(
            fid: 'wallet_${_walletService.currentAccount!.substring(2, 8)}',
            username: 'wallet_${_walletService.currentAccount!.substring(2, 8)}',
            displayName: '钱包用户 ${_walletService.currentAccount!.substring(0, 6)}...${_walletService.currentAccount!.substring(38)}',
            avatarUrl: null,
            bio: '通过钱包连接的用户，暂未关联Farcaster账户',
            walletAddress: _walletService.currentAccount!,
            followers: [],
            following: [],
            isVerified: false,
            createdAt: DateTime.now(),
            lastActiveAt: DateTime.now(),
          );
          await _saveUserToLocal(walletUser);
          _currentUser = walletUser;
          _isAuthenticated = true;
          _setLoading(false);
          notifyListeners();
          return;
        }
      }

      // 在Farcaster Mini App环境中，优先尝试无感登录
      if (_miniAppService.isMiniAppEnvironment) {
        debugPrint('🚀 Farcaster Mini App环境，启动无感登录流程...');

        // 先恢复本地状态作为备用
        await _restoreLocalUser();

        // 立即尝试从Farcaster获取用户信息（无感登录）
        try {
          // 给SDK一点时间加载
          await Future.delayed(const Duration(milliseconds: 300));

          if (_miniAppService.isSdkAvailable) {
            debugPrint('📦 SDK已就绪，立即尝试无感登录...');
            final farcasterUser = await _miniAppService.getFarcasterUser()
                .timeout(const Duration(seconds: 3));
                
            if (farcasterUser != null && farcasterUser.isNotEmpty) {
              debugPrint('🎉 无感登录成功！');
              await _processFarcasterUser(farcasterUser);
              _setError(null);
              _setLoading(false);
              return; // 成功登录，直接返回
            }
          }
          
          debugPrint('⏳ SDK可能还在加载，启动后台重试...');
        } catch (e) {
          debugPrint('⚠️ 立即登录失败，启动后台重试: $e');
        }
        
        // 如果立即登录没成功，启动后台异步重试
        _setLoading(false);
        _tryGetFarcasterUserAsync();
        return;
      }
      
      // 在普通浏览器环境中，只恢复本地存储
      debugPrint('🌐 普通浏览器环境，恢复本地用户状态');
      await _restoreLocalUser();
    } catch (e) {
      _setError('初始化用户状态失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 异步尝试获取Farcaster用户信息（不阻塞UI）
  Future<void> _tryGetFarcasterUserAsync() async {
    try {
      if (_miniAppService.isMiniAppEnvironment) {
        debugPrint('🔍 Farcaster环境检测到，尝试自动登录...');
        
        // 等待SDK完全加载
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (_miniAppService.isSdkAvailable) {
          debugPrint('📦 SDK可用，启动Quick Auth自动登录...');
          
          // 🎯 优先使用 Quick Auth 自动登录
          final quickAuthResult = await _miniAppService.quickAuthLogin()
              .timeout(const Duration(seconds: 8));
              
          if (quickAuthResult != null && quickAuthResult['fid'] != null) {
            debugPrint('✅ Quick Auth自动登录成功: FID ${quickAuthResult['fid']}');
            await _processQuickAuthResult(quickAuthResult);
            _setError(null);
            notifyListeners(); // 立即更新UI显示登录状态
            return;
          } 
          
          debugPrint('⚠️ Quick Auth自动登录失败，尝试context方案...');
          
          // 🔄 备用方案：直接从context获取用户信息（无感登录）
          final farcasterUser = await _miniAppService.getFarcasterUser()
              .timeout(const Duration(seconds: 8));
              
          if (farcasterUser != null && farcasterUser.isNotEmpty) {
            debugPrint('✅ Context自动登录成功: ${farcasterUser.toString()}');
            await _processFarcasterUser(farcasterUser);
            _setError(null);
            notifyListeners();
            return;
          } else {
            debugPrint('⚠️ 从context获取用户信息为空');
          }
        } else {
          debugPrint('❌ SDK不可用，可能还在加载中...');
          
          // 如果SDK还没加载完成，再等待一段时间重试
          await Future.delayed(const Duration(seconds: 2));
          if (_miniAppService.isSdkAvailable) {
            debugPrint('🔄 SDK延迟加载完成，重试Quick Auth...');
            final quickAuthResult = await _miniAppService.quickAuthLogin();
            if (quickAuthResult != null && quickAuthResult['fid'] != null) {
              debugPrint('✅ 延迟Quick Auth登录成功');
              await _processQuickAuthResult(quickAuthResult);
              _setError(null);
              notifyListeners();
              return;
            }
          }
        }
      } else {
        debugPrint('📱 非Farcaster环境，跳过自动登录');
      }
      
      debugPrint('⚠️ 自动登录未成功，用户需要手动登录');
    } catch (e) {
      debugPrint('❌ 自动登录失败: $e');
      // 这里不设置错误，因为这是非阻塞的尝试
      // 用户仍然可以手动点击登录
    }
  }

  /// 恢复本地用户状态
  Future<void> _restoreLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString(AppConstants.userTokenKey);
    final userJson = prefs.getString(AppConstants.userProfileKey);
    
    if (userToken != null && userJson != null) {
      debugPrint('Restoring user from local storage...');
      try {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        _setError(null);
      } catch (e) {
        debugPrint('Error parsing stored user data: $e');
        // 清理损坏的数据
        await prefs.remove(AppConstants.userTokenKey);
        await prefs.remove(AppConstants.userProfileKey);
      }
    }
  }

  /// 用户登录
  Future<bool> login(String fid) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = await _neynarService.getUserByFid(fid);
      await _saveUserToLocal(user);
      
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 通过用户名登录
  Future<bool> loginWithUsername(String username) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = await _neynarService.getUserByUsername(username);
      await _saveUserToLocal(user);
      
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 模拟登录功能（用于本地测试）
  Future<bool> simulateLogin(String username) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 创建模拟用户数据
      final mockUser = User(
        fid: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        displayName: username,
        avatarUrl: null, // 不使用网络图片，改为本地图标
        bio: '这是一个模拟用户账号，用于本地测试 ThunderTrack 应用功能。',
        walletAddress: '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        followers: ['user1', 'user2', 'user3'],
        following: ['trader_a', 'trader_b'],
        isVerified: username.contains('demo') || username.contains('trader'),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActiveAt: DateTime.now(),
      );
      
      await _saveUserToLocal(mockUser);
      
      _currentUser = mockUser;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('模拟登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 用户登出
  Future<void> logout() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userTokenKey);
      await prefs.remove(AppConstants.userProfileKey);
      
      // 断开钱包连接
      // Wallet disconnect functionality removed
      
      _currentUser = null;
      _isAuthenticated = false;
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('登出失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 更新用户信息
  Future<void> updateUserProfile(User updatedUser) async {
    _setLoading(true);
    try {
      await _saveUserToLocal(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('更新用户信息失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 关注用户
  Future<bool> followUser(String targetFid) async {
    if (_currentUser == null) return false;
    
    try {
      final success = await _neynarService.followUser(targetFid);
      if (success) {
        // 更新本地关注列表
        final updatedFollowing = List<String>.from(_currentUser!.following)
          ..add(targetFid);
        _currentUser = _currentUser!.copyWith(following: updatedFollowing);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('关注失败: $e');
      return false;
    }
  }

  /// 取消关注用户
  Future<bool> unfollowUser(String targetFid) async {
    if (_currentUser == null) return false;
    
    try {
      final success = await _neynarService.unfollowUser(targetFid);
      if (success) {
        // 更新本地关注列表
        final updatedFollowing = List<String>.from(_currentUser!.following)
          ..remove(targetFid);
        _currentUser = _currentUser!.copyWith(following: updatedFollowing);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('取消关注失败: $e');
      return false;
    }
  }

  /// 刷新用户信息
  Future<void> refreshUserData() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      final updatedUser = await _neynarService.getUserByFid(_currentUser!.fid);
      _currentUser = updatedUser;
      await _saveUserToLocal(updatedUser);
      notifyListeners();
    } catch (e) {
      _setError('刷新用户信息失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 保存用户信息到本地
  Future<void> _saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userTokenKey, user.fid);
    await prefs.setString(AppConstants.userProfileKey, jsonEncode(user.toJson()));
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// 处理从 Farcaster Mini App 获取的用户数据
  Future<void> _processFarcasterUser(Map<String, dynamic> farcasterUserData) async {
    try {
      // 详细调试 Farcaster 用户数据
      addDebugLog('🔍 Farcaster用户原始数据: ${farcasterUserData.toString()}');

      // 获取两种地址并进行对比
      final custodyAddress = farcasterUserData['custodyAddress']?.toString();
      final connectedAddress = farcasterUserData['connectedAddress']?.toString();

      addDebugLog('📋 custodyAddress (内置钱包): ${custodyAddress ?? "未获取到"}');
      addDebugLog('📋 connectedAddress (绑定钱包): ${connectedAddress ?? "未获取到"}');

      // 优先使用 eth_accounts 获取的地址，然后是 custodyAddress，最后是 connectedAddress
      String? walletAddress;
      String walletType = '未知钱包';

      // 方案1：尝试通过 eth_accounts 获取内置钱包地址
      try {
        addDebugLog('📋 尝试通过 eth_accounts 获取内置钱包地址...');
        walletAddress = await _miniAppService.getBuiltinWalletAddress();
        if (walletAddress != null && walletAddress.isNotEmpty) {
          walletType = 'Farcaster内置钱包(eth_accounts)';
          addDebugLog('✅ 使用 eth_accounts 获取的内置钱包地址: $walletAddress');
        }
      } catch (e) {
        addDebugLog('❌ eth_accounts 获取地址失败: $e');
      }

      // 方案2：如果 eth_accounts 失败，使用 custodyAddress
      if (walletAddress == null || walletAddress.isEmpty) {
        if (custodyAddress != null && custodyAddress.isNotEmpty) {
          walletAddress = custodyAddress;
          walletType = 'Farcaster内置钱包(custody)';
          addDebugLog('✅ 使用内置钱包地址(custodyAddress): $custodyAddress');
        } else if (connectedAddress != null && connectedAddress.isNotEmpty) {
          walletAddress = connectedAddress;
          walletType = '绑定外部钱包';
          addDebugLog('⚠️ 回退到绑定钱包地址: $connectedAddress');
        } else {
          addDebugLog('❌ 未找到任何钱包地址');
        }
      }

      // 将 Farcaster 用户数据转换为我们的 User 模型
      final user = User(
        fid: farcasterUserData['fid']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        username: farcasterUserData['username']?.toString() ?? 'farcaster_user',
        displayName: farcasterUserData['displayName']?.toString() ?? farcasterUserData['username']?.toString() ?? 'Farcaster User',
        avatarUrl: farcasterUserData['pfpUrl']?.toString(),
        bio: farcasterUserData['bio']?.toString() ?? '来自 Farcaster 的用户',
        walletAddress: walletAddress, // 使用优先级选择的钱包地址
        followers: _parseFollowers(farcasterUserData['followers']),
        following: _parseFollowing(farcasterUserData['following']),
        isVerified: farcasterUserData['verified'] == true || farcasterUserData['powerBadge'] == true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)), // 默认值
        lastActiveAt: DateTime.now(),
      );

      addDebugLog('🎯 最终用户钱包地址: ${user.walletAddress}');
      addDebugLog('🎯 钱包类型: $walletType');

      await _saveUserToLocal(user);
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      
      debugPrint('Successfully processed Farcaster user: ${user.username}');
    } catch (e) {
      debugPrint('Error processing Farcaster user data: $e');
      throw Exception('处理 Farcaster 用户数据失败: $e');
    }
  }

  /// 解析关注者列表
  List<String> _parseFollowers(dynamic followers) {
    if (followers == null) return [];
    if (followers is List) {
      return followers.map((f) => f.toString()).toList();
    }
    if (followers is int) {
      // 如果只是数量，返回空列表
      return [];
    }
    return [];
  }

  /// 解析关注列表
  List<String> _parseFollowing(dynamic following) {
    if (following == null) return [];
    if (following is List) {
      return following.map((f) => f.toString()).toList();
    }
    if (following is int) {
      // 如果只是数量，返回空列表
      return [];
    }
    return [];
  }

  /// 真实的 Farcaster 登录（优先使用 Quick Auth）
  Future<bool> loginFromFarcaster() async {
    if (!_miniAppService.isMiniAppEnvironment) {
      addDebugLog('❌ 不在 Farcaster Mini App 环境中');
      _setError('不在 Farcaster Mini App 环境中');
      return false;
    }

    addDebugLog('🚀 开始手动 Farcaster 登录流程...');
    _setLoading(true);
    _setError(null);

    try {
      addDebugLog('🎯 尝试 Quick Auth 登录...');
      
      // 🎯 优先使用 Quick Auth（推荐方案）
      final quickAuthResult = await _miniAppService.quickAuthLogin();
      
      if (quickAuthResult != null && quickAuthResult['fid'] != null) {
        addDebugLog('✅ Quick Auth 登录成功: FID=${quickAuthResult['fid']}');
        await _processQuickAuthResult(quickAuthResult);
        return true;
      }
      
      addDebugLog('⚠️ Quick Auth 不可用，尝试备用方案...');
      
      // 🔄 备用方案：直接从context获取用户信息
      final farcasterUser = await _miniAppService.getFarcasterUser();
      
      if (farcasterUser != null && farcasterUser.isNotEmpty) {
        addDebugLog('✅ Context方案登录成功');
        await _processFarcasterUser(farcasterUser);
        return true;
      }
      
      addDebugLog('❌ 所有登录方案都失败了');
      _setError('无法获取 Farcaster 用户信息');
      return false;
      
    } catch (e) {
      addDebugLog('❌ Farcaster登录出错: $e');
      _setError('Farcaster 登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 处理 Quick Auth 登录结果（Neynar API优先方式）
  Future<void> _processQuickAuthResult(Map<String, dynamic> authResult) async {
    try {
      addDebugLog('🔧 开始处理Quick Auth结果...');
      
      final fid = authResult['fid']?.toString();
      addDebugLog('🆔 FID: $fid');
      
      if (fid == null) {
        throw Exception('FID不能为空');
      }
      
      // 🎯 优先使用 Neynar API 获取完整用户信息
      addDebugLog('🔄 使用Neynar API获取完整用户信息...');
      
      try {
        final neynarUser = await _neynarService.getUserByFid(fid);
        
        addDebugLog('✅ Neynar API成功获取用户信息');
        addDebugLog('👤 用户名: ${neynarUser.username}');
        addDebugLog('🏷️ 显示名: ${neynarUser.displayName}');
        addDebugLog('🖼️ 头像: ${neynarUser.avatarUrl != null ? "有" : "无"}');
        
        // 直接使用 Neynar 返回的 User 对象
        final user = User(
          fid: fid,
          username: neynarUser.username,
          displayName: neynarUser.displayName,
          avatarUrl: neynarUser.avatarUrl,
          bio: neynarUser.bio ?? '来自 Farcaster 的用户',
          walletAddress: neynarUser.walletAddress, // 保留原有的钱包地址
          followers: neynarUser.followers,
          following: neynarUser.following,
          isVerified: neynarUser.isVerified,
          createdAt: neynarUser.createdAt,
          lastActiveAt: DateTime.now(),
        );

        addDebugLog('👤 创建的用户对象: ${user.displayName} (${user.username})');
        addDebugLog('🔍 检查authResult中的字段...');
        authResult.forEach((key, value) {
          addDebugLog('   $key: ${value?.toString().substring(0, math.min(50, value?.toString().length ?? 0))}...');
        });

        // 尝试获取signer_uuid
        String? signerUuid = authResult['signer_uuid'];
        String? approvalUrl;
        
        if (signerUuid == null) {
          addDebugLog('⚠️ authResult中没有signer_uuid，尝试通过API创建...');
          addDebugLog('📋 当前FID: $fid');
          if (fid.isEmpty) {
            addDebugLog('❌ FID为空，无法创建signer');
          } else {
            addDebugLog('🔧 开始调用_neynarService.getOrCreateSignerUuid($fid)');
            final signerInfo = await _neynarService.getOrCreateSignerUuid(fid, addDebugLog);
            addDebugLog('🔧 _neynarService.getOrCreateSignerUuid调用完成');
            if (signerInfo != null) {
              // signerInfo现在包含完整的signer信息
              signerUuid = signerInfo['signer_uuid'] as String?;
              approvalUrl = signerInfo['signer_approval_url'] as String?;
              addDebugLog('✅ 通过API创建signer: ${signerUuid?.substring(0, 8)}...');
              if (approvalUrl != null) {
                addDebugLog('🔗 需要用户批准: $approvalUrl');
              }
            } else {
              addDebugLog('❌ API创建signer失败，signerInfo为null');
            }
          }
        } else {
          addDebugLog('✅ 从authResult获得signer_uuid: ${signerUuid.substring(0, 8)}...');
        }
        
        // 保存认证token、signer_uuid和approval_url
        await _saveAuthToken(authResult['token']);
        
        if (signerUuid != null) {
          await _saveSignerUuid(signerUuid);
          addDebugLog('💾 已保存signer_uuid: ${signerUuid.substring(0, 8)}...');
          
          // 立即验证是否保存成功
          final savedSigner = await getSignerUuid();
          if (savedSigner != null) {
            addDebugLog('✅ 验证signer_uuid保存成功: ${savedSigner.substring(0, 8)}...');
          } else {
            addDebugLog('❌ 验证失败：无法读取已保存的signer_uuid');
          }
        } else {
          addDebugLog('⚠️ signerUuid为null，跳过保存');
        }
        
        if (approvalUrl != null) {
          await _saveSignerApprovalUrl(approvalUrl);
          addDebugLog('💾 已保存approval_url');
        }
        await _saveUserToLocal(user);
        
        _currentUser = user;
        _isAuthenticated = true;
        
        // 🔑 处理钱包地址
        await _handleWalletAddress(user);
        
        addDebugLog('✅ 用户状态更新完成');
        addDebugLog('🎯 当前用户: ${_currentUser?.displayName} - 已认证: $_isAuthenticated');
        addDebugLog('💰 钱包地址: ${_currentUser?.walletAddress ?? "未设置"}');
        
        notifyListeners();
        
        addDebugLog('🎉 Quick Auth + Neynar API 处理成功: ${user.username}');
        return;
      } catch (e) {
        addDebugLog('❌ Neynar API调用失败: $e');
        // 继续使用备用方案
      }
      
      // 备用方案：SDK Context
      addDebugLog('🔄 Neynar API失败，尝试SDK Context...');
      final contextUser = await _miniAppService.getContextUserInfo();

      if (contextUser != null && contextUser.isNotEmpty) {
        addDebugLog('✅ SDK Context获取到用户信息');

        // 获取钱包地址并区分类型
        final custodyAddress = contextUser['custodyAddress']?.toString();
        final connectedAddress = contextUser['connectedAddress']?.toString();

        addDebugLog('📋 SDK Context - custodyAddress: ${custodyAddress ?? "未获取到"}');
        addDebugLog('📋 SDK Context - connectedAddress: ${connectedAddress ?? "未获取到"}');

        String? walletAddress;

        // 优先使用 eth_accounts 获取内置钱包地址
        try {
          addDebugLog('📋 尝试通过 eth_accounts 获取内置钱包地址...');
          walletAddress = await _miniAppService.getBuiltinWalletAddress();
          if (walletAddress != null && walletAddress.isNotEmpty) {
            addDebugLog('✅ 使用 eth_accounts 获取的内置钱包地址: $walletAddress');
          }
        } catch (e) {
          addDebugLog('❌ eth_accounts 获取地址失败: $e');
        }

        // 备用方案：使用 custodyAddress 或 connectedAddress
        if (walletAddress == null || walletAddress.isEmpty) {
          if (custodyAddress != null && custodyAddress.isNotEmpty) {
            walletAddress = custodyAddress;
            addDebugLog('✅ 使用内置钱包地址(custodyAddress): $custodyAddress');
          } else if (connectedAddress != null && connectedAddress.isNotEmpty) {
            walletAddress = connectedAddress;
            addDebugLog('⚠️ 使用绑定钱包地址: $connectedAddress');
          }
        }

        final user = User(
          fid: fid,
          username: contextUser['username']?.toString() ?? 'user_$fid',
          displayName: contextUser['displayName']?.toString() ??
                      contextUser['username']?.toString() ??
                      'Farcaster User $fid',
          avatarUrl: contextUser['pfpUrl']?.toString(),
          bio: contextUser['bio']?.toString() ?? '来自 Farcaster 的用户',
          walletAddress: walletAddress, // 使用正确的钱包地址逻辑
          followers: [],
          following: [],
          isVerified: contextUser['powerBadge'] == true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastActiveAt: DateTime.now(),
        );

        await _saveAuthToken(authResult['token']);
        await _saveSignerUuid(authResult['signer_uuid']);
        await _saveUserToLocal(user);
        
        _currentUser = user;
        _isAuthenticated = true;
        
        addDebugLog('🎉 SDK Context处理成功: ${user.username}');
        notifyListeners();
        return;
      }
      
      // 最后的备用方案：使用基本信息
      addDebugLog('❌ 所有方式都失败，使用基本信息');
      final user = User(
        fid: fid,
        username: 'user_$fid',
        displayName: 'Farcaster User $fid',
        avatarUrl: null,
        bio: '来自 Farcaster 的用户',
        walletAddress: null,
        followers: [],
        following: [],
        isVerified: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActiveAt: DateTime.now(),
      );

      await _saveAuthToken(authResult['token']);
      await _saveSignerUuid(authResult['signer_uuid']);
      await _saveUserToLocal(user);
      
      _currentUser = user;
      _isAuthenticated = true;
      
      addDebugLog('🎯 使用基本用户信息: ${user.displayName}');
      notifyListeners();
      
    } catch (e) {
      addDebugLog('❌ 处理 Quick Auth 结果失败: $e');
      throw Exception('处理认证结果失败: $e');
    }
  }

  /// 保存signer UUID
  Future<void> _saveSignerUuid(String? signerUuid) async {
    if (signerUuid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${AppConstants.userTokenKey}_signer', signerUuid);
      debugPrint('💾 Signer UUID已保存: ${signerUuid.substring(0, 8)}...');
    }
  }

  /// 获取保存的signer UUID
  Future<String?> getSignerUuid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${AppConstants.userTokenKey}_signer');
  }

  /// 保存signer approval URL
  Future<void> _saveSignerApprovalUrl(String? approvalUrl) async {
    if (approvalUrl != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${AppConstants.userTokenKey}_approval', approvalUrl);
      debugPrint('💾 Signer approval URL已保存');
    }
  }

  /// 获取保存的signer approval URL
  Future<String?> getSignerApprovalUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${AppConstants.userTokenKey}_approval');
  }

  /// 保存认证token
  Future<void> _saveAuthToken(String? token) async {
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${AppConstants.userTokenKey}_auth', token);
      debugPrint('💾 认证token已保存');
    }
  }

  /// 获取保存的认证token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${AppConstants.userTokenKey}_auth');
  }

  /// 使用完整的 Sign In with Farcaster 流程
  Future<bool> signInWithFarcaster() async {
    if (!_miniAppService.isMiniAppEnvironment) {
      _setError('不在 Farcaster Mini App 环境中');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      debugPrint('开始 Sign In with Farcaster 流程...');
      
      final signInResult = await _miniAppService.signInWithFarcaster();
      
      if (signInResult != null) {
        // 这里需要将signature和message发送到服务器进行验证
        // 目前先模拟验证成功，实际项目中需要后端验证
        debugPrint('SIWF签名获取成功，需要服务器验证');
        
        // 获取用户基本信息
        final contextUser = await _miniAppService.getFarcasterUser();
        if (contextUser != null) {
          final combinedInfo = {
            ...contextUser,
            'signature': signInResult['signature'],
            'message': signInResult['message'],
            'nonce': signInResult['nonce'],
            'verified': false, // 标记为未验证，需要服务器验证
          };
          
          await _processFarcasterUser(combinedInfo);
          debugPrint('SIWF 登录成功（需服务器验证）');
          return true;
        }
      }
      
      _setError('Sign In with Farcaster 失败');
      return false;
      
    } catch (e) {
      if (e.toString().contains('用户拒绝')) {
        _setError('用户取消了登录');
      } else {
        _setError('SIWF 登录失败: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 通知 Mini App 准备就绪
  Future<void> notifyMiniAppReady() async {
    try {
      await _miniAppService.markReady();
      debugPrint('Mini App ready notification sent');
    } catch (e) {
      debugPrint('Error sending Mini App ready notification: $e');
    }
  }

  /// 获取以太坊钱包提供者
  dynamic getEthereumProvider() {
    return _miniAppService.getEthereumProvider();
  }

  /// 处理用户钱包地址
  Future<void> _handleWalletAddress(User user) async {
    try {
      addDebugLog('🔑 开始处理用户钱包地址...');

      // 检查用户是否已经有钱包地址
      if (user.walletAddress != null && user.walletAddress!.isNotEmpty) {
        addDebugLog('✅ 用户已有钱包地址: ${user.walletAddress}');
        return;
      }

      addDebugLog('🔍 用户暂无钱包地址，尝试获取内置钱包地址...');

      String? walletAddress;

      // 优先方案：通过 eth_accounts 获取内置钱包地址
      try {
        addDebugLog('📋 方案1: 尝试通过 eth_accounts 获取地址...');
        walletAddress = await _miniAppService.getBuiltinWalletAddress();
        if (walletAddress != null && walletAddress.isNotEmpty) {
          addDebugLog('✅ 通过 eth_accounts 获取到内置钱包地址: $walletAddress');
        } else {
          addDebugLog('⚠️ eth_accounts 未返回地址');
        }
      } catch (e) {
        addDebugLog('❌ eth_accounts 方法失败: $e');
      }

      // 备用方案：从SDK Context获取钱包地址
      if (walletAddress == null || walletAddress.isEmpty) {
        addDebugLog('📋 方案2: 从SDK Context获取钱包地址...');
        final contextUser = await _miniAppService.getContextUserInfo();
        if (contextUser != null) {
          final custodyAddress = contextUser['custodyAddress']?.toString();
          final connectedAddress = contextUser['connectedAddress']?.toString();

          addDebugLog('📋 SDK Context - custodyAddress: ${custodyAddress ?? "未获取到"}');
          addDebugLog('📋 SDK Context - connectedAddress: ${connectedAddress ?? "未获取到"}');

          if (custodyAddress != null && custodyAddress.isNotEmpty) {
            walletAddress = custodyAddress;
            addDebugLog('✅ 使用内置钱包地址 (custodyAddress): $custodyAddress');
          } else if (connectedAddress != null && connectedAddress.isNotEmpty) {
            walletAddress = connectedAddress;
            addDebugLog('⚠️ 使用绑定钱包地址 (connectedAddress): $connectedAddress');
          }
        } else {
          addDebugLog('❌ 无法获取SDK Context用户信息');
        }
      }

      if (walletAddress != null) {
        // 更新用户钱包地址
        final updatedUser = User(
          fid: user.fid,
          username: user.username,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          bio: user.bio,
          walletAddress: walletAddress,
          followers: user.followers,
          following: user.following,
          isVerified: user.isVerified,
          createdAt: user.createdAt,
          lastActiveAt: user.lastActiveAt,
        );

        _currentUser = updatedUser;
        await _saveUserToLocal(updatedUser);
        addDebugLog('🎯 钱包地址已更新: $walletAddress');
        notifyListeners();
      } else {
        addDebugLog('⚠️ 未找到任何可用的钱包地址');
      }
    } catch (e) {
      addDebugLog('❌ 钱包地址处理失败：$e');
    }
  }

  /// 更新用户钱包地址
  Future<void> updateUserWalletAddress(String newWalletAddress) async {
    try {
      if (_currentUser == null) {
        addDebugLog('❌ 没有当前用户，无法更新钱包地址');
        return;
      }

      addDebugLog('🔄 更新用户钱包地址...');
      addDebugLog('   原地址: ${_currentUser!.walletAddress ?? "无"}');
      addDebugLog('   新地址: $newWalletAddress');

      // 创建新的用户对象
      final updatedUser = User(
        fid: _currentUser!.fid,
        username: _currentUser!.username,
        displayName: _currentUser!.displayName,
        avatarUrl: _currentUser!.avatarUrl,
        bio: _currentUser!.bio,
        walletAddress: newWalletAddress,
        followers: _currentUser!.followers,
        following: _currentUser!.following,
        isVerified: _currentUser!.isVerified,
        createdAt: _currentUser!.createdAt,
        lastActiveAt: _currentUser!.lastActiveAt,
      );

      // 更新当前用户
      _currentUser = updatedUser;

      // 保存到本地存储
      await _saveUserToLocal(updatedUser);

      // 通知监听器
      notifyListeners();

      addDebugLog('✅ 用户钱包地址更新完成');
    } catch (e) {
      addDebugLog('❌ 更新用户钱包地址失败: $e');
      rethrow;
    }
  }

  /// 手动连接钱包地址
  Future<bool> connectWalletAddress({
    required String address,
    required int appFid,
    required String signature,
    int? deadline,
  }) async {
    try {
      addDebugLog('❌ 钱包连接功能已移除');
      return false;
    } catch (e) {
      addDebugLog('❌ 连接钱包地址出错: $e');
      _setError('连接钱包地址失败: $e');
      return false;
    }
  }

  /// 检查钱包地址状态 (功能已移除)
  Future<void> checkWalletStatus() async {
    addDebugLog('📱 钱包状态检查功能已移除');
  }

  /// 手动检查钱包连接状态
  Future<void> checkWalletConnection() async {
    addDebugLog('🔄 手动检查钱包连接状态...');

    try {
      await _walletService.checkExistingConnection();

      if (_walletService.isConnected && !_isAuthenticated) {
        addDebugLog('✅ 发现已连接钱包，但用户未登录，尝试自动登录...');
        final success = await signInWithEthereum();
        addDebugLog(success ? '🎉 自动登录成功' : '❌ 自动登录失败');
      }

      notifyListeners();
    } catch (e) {
      addDebugLog('❌ 检查钱包连接失败: $e');
    }
  }

  /// 断开钱包连接
  Future<void> disconnectWallet() async {
    try {
      await _walletService.disconnectWallet();
      addDebugLog('✅ 钱包已断开连接');

      // 更新用户对象，清除钱包地址
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(walletAddress: null);
        await _saveUserToLocal(_currentUser!);
      }

      notifyListeners();
    } catch (e) {
      addDebugLog('❌ 断开钱包连接失败: $e');
      _setError('断开钱包连接失败: $e');
    }
  }

  /// 连接钱包 (Web3)
  Future<bool> connectWallet() async {
    if (!_walletService.isWeb3Available) {
      addDebugLog('❌ Web3不可用，请使用支持的浏览器');
      _setError('Web3不可用，请使用支持的浏览器');
      return false;
    }

    addDebugLog('🔄 开始连接钱包...');
    _setLoading(true);
    _setError(null);

    try {
      final walletAddress = await _walletService.connectWallet();

      if (walletAddress != null) {
        addDebugLog('✅ 钱包连接成功: $walletAddress');

        // 更新当前用户的钱包地址
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(walletAddress: walletAddress);
          await _saveUserToLocal(_currentUser!);
        }

        notifyListeners();
        return true;
      }

      addDebugLog('❌ 钱包连接失败');
      return false;
    } catch (e) {
      addDebugLog('❌ 连接钱包出错: $e');
      _setError('连接钱包失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign-in with Ethereum + Farcaster 集成登录
  Future<bool> signInWithEthereum() async {
    if (!_walletService.isWeb3Available) {
      addDebugLog('❌ Web3不可用');
      _setError('Web3不可用，请使用支持的浏览器');
      return false;
    }

    addDebugLog('🚀 开始 Sign-in with Ethereum + Farcaster 流程...');
    _setLoading(true);
    _setError(null);

    try {
      // 第1步：连接钱包
      addDebugLog('📋 步骤1: 连接钱包');
      final walletAddress = await _walletService.connectWallet();

      if (walletAddress == null) {
        addDebugLog('❌ 钱包连接失败');
        return false;
      }

      addDebugLog('✅ 钱包连接成功: $walletAddress');

      // 第2步：通过钱包地址查找Farcaster账户
      addDebugLog('📋 步骤2: 查找关联的Farcaster账户');
      final farcasterUser = await _neynarService.getUserByWalletAddress(walletAddress);

      if (farcasterUser != null) {
        // 找到了关联的Farcaster账户
        addDebugLog('✅ 找到关联的Farcaster账户: ${farcasterUser.username}');

        // 确保钱包地址包含在用户数据中
        final user = farcasterUser.copyWith(walletAddress: walletAddress);

        await _saveUserToLocal(user);
        _currentUser = user;
        _isAuthenticated = true;

        addDebugLog('🎉 Sign-in with Ethereum 完成: ${user.username}');
        addDebugLog('💰 关联钱包: $walletAddress');

        notifyListeners();
        return true;
      } else {
        // 未找到关联的Farcaster账户
        addDebugLog('⚠️ 钱包地址未关联Farcaster账户');

        // 创建一个基本的钱包用户
        final walletUser = User(
          fid: 'wallet_${walletAddress.substring(2, 8)}',
          username: walletAddress.substring(0, 10), // 使用地址前10位作为用户名
          displayName: '${walletAddress.substring(0, 6)}...${walletAddress.substring(38)}', // 简化显示名
          avatarUrl: null, // 使用默认头像
          bio: '钱包用户 - 可进行交易操作',
          walletAddress: walletAddress,
          followers: [],
          following: [],
          isVerified: false,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        await _saveUserToLocal(walletUser);
        _currentUser = walletUser;
        _isAuthenticated = true;

        addDebugLog('✅ 创建钱包用户登录成功');
        addDebugLog('💡 提示：您可以在Farcaster中验证此钱包地址来关联账户');

        notifyListeners();
        return true;
      }
    } catch (e) {
      addDebugLog('❌ Sign-in with Ethereum 失败: $e');
      _setError('登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 签名消息 (优先使用 Farcaster 内置钱包，备用 Web3 钱包)
  Future<String?> signMessage(String message) async {
    addDebugLog('🔏 开始签名消息...');
    addDebugLog('   消息: ${message.length > 50 ? message.substring(0, 50) + "..." : message}');

    // 检查内置钱包签名条件
    addDebugLog('📋 检查内置钱包签名条件:');
    addDebugLog('   isMiniAppEnvironment: $isMiniAppEnvironment');
    addDebugLog('   hasBuiltinWallet: $hasBuiltinWallet');
    addDebugLog('   当前用户: ${_currentUser != null ? "存在" : "不存在"}');
    addDebugLog('   钱包地址: ${_currentUser?.walletAddress ?? "无"}');

    // 优先使用 Farcaster 内置钱包
    if (isMiniAppEnvironment && hasBuiltinWallet && _currentUser?.walletAddress != null) {
      addDebugLog('✅ 条件满足，使用 Farcaster 内置钱包签名消息');
      addDebugLog('   使用地址: ${_currentUser!.walletAddress}');
      try {
        final signature = await _miniAppService.signMessageWithBuiltinWallet(
          message,
          _currentUser!.walletAddress!
        );
        if (signature != null) {
          addDebugLog('✅ Farcaster 内置钱包签名成功');
          return signature;
        } else {
          addDebugLog('⚠️ Farcaster 内置钱包签名返回null');
        }
      } catch (e) {
        addDebugLog('❌ Farcaster 内置钱包签名失败: $e');
      }
    } else {
      addDebugLog('❌ 内置钱包签名条件不满足');
    }

    // 备用方案：使用 Web3 钱包
    addDebugLog('📋 检查 Web3 钱包签名条件:');
    addDebugLog('   _walletService.isConnected: ${_walletService.isConnected}');

    if (_walletService.isConnected) {
      addDebugLog('✅ Web3 钱包已连接，尝试签名');
      try {
        final signature = await _walletService.signMessage(message);
        if (signature != null) {
          addDebugLog('✅ Web3 钱包签名成功');
          return signature;
        } else {
          addDebugLog('⚠️ Web3 钱包签名返回null');
        }
      } catch (e) {
        addDebugLog('❌ Web3 钱包签名失败: $e');
      }
    } else {
      addDebugLog('❌ Web3 钱包未连接');
    }

    addDebugLog('❌ 无可用钱包进行签名');
    return null;
  }

  /// EIP-712结构化数据签名 (优先使用 Farcaster 内置钱包)
  Future<String?> signTypedData(Map<String, dynamic> typedData) async {
    // 优先使用 Farcaster 内置钱包
    if (isMiniAppEnvironment && hasBuiltinWallet && _currentUser?.walletAddress != null) {
      addDebugLog('🔏 使用 Farcaster 内置钱包进行 EIP-712 签名');
      try {
        final signature = await _miniAppService.signTypedDataWithBuiltinWallet(
          typedData,
          _currentUser!.walletAddress!
        );
        if (signature != null) {
          addDebugLog('✅ Farcaster 内置钱包 EIP-712 签名成功');
          return signature;
        }
      } catch (e) {
        addDebugLog('❌ Farcaster 内置钱包 EIP-712 签名失败: $e');
      }
    }

    // 备用方案：使用 Web3 钱包
    if (_walletService.isConnected) {
      addDebugLog('🔏 使用 Web3 钱包进行 EIP-712 签名');
      try {
        final signature = await _walletService.signTypedData(typedData);
        if (signature != null) {
          addDebugLog('✅ Web3 钱包 EIP-712 签名成功');
          return signature;
        }
      } catch (e) {
        addDebugLog('❌ Web3 钱包 EIP-712 签名失败: $e');
      }
    }

    addDebugLog('❌ 无可用钱包进行 EIP-712 签名');
    return null;
  }

  /// 获取钱包余额
  Future<String?> getWalletBalance() async {
    if (!_walletService.isConnected) return null;

    try {
      return await _walletService.getBalance();
    } catch (e) {
      addDebugLog('❌ 获取钱包余额失败: $e');
      return null;
    }
  }

  /// 获取链信息
  Map<String, String> getChainInfo() {
    return _walletService.getChainInfo();
  }

  /// 生成钱包签名数据
  Map<String, dynamic> generateWalletSignatureData({
    required String address,
    required int appFid,
    int? deadline,
  }) {
    // 为Hyperliquid生成EIP-712签名数据
    final now = DateTime.now().millisecondsSinceEpoch;
    final signatureDeadline = deadline ?? (now ~/ 1000) + 3600; // 1小时后过期

    return {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'version', 'type': 'string'},
          {'name': 'chainId', 'type': 'uint256'},
        ],
        'Agent': [
          {'name': 'source', 'type': 'string'},
          {'name': 'connectionId', 'type': 'bytes32'},
        ],
      },
      'domain': {
        'name': 'ThunderTrack',
        'version': '1.0.0',
        'chainId': 1, // 以太坊主网
      },
      'primaryType': 'Agent',
      'message': {
        'source': 'thundertrack',
        'connectionId': '0x${address.substring(2).padLeft(64, '0')}',
      },
    };
  }

  @override
  void dispose() {
    _walletService.removeListener(_onWalletStateChanged);
    super.dispose();
  }
}