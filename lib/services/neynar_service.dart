import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import '../utils/api_client.dart';

/// Neynar API服务 (Farcaster)
class NeynarService {
  static final NeynarService _instance = NeynarService._internal();
  factory NeynarService() => _instance;
  NeynarService._internal();

  final ApiClient _apiClient = ApiClient();

  /// 创建新的signer
  Future<Map<String, dynamic>?> createSigner([Function(String)? logCallback]) async {
    try {
      logCallback?.call('🔄 创建新的signer...');
      logCallback?.call('🌐 API URL: ${AppConfig.neynarBaseUrl}/v2/farcaster/signer');
      logCallback?.call('🔑 API Key: ${AppConfig.neynarApiKey.substring(0, 10)}...');
      
      final response = await _apiClient.post(
        '/v2/farcaster/signer',
        data: {}, // POST请求不需要body参数
        baseUrl: AppConfig.neynarBaseUrl,
        options: _getAuthOptions(),
      );

      logCallback?.call('📨 Signer创建响应: ${response.statusCode}');
      logCallback?.call('📄 响应内容: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final result = response.data as Map<String, dynamic>;
        final signerUuid = result['signer_uuid'] as String?;
        final status = result['status'] as String?;
        final approvalUrl = result['signer_approval_url'] as String?;
        
        logCallback?.call('✅ Signer创建成功:');
        logCallback?.call('   UUID: ${signerUuid?.substring(0, 8)}...');
        logCallback?.call('   状态: $status');
        logCallback?.call('   批准URL: $approvalUrl');
        
        return result;
      }
      
      logCallback?.call('❌ 创建signer失败: 状态码${response.statusCode}');
      return null;
    } catch (e) {
      logCallback?.call('❌ 创建signer异常: $e');
      logCallback?.call('🔍 异常类型: ${e.runtimeType}');
      if (e.toString().contains('DioException')) {
        logCallback?.call('🌐 网络请求详情: $e');
      }
      return null;
    }
  }

