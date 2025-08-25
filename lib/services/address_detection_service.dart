import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/address_auth.dart';
import '../services/neynar_service.dart';
import '../services/hyperliquid_service.dart';

/// 智能地址检测和管理服务
class AddressDetectionService {
  static final AddressDetectionService _instance = AddressDetectionService._internal();
  factory AddressDetectionService() => _instance;
  AddressDetectionService._internal();

  final NeynarService _neynarService = NeynarService();
  final HyperliquidService _hyperliquidService = HyperliquidService();

  /// 智能检测最佳交易地址
  Future<List<AddressOption>> detectAvailableAddresses(User user) async {
    debugPrint('🔍 开始检测可用地址...');
    
    List<AddressOption> options = [];
    
    try {
      // 1. 检测 Farcaster custody address（优先级最高）
      final custodyAddress = await _detectCustodyAddress(user);
      if (custodyAddress != null) {
        options.add(custodyAddress);
        debugPrint('✅ 找到 Farcaster custody address');
      }

      // 2. 检测用户绑定的验证地址
      final verifiedAddresses = await _detectVerifiedAddresses(user);
      options.addAll(verifiedAddresses);
      debugPrint('✅ 找到 ${verifiedAddresses.length} 个绑定地址');

      // 3. 检测已授权的 Hyperliquid 地址
      final authorizedAddresses = await _detectAuthorizedAddresses();
      for (final authAddr in authorizedAddresses) {
        // 避免重复添加
        if (!options.any((option) => option.address.toLowerCase() == authAddr.toLowerCase())) {
          options.add(AddressOption(
            address: authAddr,
            type: '已授权钱包',
            isConnected: true,
          ));
        }
      }
      debugPrint('✅ 找到 ${authorizedAddresses.length} 个已授权地址');

      // 按优先级排序
      options.sort((a, b) {
        if (a.recommended && !b.recommended) return -1;
        if (!a.recommended && b.recommended) return 1;
        if (a.isConnected && !b.isConnected) return -1;
        if (!a.isConnected && b.isConnected) return 1;
        return 0;
      });

      debugPrint('🎯 地址检测完成，共找到 ${options.length} 个可用地址');
      return options;
      
    } catch (e) {
      debugPrint('❌ 地址检测失败: $e');
      return options; // 返回已检测到的地址
    }
  }

  /// 获取推荐地址（第一优先级）
  Future<AddressOption?> getRecommendedAddress(User user) async {
    final options = await detectAvailableAddresses(user);
    
    // 返回第一个推荐地址，或者第一个可用地址
    final recommended = options.where((option) => option.recommended).firstOrNull;
    if (recommended != null) {
      debugPrint('💡 推荐地址: ${recommended.displayName}');
      return recommended;
    }
    
    final first = options.firstOrNull;
    if (first != null) {
      debugPrint('💡 默认地址: ${first.displayName}');
    }
    
    return first;
  }

