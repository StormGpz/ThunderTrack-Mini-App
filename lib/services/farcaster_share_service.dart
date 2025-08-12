import 'dart:js' as js;
import '../models/trading_diary.dart';

/// Farcaster分享服务
class FarcasterShareService {
  static final FarcasterShareService _instance = FarcasterShareService._internal();
  factory FarcasterShareService() => _instance;
  FarcasterShareService._internal();

  /// 分享日记到Farcaster
  Future<bool> shareDiary(TradingDiary diary) async {
    try {
      // 检查是否在Farcaster Mini App环境中
      if (!_isInMiniAppEnvironment()) {
        // 在普通Web环境中，生成分享链接
        return _shareViaWeb(diary);
      }
      
      // 在Mini App环境中，使用SDK分享
      return await _shareViaSdk(diary);
    } catch (e) {
      print('分享失败: $e');
      return false;
    }
  }

  /// 生成日记分享文本
  String generateShareText(TradingDiary diary) {
    final StringBuffer text = StringBuffer();
    
    // 添加标题
    text.writeln('📊 ${diary.title}');
    text.writeln();
    
    // 添加类型标识
    text.writeln('${_getTypeEmoji(diary.type)} ${diary.typeDisplayName}');
    
    // 添加内容预览
    final contentPreview = _getContentPreview(diary.content);
    if (contentPreview.isNotEmpty) {
      text.writeln();
      text.writeln(contentPreview);
    }
    
    // 添加标签
    if (diary.tags.isNotEmpty) {
      text.writeln();
      text.write(diary.tags.map((tag) => '#$tag').join(' '));
    }
    
    // 添加应用标识
    text.writeln();
    text.writeln('#ThunderTrack #交易日记');
    
    return text.toString();
  }

  /// 检查是否在Mini App环境中
  bool _isInMiniAppEnvironment() {
    try {
      return js.context.hasProperty('farcasterMiniApp') &&
             js.context['farcasterMiniApp'] != null;
    } catch (e) {
      return false;
    }
  }

  /// 通过SDK分享
  Future<bool> _shareViaSdk(TradingDiary diary) async {
    try {
      final shareText = generateShareText(diary);
      
      // 调用Farcaster Mini App SDK的分享功能
      final result = await js.context.callMethod('shareCast', [
        js.JsObject.jsify({
          'text': shareText,
          'embeds': diary.imageUrls.isNotEmpty ? diary.imageUrls : null,
        })
      ]);
      
      return result == true;
    } catch (e) {
      print('SDK分享失败: $e');
      return false;
    }
  }

  /// 通过Web分享
  bool _shareViaWeb(TradingDiary diary) {
    try {
      final shareText = generateShareText(diary);
      final encodedText = Uri.encodeComponent(shareText);
      
      // 生成包含Mini App信息的分享链接
      final appUrl = 'https://thunder-track-mini-app.vercel.app?miniApp=true&diary=${diary.id}';
      final encodedUrl = Uri.encodeComponent(appUrl);
      
      // 使用Warpcast的分享URL，包含embed信息
      final shareUrl = 'https://warpcast.com/~/compose?text=$encodedText&embeds%5B%5D=$encodedUrl';
      
      // 在新窗口中打开分享页面
      js.context.callMethod('open', [shareUrl, '_blank']);
      
      return true;
    } catch (e) {
      print('Web分享失败: $e');
      return false;
    }
  }

  /// 获取内容预览
  String _getContentPreview(String content, {int maxLength = 200}) {
    // 移除Markdown格式符号
    String preview = content
        .replaceAll(RegExp(r'[#*`_\[\]()]'), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
    
    if (preview.length > maxLength) {
      // 在单词边界截断
      int cutoff = maxLength;
      while (cutoff > 0 && preview[cutoff] != ' ') {
        cutoff--;
      }
      if (cutoff == 0) cutoff = maxLength;
      
      preview = '${preview.substring(0, cutoff)}...';
    }
    
    return preview;
  }

  /// 获取类型对应的Emoji
  String _getTypeEmoji(DiaryType type) {
    switch (type) {
      case DiaryType.singleTrade:
        return '📊';
      case DiaryType.strategySummary:
        return '🎯';
      case DiaryType.freeForm:
        return '📝';
    }
  }

  /// 生成分享URL（供IPFS存储使用）
  String generateShareUrl(TradingDiary diary) {
    if (diary.ipfsHash != null) {
      return 'https://thunder-track-mini-app.vercel.app/diary/${diary.ipfsHash}';
    }
    return 'https://thunder-track-mini-app.vercel.app/diary/${diary.id}';
  }

  /// 检查分享权限
  bool canShare() {
    return _isInMiniAppEnvironment() || _canOpenWindow();
  }

  /// 检查是否可以打开新窗口
  bool _canOpenWindow() {
    try {
      return js.context.hasProperty('open');
    } catch (e) {
      return false;
    }
  }
}