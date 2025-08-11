import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/trading_diary.dart';
import '../models/trade.dart';
import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import '../utils/api_client.dart';

/// IPFS存储服务 (使用Pinata作为网关)
class IpfsService {
  static final IpfsService _instance = IpfsService._internal();
  factory IpfsService() => _instance;
  IpfsService._internal();

  final ApiClient _apiClient = ApiClient();

  /// 将交易日记存储到IPFS
  Future<String> storeDiary(TradingDiary diary) async {
    try {
      // 准备要存储的数据
      final diaryData = {
        'id': diary.id,
        'authorFid': diary.authorFid,
        'title': diary.title,
        'content': diary.content,
        'category': diary.category,
        'tags': diary.tags,
        'imageUrls': diary.imageUrls,
        'trades': diary.trades.map((trade) => trade.toJson()).toList(),
        'createdAt': diary.createdAt.toIso8601String(),
        'updatedAt': diary.updatedAt?.toIso8601String(),
        'isPublic': diary.isPublic,
        'summary': diary.summary,
        'rating': diary.rating,
        'metadata': {
          'version': '1.0',
          'type': 'trading_diary',
          'app': 'ThunderTrack',
        }
      };

      final response = await _apiClient.post(
        ApiEndpoints.pinataPin,
        baseUrl: AppConfig.pinataApiUrl,
        data: {
          'pinataContent': diaryData,
          'pinataMetadata': {
            'name': 'TradingDiary_${diary.id}',
            'keyvalues': {
              'author': diary.authorFid,
              'category': diary.category,
              'created': diary.createdAt.toIso8601String(),
            }
          },
          'pinataOptions': {
            'cidVersion': 1,
          }
        },
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['IpfsHash'];
      }
      throw ApiException('存储到IPFS失败');
    } catch (e) {
      throw ApiException('存储到IPFS失败: $e');
    }
  }

  /// 从IPFS获取交易日记
  Future<TradingDiary> getDiary(String ipfsHash) async {
    try {
      final response = await _apiClient.get(
        '${AppConfig.ipfsGateway}$ipfsHash',
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseDiaryFromIpfs(response.data);
      }
      throw ApiException('从IPFS获取日记失败');
    } catch (e) {
      throw ApiException('从IPFS获取日记失败: $e');
    }
  }

  /// 存储图片到IPFS
  Future<String> storeImage(List<int> imageBytes, String fileName) async {
    try {
      // 创建FormData用于文件上传
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
        'pinataMetadata': jsonEncode({
          'name': fileName,
          'keyvalues': {
            'type': 'image',
            'app': 'ThunderTrack',
          }
        }),
        'pinataOptions': jsonEncode({
          'cidVersion': 1,
        }),
      });

      final response = await _apiClient.post(
        '/pinning/pinFileToIPFS',
        baseUrl: AppConfig.pinataApiUrl,
        data: formData,
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['IpfsHash'];
      }
      throw ApiException('图片上传到IPFS失败');
    } catch (e) {
      throw ApiException('图片上传到IPFS失败: $e');
    }
  }

  /// 获取用户的所有日记列表
  Future<List<String>> getUserDiaryHashes(String authorFid) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.pinataList,
        baseUrl: AppConfig.pinataApiUrl,
        queryParameters: {
          'status': 'pinned',
          'metadata[keyvalues][author]': authorFid,
          'metadata[keyvalues][type]': 'trading_diary',
        },
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final rows = response.data['rows'] as List;
        return rows.map((row) => row['ipfs_pin_hash'].toString()).toList();
      }
      return [];
    } catch (e) {
      throw ApiException('获取日记列表失败: $e');
    }
  }

  /// 删除IPFS上的内容
  Future<bool> unpinContent(String ipfsHash) async {
    try {
      final response = await _apiClient.delete(
        '${ApiEndpoints.pinataUnpin}/$ipfsHash',
        baseUrl: AppConfig.pinataApiUrl,
        options: _getAuthOptions(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw ApiException('删除IPFS内容失败: $e');
    }
  }

  /// 获取认证选项
  Options _getAuthOptions() {
    return Options(
      headers: {
        'Authorization': 'Bearer ${AppConfig.pinataApiKey}',
      },
    );
  }

  /// 从IPFS数据解析日记对象
  TradingDiary _parseDiaryFromIpfs(Map<String, dynamic> data) {
    final trades = (data['trades'] as List? ?? [])
        .map((tradeData) => Trade.fromJson(tradeData))
        .toList();

    return TradingDiary(
      id: data['id'],
      authorFid: data['authorFid'],
      title: data['title'],
      content: data['content'],
      category: data['category'],
      tags: List<String>.from(data['tags'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      trades: trades,
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt']) 
          : null,
      isPublic: data['isPublic'] ?? true,
      ipfsHash: null, // 会在外部设置
      summary: data['summary'],
      rating: data['rating']?.toDouble(),
    );
  }
}