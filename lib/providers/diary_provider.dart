import 'package:flutter/foundation.dart';
import '../models/trading_diary.dart';
import '../services/ipfs_service.dart';
import '../services/neynar_service.dart';
import 'package:uuid/uuid.dart';

/// 交易日记状态管理Provider
class DiaryProvider extends ChangeNotifier {
  static final DiaryProvider _instance = DiaryProvider._internal();
  factory DiaryProvider() => _instance;
  DiaryProvider._internal();

  final IpfsService _ipfsService = IpfsService();
  final NeynarService _neynarService = NeynarService();
  final Uuid _uuid = const Uuid();
  
  List<TradingDiary> _publicDiaries = [];
  List<TradingDiary> _myDiaries = [];
  List<TradingDiary> _followingDiaries = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TradingDiary> get publicDiaries => _publicDiaries;
  List<TradingDiary> get myDiaries => _myDiaries;
  List<TradingDiary> get followingDiaries => _followingDiaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初始化日记数据
  Future<void> initialize() async {
    await loadPublicDiaries();
  }

  /// 加载公开的交易日记
  Future<void> loadPublicDiaries() async {
    _setLoading(true);
    try {
      // 这里需要实现从IPFS或其他数据源获取公开日记的逻辑
      // 当前返回空列表作为占位
      _publicDiaries = [];
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('加载公开日记失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载用户自己的日记
  Future<void> loadMyDiaries(String userFid) async {
    _setLoading(true);
    try {
      final diaryHashes = await _ipfsService.getUserDiaryHashes(userFid);
      
      final diaries = <TradingDiary>[];
      for (final hash in diaryHashes) {
        try {
          final diary = await _ipfsService.getDiary(hash);
          diaries.add(diary.copyWith(ipfsHash: hash));
        } catch (e) {
          debugPrint('加载日记失败 (IPFS: $hash): $e');
        }
      }
      
      _myDiaries = diaries;
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('加载个人日记失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载关注用户的日记
  Future<void> loadFollowingDiaries(List<String> followingFids) async {
    _setLoading(true);
    try {
      final diaries = <TradingDiary>[];
      
      for (final fid in followingFids) {
        final userDiaryHashes = await _ipfsService.getUserDiaryHashes(fid);
        for (final hash in userDiaryHashes) {
          try {
            final diary = await _ipfsService.getDiary(hash);
            if (diary.isPublic) {
              diaries.add(diary.copyWith(ipfsHash: hash));
            }
          } catch (e) {
            debugPrint('加载关注用户日记失败 (IPFS: $hash): $e');
          }
        }
      }
      
      // 按时间排序
      diaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _followingDiaries = diaries;
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('加载关注用户日记失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建新的交易日记
  Future<String?> createDiary(TradingDiary diary) async {
    try {
      // 生成唯一ID
      final diaryWithId = diary.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
      );
      
      // 存储到IPFS
      final ipfsHash = await _ipfsService.storeDiary(diaryWithId);
      final finalDiary = diaryWithId.copyWith(ipfsHash: ipfsHash);
      
      // 添加到本地列表
      _myDiaries.insert(0, finalDiary);
      
      // 如果是公开日记，也添加到公开列表
      if (diary.isPublic) {
        _publicDiaries.insert(0, finalDiary);
      }
      
      notifyListeners();
      
      // 可选：发布到Farcaster
      if (diary.isPublic) {
        await _publishToFarcaster(finalDiary);
      }
      
      return ipfsHash;
    } catch (e) {
      _setError('创建日记失败: $e');
      return null;
    }
  }

  /// 更新交易日记
  Future<bool> updateDiary(TradingDiary diary) async {
    try {
      final updatedDiary = diary.copyWith(updatedAt: DateTime.now());
      
      // 重新存储到IPFS
      final ipfsHash = await _ipfsService.storeDiary(updatedDiary);
      final finalDiary = updatedDiary.copyWith(ipfsHash: ipfsHash);
      
      // 更新本地列表
      final index = _myDiaries.indexWhere((d) => d.id == diary.id);
      if (index != -1) {
        _myDiaries[index] = finalDiary;
      }
      
      // 更新公开列表
      if (diary.isPublic) {
        final publicIndex = _publicDiaries.indexWhere((d) => d.id == diary.id);
        if (publicIndex != -1) {
          _publicDiaries[publicIndex] = finalDiary;
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('更新日记失败: $e');
      return false;
    }
  }

  /// 删除交易日记
  Future<bool> deleteDiary(String diaryId, String? ipfsHash) async {
    try {
      // 从IPFS删除
      if (ipfsHash != null) {
        await _ipfsService.unpinContent(ipfsHash);
      }
      
      // 从本地列表删除
      _myDiaries.removeWhere((d) => d.id == diaryId);
      _publicDiaries.removeWhere((d) => d.id == diaryId);
      _followingDiaries.removeWhere((d) => d.id == diaryId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('删除日记失败: $e');
      return false;
    }
  }

  /// 点赞日记
  Future<void> likeDiary(String diaryId) async {
    try {
      // 这里需要实现点赞逻辑，可能需要区块链交互或中心化后端
      // 当前只更新本地状态
      _updateDiaryLikes(diaryId, 1);
    } catch (e) {
      _setError('点赞失败: $e');
    }
  }

  /// 搜索日记
  List<TradingDiary> searchDiaries(String query) {
    if (query.isEmpty) return _publicDiaries;
    
    final searchLower = query.toLowerCase();
    return _publicDiaries.where((diary) {
      return diary.title.toLowerCase().contains(searchLower) ||
             diary.content.toLowerCase().contains(searchLower) ||
             diary.tags.any((tag) => tag.toLowerCase().contains(searchLower));
    }).toList();
  }

  /// 按类型筛选日记
  List<TradingDiary> filterDiariesByType(DiaryType type) {
    return _publicDiaries.where((diary) => diary.type == type).toList();
  }

  /// 刷新所有数据
  Future<void> refreshAll({
    String? userFid,
    List<String>? followingFids,
  }) async {
    await Future.wait([
      loadPublicDiaries(),
      if (userFid != null) loadMyDiaries(userFid),
      if (followingFids != null) loadFollowingDiaries(followingFids),
    ]);
  }

  /// 发布到Farcaster
  Future<void> _publishToFarcaster(TradingDiary diary) async {
    try {
      final text = '${diary.title}\n\n${diary.summary ?? diary.content.substring(0, 100)}...\n\n#ThunderTrack';
      await _neynarService.publishCast(
        text: text,
        imageUrls: diary.imageUrls.isNotEmpty ? [diary.imageUrls.first] : null,
      );
    } catch (e) {
      debugPrint('发布到Farcaster失败: $e');
      // 不抛出错误，因为这是可选功能
    }
  }

  /// 更新日记点赞数
  void _updateDiaryLikes(String diaryId, int increment) {
    // 更新所有列表中的对应日记
    for (int i = 0; i < _publicDiaries.length; i++) {
      if (_publicDiaries[i].id == diaryId) {
        _publicDiaries[i] = _publicDiaries[i].copyWith(
          likes: _publicDiaries[i].likes + increment,
        );
        break;
      }
    }
    
    for (int i = 0; i < _followingDiaries.length; i++) {
      if (_followingDiaries[i].id == diaryId) {
        _followingDiaries[i] = _followingDiaries[i].copyWith(
          likes: _followingDiaries[i].likes + increment,
        );
        break;
      }
    }
    
    notifyListeners();
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
}