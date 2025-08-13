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
      
      // 在Mini App环境中，先快速恢复本地状态，然后异步获取Farcaster用户
      if (_miniAppService.isMiniAppEnvironment) {
        debugPrint('Mini App environment detected, restoring local state first...');
        // 先恢复本地状态，不阻塞应用启动
        await _restoreLocalUser();
        _setLoading(false);
        
        // 异步获取Farcaster用户信息，不阻塞UI
        _tryGetFarcasterUserAsync();
        return;
      }
      
      // 在普通浏览器环境中，只恢复本地存储
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
      if (_miniAppService.isSdkAvailable) {
        debugPrint('Attempting to get user from Farcaster Mini App...');
        
        // 添加超时机制，避免无限等待
        final farcasterUser = await _miniAppService.getFarcasterUser()
            .timeout(const Duration(seconds: 5));
            
        if (farcasterUser != null && farcasterUser.isNotEmpty) {
          debugPrint('Got Farcaster user: ${farcasterUser.toString()}');
          await _processFarcasterUser(farcasterUser);
          _setError(null);
          notifyListeners(); // 更新UI显示登录状态
        }
      }
    } catch (e) {
      debugPrint('Failed to get Farcaster user (non-blocking): $e');
      // 这里不设置错误，因为这是非阻塞的尝试
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

  /// 真实的 Farcaster 登录（从 Mini App 获取用户信息）
  Future<bool> loginFromFarcaster() async {
    if (!_miniAppService.isMiniAppEnvironment) {
      _setError('不在 Farcaster Mini App 环境中');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final farcasterUser = await _miniAppService.getFarcasterUser();
      
      if (farcasterUser == null || farcasterUser.isEmpty) {
        _setError('无法获取 Farcaster 用户信息');
        return false;
      }

      await _processFarcasterUser(farcasterUser);
      return true;
    } catch (e) {
      _setError('Farcaster 登录失败: $e');
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