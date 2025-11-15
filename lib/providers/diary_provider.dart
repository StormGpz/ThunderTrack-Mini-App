import 'package:flutter/foundation.dart';
import '../models/trading_diary.dart';
import 'package:uuid/uuid.dart';

/// 交易日记状态管理Provider
class DiaryProvider extends ChangeNotifier {
  static final DiaryProvider _instance = DiaryProvider._internal();
  factory DiaryProvider() => _instance;
  DiaryProvider._internal();

  final Uuid _uuid = const Uuid();

  List<TradingDiary> _myDiaries = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TradingDiary> get myDiaries => _myDiaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载用户自己的日记
  Future<void> loadMyDiaries() async {
    _setLoading(true);
    try {
      // TODO: 从本地存储或服务器加载日记
      _myDiaries = [];
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('加载个人日记失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建新的日记
  Future<String?> createDiary(TradingDiary diary) async {
    try {
      // 生成唯一ID
      final diaryWithId = diary.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
      );

      // 添加到本地列表
      _myDiaries.insert(0, diaryWithId);
      notifyListeners();

      return diaryWithId.id;
    } catch (e) {
      _setError('创建日记失败: $e');
      return null;
    }
  }

  /// 更新日记
  Future<bool> updateDiary(TradingDiary diary) async {
    try {
      final updatedDiary = diary.copyWith(updatedAt: DateTime.now());

      // 更新本地列表
      final index = _myDiaries.indexWhere((d) => d.id == diary.id);
      if (index != -1) {
        _myDiaries[index] = updatedDiary;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('更新日记失败: $e');
      return false;
    }
  }

  /// 删除日记
  Future<bool> deleteDiary(String diaryId) async {
    try {
      _myDiaries.removeWhere((d) => d.id == diaryId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('删除日记失败: $e');
      return false;
    }
  }

  /// 搜索日记
  List<TradingDiary> searchDiaries(String query) {
    if (query.isEmpty) return _myDiaries;

    final searchLower = query.toLowerCase();
    return _myDiaries.where((diary) {
      return diary.title.toLowerCase().contains(searchLower) ||
             diary.content.toLowerCase().contains(searchLower) ||
             diary.tags.any((tag) => tag.toLowerCase().contains(searchLower));
    }).toList();
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