  /// 检查signer状态
  Future<Map<String, dynamic>?> getSignerStatus(String signerUuid) async {
    try {
      debugPrint('🔄 检查signer状态: ${signerUuid.substring(0, 8)}...');
      
      final response = await _apiClient.get(
        '/v2/farcaster/signer?signer_uuid=$signerUuid',
        baseUrl: AppConfig.neynarBaseUrl,
        options: _getAuthOptions(),
      );

      debugPrint('📨 Signer状态响应: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        final result = response.data as Map<String, dynamic>;
        final status = result['status'] as String?;
        debugPrint('📊 Signer状态: $status');
        return result;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ 获取signer状态异常: $e');
      return null;
    }
  }

  /// 获取或创建signer UUID
  Future<Map<String, dynamic>?> getOrCreateSignerUuid(String fid, [Function(String)? logCallback]) async {
    try {
      logCallback?.call('🔄 为FID $fid 获取或创建signer...');
      
      // 首先尝试创建新的signer
      logCallback?.call('📞 开始调用createSigner()...');
      final signerInfo = await createSigner(logCallback);
      logCallback?.call('📞 createSigner()调用完成，结果: ${signerInfo != null ? "成功" : "失败"}');
      
      if (signerInfo == null) {
        logCallback?.call('❌ createSigner返回null');
        return null;
      }
      
      final signerUuid = signerInfo['signer_uuid'] as String?;
      final status = signerInfo['status'] as String?;
      final approvalUrl = signerInfo['signer_approval_url'] as String?;
      
      if (signerUuid != null) {
        logCallback?.call('✅ Signer UUID: ${signerUuid.substring(0, 8)}...');
        logCallback?.call('📊 当前状态: $status');
        
        // 如果需要批准，显示批准URL
        if (status == 'pending_approval' && approvalUrl != null) {
          logCallback?.call('⚠️ Signer需要用户批准');
          logCallback?.call('🔗 批准URL: $approvalUrl');
        }
        
        return signerInfo; // 返回完整的signer信息
      }
      
      logCallback?.call('❌ signerInfo中没有找到signer_uuid');
      return null;
    } catch (e) {
      logCallback?.call('❌ 获取/创建signer失败: $e');
      logCallback?.call('🔍 异常详情: ${e.toString()}');
      return null;
    }
  }

  /// 获取用户信息
  Future<User> getUserByFid(String fid) async {
    try {
      debugPrint('🔄 调用Neynar API获取用户信息，FID: $fid');
      debugPrint('🔗 API URL: ${AppConfig.neynarBaseUrl}${ApiEndpoints.neynarUserBulk}?fids=$fid');
      debugPrint('🔑 API Key: ${AppConfig.neynarApiKey.substring(0, 8)}...');
      
      final response = await _apiClient.get(
        '${ApiEndpoints.neynarUserBulk}?fids=$fid',
        baseUrl: AppConfig.neynarBaseUrl,
        options: _getAuthOptions(),
      );

      debugPrint('✅ Neynar API响应状态: ${response.statusCode}');
      debugPrint('📋 响应数据结构: ${response.data?.keys}');

      if (response.statusCode == 200 && response.data != null) {
        final users = response.data['users'] as List;
        if (users.isNotEmpty) {
          final user = _parseUser(users.first);
          debugPrint('🎉 用户解析成功: ${user.username} (${user.displayName})');
          return user;
        } else {
          throw ApiException('用户数据为空');
        }
      }
      throw ApiException('获取用户信息失败');
    } catch (e) {
      debugPrint('❌ Neynar API调用失败: $e');
      throw ApiException('获取用户信息失败: $e');
    }
  }

  /// 根据用户名获取用户信息
  Future<User> getUserByUsername(String username) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.neynarUser,
        baseUrl: AppConfig.neynarBaseUrl,
        queryParameters: {'username': username},
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final users = response.data['result']['users'] as List;
        if (users.isNotEmpty) {
          return _parseUser(users.first);
        }
      }
      throw ApiException('用户不存在');
    } catch (e) {
      throw ApiException('获取用户信息失败: $e');
    }
  }

  /// 根据钱包地址获取用户信息 (Sign-in with Ethereum)
  Future<User?> getUserByWalletAddress(String walletAddress) async {
    try {
      debugPrint('🔄 通过钱包地址查找Farcaster用户: $walletAddress');

      final response = await _apiClient.get(
        '/v2/farcaster/user/bulk-by-address',
        baseUrl: AppConfig.neynarBaseUrl,
        queryParameters: {'addresses': walletAddress.toLowerCase()},
        options: _getAuthOptions(),
      );

      debugPrint('📨 钱包地址查询响应: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final addressData = response.data as Map<String, dynamic>;
        final usersList = addressData[walletAddress.toLowerCase()];

        if (usersList != null && usersList is List && usersList.isNotEmpty) {
          final userData = usersList.first;
          debugPrint('✅ 找到关联的Farcaster用户: ${userData['username']}');
          return _parseUser(userData);
        } else {
          debugPrint('⚠️ 钱包地址未关联Farcaster账户');
          return null;
        }
      }

      debugPrint('❌ 查询钱包地址失败: 状态码${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ 钱包地址查询异常: $e');
      return null; // 不抛出异常，返回null表示未找到
    }
  }

  /// 获取用户关注列表
  Future<List<String>> getFollowing(String fid) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.neynarFollows}/$fid',
        baseUrl: AppConfig.neynarBaseUrl,
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final following = response.data['result']['users'] as List;
        return following.map((user) => user['fid'].toString()).toList();
      }
      return [];
    } catch (e) {
      throw ApiException('获取关注列表失败: $e');
    }
  }

  /// 发布Cast (用于分享交易日记)
  Future<String> publishCast({
    required String text,
    List<String>? imageUrls,
    String? parentCastId,
  }) async {
    try {
      final castData = {
        'text': text,
        'signer_uuid': '', // 需要从认证信息获取
      };

      if (imageUrls != null && imageUrls.isNotEmpty) {
//        castData['embeds'] = imageUrls.map((url) => {'url': url}).toList();
      }

      if (parentCastId != null) {
        castData['parent'] = parentCastId;
      }

      final response = await _apiClient.post(
        ApiEndpoints.neynarCast,
        baseUrl: AppConfig.neynarBaseUrl,
        data: castData,
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['result']['cast']['hash'];
      }
      throw ApiException('发布失败');
    } catch (e) {
      throw ApiException('发布失败: $e');
    }
  }

  /// 获取用户的通知
  Future<List<Map<String, dynamic>>> getNotifications(String fid) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.neynarNotifications}/$fid',
        baseUrl: AppConfig.neynarBaseUrl,
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return List<Map<String, dynamic>>.from(
          response.data['result']['notifications'] ?? []
        );
      }
      return [];
    } catch (e) {
      throw ApiException('获取通知失败: $e');
    }
  }

  /// 关注用户
  Future<bool> followUser(String targetFid) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.neynarFollows,
        baseUrl: AppConfig.neynarBaseUrl,
        data: {
          'signer_uuid': '', // 需要从认证信息获取
          'target_fids': [int.parse(targetFid)],
        },
        options: _getAuthOptions(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw ApiException('关注失败: $e');
    }
  }

  /// 取消关注用户
  Future<bool> unfollowUser(String targetFid) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.neynarFollows,
        baseUrl: AppConfig.neynarBaseUrl,
        data: {
          'signer_uuid': '', // 需要从认证信息获取
          'target_fids': [int.parse(targetFid)],
        },
        options: _getAuthOptions(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw ApiException('取消关注失败: $e');
    }
  }

  /// 注册开发者管理的认证地址
  Future<Map<String, dynamic>?> registerSignedKey({
    required String address,
    required int appFid,
    required int deadline,
    required String signature,
    String? redirectUrl,
  }) async {
    try {
      debugPrint('🔄 注册认证地址: $address for App FID: $appFid');
      
      final data = {
        'address': address,
        'app_fid': appFid,
        'deadline': deadline,
        'signature': signature,
        if (redirectUrl != null) 'redirect_url': redirectUrl,
      };

      final response = await _apiClient.post(
        '/v2/farcaster/auth_address/developer_managed/signed_key/',
        baseUrl: AppConfig.neynarBaseUrl,
        data: data,
        options: _getAuthOptions(),
      );

      debugPrint('✅ 认证地址注册响应: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw ApiException('注册认证地址失败');
    } catch (e) {
      debugPrint('❌ 认证地址注册失败: $e');
      throw ApiException('注册认证地址失败: $e');
    }
  }

  /// 查询认证地址状态
  Future<Map<String, dynamic>?> getAuthAddressStatus({
    required String address,
  }) async {
    try {
      debugPrint('🔄 查询认证地址状态: $address');
      
      final response = await _apiClient.get(
        '/v2/farcaster/auth_address/developer_managed/',
        baseUrl: AppConfig.neynarBaseUrl,
        queryParameters: {'address': address},
        options: _getAuthOptions(),
      );

      debugPrint('✅ 认证地址状态查询响应: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw ApiException('查询认证地址状态失败');
    } catch (e) {
      debugPrint('❌ 查询认证地址状态失败: $e');
      throw ApiException('查询认证地址状态失败: $e');
    }
  }

  /// 获取认证选项
  Options _getAuthOptions() {
    return Options(
      headers: {
        'x-api-key': AppConfig.neynarApiKey,
        'Content-Type': 'application/json',
      },
    );
  }

  /// 解析用户数据
  User _parseUser(Map<String, dynamic> userData) {
    return User(
      fid: userData['fid'].toString(),
      username: userData['username'] ?? '',
      displayName: userData['display_name'] ?? '',
      avatarUrl: userData['pfp_url'],
      bio: userData['profile']?['bio']?['text'] ?? '',
      followers: [], // 需要单独获取
      following: [], // 需要单独获取
      isVerified: userData['power_badge'] ?? false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)), // API没有created_at，使用默认值
      walletAddress: userData['verifications']?.isNotEmpty == true 
          ? userData['verifications'][0] 
          : null,
    );
  }
}