import 'package:dio/dio.dart';
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

  /// 获取用户信息
  Future<User> getUserByFid(String fid) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.neynarUser}/$fid',
        baseUrl: AppConfig.neynarBaseUrl,
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseUser(response.data['result']['user']);
      }
      throw ApiException('获取用户信息失败');
    } catch (e) {
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

  /// 获取认证选项
  Options _getAuthOptions() {
    return Options(
      headers: {
        'Authorization': 'Bearer ${AppConfig.neynarApiKey}',
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
      bio: userData['profile']['bio']['text'],
      followers: [], // 需要单独获取
      following: [], // 需要单独获取
      isVerified: userData['power_badge'] ?? false,
      createdAt: DateTime.parse(userData['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}