  /// 检测 Farcaster custody address
  Future<AddressOption?> _detectCustodyAddress(User user) async {
    try {
      // 从用户信息中查找 custody address
      // 注意：需要根据实际的 Farcaster API 响应结构调整
      
      // 方案1: 从 user.walletAddress 获取（如果是 custody address）
      if (user.walletAddress != null && user.walletAddress!.isNotEmpty) {
        // 检查是否为 custody address 的特征
        if (await _isCustodyAddress(user.walletAddress!)) {
          return AddressOption(
            address: user.walletAddress!,
            type: 'Farcaster钱包',
            recommended: true,
            isConnected: true,
          );
        }
      }

      // 方案2: 通过 Neynar API 获取更详细的用户信息
      final detailedUser = await _neynarService.getUserByFid(user.fid);
      if (detailedUser.walletAddress != null && detailedUser.walletAddress!.isNotEmpty) {
        if (await _isCustodyAddress(detailedUser.walletAddress!)) {
          return AddressOption(
            address: detailedUser.walletAddress!,
            type: 'Farcaster钱包',
            recommended: true,
            isConnected: true,
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ 检测 custody address 失败: $e');
      return null;
    }
  }

  /// 检测用户绑定的验证地址
  Future<List<AddressOption>> _detectVerifiedAddresses(User user) async {
    List<AddressOption> addresses = [];
    
    try {
      // 从用户现有的 walletAddress 获取
      if (user.walletAddress != null && user.walletAddress!.isNotEmpty) {
        // 如果不是 custody address，则作为绑定地址
        if (!await _isCustodyAddress(user.walletAddress!)) {
          addresses.add(AddressOption(
            address: user.walletAddress!,
            type: '绑定钱包',
            recommended: addresses.isEmpty, // 第一个绑定地址作为推荐
            isConnected: true,
          ));
        }
      }

      // TODO: 如果 Neynar API 支持获取多个验证地址，在这里添加
      // 目前 Farcaster 用户通常只有一个主要的验证地址
      
    } catch (e) {
      debugPrint('⚠️ 检测绑定地址失败: $e');
    }
    
    return addresses;
  }

  /// 检测已授权的 Hyperliquid 地址
  Future<List<String>> _detectAuthorizedAddresses() async {
    try {
      return _hyperliquidService.getAuthorizedAddresses();
    } catch (e) {
      debugPrint('⚠️ 检测已授权地址失败: $e');
      return [];
    }
  }

  /// 检查是否为 custody address
  Future<bool> _isCustodyAddress(String address) async {
    // 这里需要根据 Farcaster 的实际实现来判断
    // custody address 通常有特定的特征或者可以通过 API 验证
    
    // 临时实现：简单的启发式判断
    // 实际项目中需要更准确的判断逻辑
    try {
      // 可能的判断方式：
      // 1. 检查地址是否在 Farcaster 的 custody 合约中
      // 2. 通过 Neynar API 验证地址类型
      // 3. 检查地址的创建方式或特征
      
      // 目前返回 false，表示需要进一步实现
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 验证地址有效性
  Future<bool> validateAddress(String address) async {
    try {
      // 基本的以太坊地址格式验证
      if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) {
        return false;
      }

      // TODO: 可以添加更多验证逻辑
      // 1. 检查地址是否为合约地址
      // 2. 检查地址是否有交易记录
      // 3. 检查地址是否在黑名单中
      
      return true;
    } catch (e) {
      debugPrint('❌ 地址验证失败: $e');
      return false;
    }
  }

  /// 格式化地址显示
  String formatAddress(String address, {int prefixLength = 6, int suffixLength = 4}) {
    if (address.length <= prefixLength + suffixLength) {
      return address;
    }
    return '${address.substring(0, prefixLength)}...${address.substring(address.length - suffixLength)}';
  }

  /// 生成地址标签建议
  String generateAddressLabel(AddressOption option) {
    switch (option.type) {
      case 'Farcaster钱包':
        return 'Farcaster 主钱包';
      case '绑定钱包':
        return '绑定钱包';
      case '已授权钱包':
        return '交易钱包';
      default:
        return '钱包 ${formatAddress(option.address)}';
    }
  }

  /// 检查地址是否需要重新授权
  Future<bool> needsReauthorization(String address) async {
    try {
      final status = _hyperliquidService.getAddressAuthStatus(address);
      return status.needsAuth;
    } catch (e) {
      return true; // 出错时默认需要重新授权
    }
  }

  /// 获取地址的授权状态描述
  String getAuthStatusDescription(String address) {
    try {
      final status = _hyperliquidService.getAddressAuthStatus(address);
      switch (status) {
        case AddressAuthStatus.unselected:
          return '未设置';
        case AddressAuthStatus.selected:
          return '已选择，需要授权';
        case AddressAuthStatus.authorizing:
          return '授权中...';
        case AddressAuthStatus.authorized:
          return '已授权，可以交易';
        case AddressAuthStatus.failed:
          return '授权失败';
        case AddressAuthStatus.expired:
          return '授权已过期';
      }
    } catch (e) {
      return '状态未知';
    }
  }
}

// 扩展方法：为 List 添加 firstOrNull
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}