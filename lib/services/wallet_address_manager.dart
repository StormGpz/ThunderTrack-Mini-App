import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/neynar_service.dart';
import '../models/auth_address.dart';
import '../models/user.dart';

/// 钱包地址管理器
/// 负责管理用户的钱包地址连接和状态
class WalletAddressManager {
  static final WalletAddressManager _instance = WalletAddressManager._internal();
  factory WalletAddressManager() => _instance;
  WalletAddressManager._internal();

  final NeynarService _neynarService = NeynarService();
  
  static const String _keyWalletAddress = 'wallet_address';
  static const String _keyAuthStatus = 'auth_status';
  static const String _keyAppFid = 'app_fid';

  String? _currentAddress;
  AuthAddressStatus? _currentStatus;
  int? _appFid;

  /// 当前连接的钱包地址
  String? get currentAddress => _currentAddress;
  
  /// 当前认证状态
  AuthAddressStatus? get currentStatus => _currentStatus;
  
  /// 当前App FID
  int? get appFid => _appFid;
  
  /// 钱包是否已连接且已批准
  bool get isWalletConnected => 
    _currentAddress != null && 
    _currentStatus?.isActive == true;

  /// 初始化钱包管理器
  Future<void> initialize() async {
    await _loadStoredWalletInfo();
    
    if (_currentAddress != null) {
      await _refreshWalletStatus();
    }
  }

  /// 从用户的 Farcaster 信息获取钱包地址
  Future<String?> getWalletAddressFromUser(User user) async {
    try {
      debugPrint('🔄 从用户信息获取钱包地址: ${user.username}');
      
      // 1. 首先尝试从用户的验证地址中获取
      if (user.walletAddress != null && user.walletAddress!.isNotEmpty) {
        debugPrint('✅ 找到用户验证地址: ${user.walletAddress}');
        return user.walletAddress;
      }

      // 2. 如果没有验证地址，使用开发者管理的认证地址
      debugPrint('⚠️ 用户没有验证地址，需要设置开发者管理的认证地址');
      return null;
      
    } catch (e) {
      debugPrint('❌ 获取钱包地址失败: $e');
      return null;
    }
  }

  /// 注册钱包地址为认证地址
  Future<bool> registerWalletAddress({
    required String address,
    required int appFid,
    required String signature,
    int? deadline,
  }) async {
    try {
      debugPrint('🔄 注册钱包地址: $address');
      
      final deadlineTimestamp = deadline ?? 
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + (24 * 60 * 60); // 24小时后过期

      final response = await _neynarService.registerSignedKey(
        address: address,
        appFid: appFid,
        deadline: deadlineTimestamp,
        signature: signature,
      );

      debugPrint('✅ 钱包地址注册成功: ${response.status.displayName}');
      
      _currentAddress = address;
      _currentStatus = response.status;
      _appFid = appFid;
      
      await _saveWalletInfo();
      
      return true;
    } catch (e) {
      debugPrint('❌ 钱包地址注册失败: $e');
      return false;
    }
  }

  /// 检查钱包地址的认证状态
  Future<AuthAddressStatus?> checkWalletStatus(String address) async {
    try {
      debugPrint('🔄 检查钱包状态: $address');
      
      final response = await _neynarService.getAuthAddressStatus(
        address: address,
      );

      debugPrint('✅ 钱包状态: ${response.status.displayName}');
      
      _currentStatus = response.status;
      await _saveWalletInfo();
      
      return response.status;
    } catch (e) {
      debugPrint('❌ 检查钱包状态失败: $e');
      return null;
    }
  }

  /// 设置当前钱包地址（从已有的验证地址）
  Future<void> setWalletAddress(String address) async {
    _currentAddress = address;
    _currentStatus = AuthAddressStatus.approved; // 验证地址默认为已批准
    await _saveWalletInfo();
    debugPrint('✅ 设置钱包地址: $address');
  }

  /// 断开钱包连接
  Future<void> disconnectWallet() async {
    _currentAddress = null;
    _currentStatus = null;
    _appFid = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWalletAddress);
    await prefs.remove(_keyAuthStatus);
    await prefs.remove(_keyAppFid);
    
    debugPrint('✅ 钱包已断开连接');
  }

  /// 刷新钱包状态
  Future<void> _refreshWalletStatus() async {
    if (_currentAddress != null) {
      await checkWalletStatus(_currentAddress!);
    }
  }

  /// 保存钱包信息到本地存储
  Future<void> _saveWalletInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_currentAddress != null) {
      await prefs.setString(_keyWalletAddress, _currentAddress!);
    }
    
    if (_currentStatus != null) {
      await prefs.setString(_keyAuthStatus, _currentStatus!.value);
    }
    
    if (_appFid != null) {
      await prefs.setInt(_keyAppFid, _appFid!);
    }
  }

  /// 从本地存储加载钱包信息
  Future<void> _loadStoredWalletInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentAddress = prefs.getString(_keyWalletAddress);
    
    final statusValue = prefs.getString(_keyAuthStatus);
    if (statusValue != null) {
      try {
        _currentStatus = AuthAddressStatus.fromString(statusValue);
      } catch (e) {
        debugPrint('⚠️ 无效的认证状态: $statusValue');
        _currentStatus = null;
      }
    }
    
    _appFid = prefs.getInt(_keyAppFid);
    
    debugPrint('📱 加载钱包信息 - 地址: $_currentAddress, 状态: ${_currentStatus?.displayName}');
  }

  /// 生成签名数据（需要配合前端签名工具使用）
  Map<String, dynamic> generateSignatureData({
    required String address,
    required int appFid,
    required int deadline,
  }) {
    return {
      'address': address,
      'app_fid': appFid,
      'deadline': deadline,
      'message': '注册 $address 为 App FID $appFid 的认证地址，有效期至 ${DateTime.fromMillisecondsSinceEpoch(deadline * 1000)}',
    };
  }

  @override
  String toString() {
    return 'WalletAddressManager(address: $_currentAddress, status: ${_currentStatus?.displayName}, appFid: $_appFid)';
  }
}