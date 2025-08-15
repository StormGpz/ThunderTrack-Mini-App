import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/neynar_service.dart';
import '../services/farcaster_miniapp_service.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户状态管理Provider
class UserProvider extends ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();
  factory UserProvider() => _instance;
  UserProvider._internal();

  final NeynarService _neynarService = NeynarService();
  final FarcasterMiniAppService _miniAppService = FarcasterMiniAppService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  
  // Mini App 相关 getters
  bool get isMiniAppEnvironment => _miniAppService.isMiniAppEnvironment;
  bool get isMiniAppSdkAvailable => _miniAppService.isSdkAvailable;
  Map<String, dynamic> get environmentInfo => _miniAppService.getEnvironmentInfo();

  /// 初始化用户状态
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // 记录环境信息用于调试
      _miniAppService.logEnvironmentInfo();
      
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
      // 将 Farcaster 用户数据转换为我们的 User 模型
      final user = User(
        fid: farcasterUserData['fid']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        username: farcasterUserData['username']?.toString() ?? 'farcaster_user',
        displayName: farcasterUserData['displayName']?.toString() ?? farcasterUserData['username']?.toString() ?? 'Farcaster User',
        avatarUrl: farcasterUserData['pfpUrl']?.toString(),
        bio: farcasterUserData['bio']?.toString() ?? '来自 Farcaster 的用户',
        walletAddress: null, // 钱包地址可能需要单独获取
        followers: _parseFollowers(farcasterUserData['followers']),
        following: _parseFollowing(farcasterUserData['following']),
        isVerified: farcasterUserData['verified'] == true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)), // 默认值
        lastActiveAt: DateTime.now(),
      );

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
      _setError('不在 Farcaster Mini App 环境中');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      debugPrint('🚀 开始 Farcaster 登录流程...');
      
      // 🎯 优先使用 Quick Auth（推荐方案）
      final quickAuthResult = await _miniAppService.quickAuthLogin();
      
      if (quickAuthResult != null && quickAuthResult['fid'] != null) {
        debugPrint('✅ Quick Auth 登录成功');
        await _processQuickAuthResult(quickAuthResult);
        return true;
      }
      
      debugPrint('⚠️ Quick Auth 不可用，尝试备用方案...');
      
      // 🔄 备用方案：直接从context获取用户信息
      final farcasterUser = await _miniAppService.getFarcasterUser();
      
      if (farcasterUser != null && farcasterUser.isNotEmpty) {
        debugPrint('✅ Context方案登录成功');
        await _processFarcasterUser(farcasterUser);
        return true;
      }
      
      _setError('无法获取 Farcaster 用户信息');
      return false;
      
    } catch (e) {
      debugPrint('❌ Farcaster登录出错: $e');
      _setError('Farcaster 登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 处理 Quick Auth 登录结果
  Future<void> _processQuickAuthResult(Map<String, dynamic> authResult) async {
    try {
      // 从 JWT token 和 context 信息创建用户对象
      final user = User(
        fid: authResult['fid']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        username: authResult['username']?.toString() ?? 'farcaster_user_${authResult['fid']}',
        displayName: authResult['displayName']?.toString() ?? authResult['username']?.toString() ?? 'Farcaster User',
        avatarUrl: authResult['pfpUrl']?.toString(),
        bio: authResult['bio']?.toString() ?? '来自 Farcaster 的用户',
        walletAddress: authResult['primaryAddress']?.toString(), // 可能从Quick Auth或context获取
        followers: _parseFollowers(authResult['followers']),
        following: _parseFollowing(authResult['following']),
        isVerified: authResult['verified'] == true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)), // 默认值
        lastActiveAt: DateTime.now(),
      );

      // 保存认证token（重要！）
      await _saveAuthToken(authResult['token']);
      await _saveUserToLocal(user);
      
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      
      debugPrint('✅ Quick Auth 用户处理成功: ${user.username}');
    } catch (e) {
      debugPrint('❌ 处理 Quick Auth 结果失败: $e');
      throw Exception('处理认证结果失败: $e');
    }
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
}