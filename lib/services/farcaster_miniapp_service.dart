import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Farcaster Mini App 服务
/// 处理与 Farcaster Mini App SDK 的 JavaScript 交互
class FarcasterMiniAppService {
  static final FarcasterMiniAppService _instance = FarcasterMiniAppService._internal();
  factory FarcasterMiniAppService() => _instance;
  FarcasterMiniAppService._internal();

  /// 检查是否在 Mini App 环境中运行
  bool get isMiniAppEnvironment {
    if (!kIsWeb) return false;
    
    try {
      final currentUrl = js.context['location']['href'] as String?;
      return currentUrl?.contains('miniApp=true') == true ||
             currentUrl?.contains('/mini') == true ||
             js.context['window'] != js.context['parent'];
    } catch (e) {
      debugPrint('Error checking Mini App environment: $e');
      return false;
    }
  }

  /// 调用 Mini App 准备就绪信号
  Future<void> markReady() async {
    if (!kIsWeb) return;
    
    try {
      final markReadyFunction = js.context['markMiniAppReady'];
      if (markReadyFunction != null) {
        await js_util.promiseToFuture(js_util.callMethod(markReadyFunction, 'call', [js.context]));
        debugPrint('Mini App ready signal sent successfully');
      } else {
        debugPrint('markMiniAppReady function not found');
      }
    } catch (e) {
      debugPrint('Error sending Mini App ready signal: $e');
    }
  }

  /// 获取 Farcaster 用户信息
  Future<Map<String, dynamic>?> getFarcasterUser() async {
    if (!kIsWeb) return null;
    
    try {
      final getUserFunction = js.context['getFarcasterUser'];
      if (getUserFunction != null) {
        final result = await js_util.promiseToFuture(
          js_util.callMethod(getUserFunction, 'call', [js.context])
        );
        
        if (result != null) {
          // 将 JavaScript 对象转换为 Dart Map
          return _jsObjectToMap(result);
        }
      } else {
        debugPrint('getFarcasterUser function not found');
      }
    } catch (e) {
      debugPrint('Error getting Farcaster user: $e');
    }
    
    return null;
  }

  /// 获取以太坊钱包提供者
  dynamic getEthereumProvider() {
    if (!kIsWeb) return null;
    
    try {
      final getProviderFunction = js.context['getEthereumProvider'];
      if (getProviderFunction != null) {
        return js_util.callMethod(getProviderFunction, 'call', [js.context]);
      } else {
        debugPrint('getEthereumProvider function not found');
      }
    } catch (e) {
      debugPrint('Error getting Ethereum provider: $e');
    }
    
    return null;
  }

  /// 检查 Farcaster SDK 是否可用
  bool get isSdkAvailable {
    if (!kIsWeb) return false;
    
    try {
      return js.context['farcasterSdk'] != null;
    } catch (e) {
      debugPrint('Error checking SDK availability: $e');
      return false;
    }
  }

  /// 获取 Mini App 环境信息
  Map<String, dynamic> getEnvironmentInfo() {
    if (!kIsWeb) {
      return {
        'platform': 'non-web',
        'isMiniApp': false,
        'sdkAvailable': false,
        'userAgent': 'flutter-native',
      };
    }
    
    try {
      final userAgent = js.context['navigator']['userAgent'] as String?;
      final currentUrl = js.context['location']['href'] as String?;
      
      return {
        'platform': 'web',
        'isMiniApp': isMiniAppEnvironment,
        'sdkAvailable': isSdkAvailable,
        'userAgent': userAgent ?? 'unknown',
        'currentUrl': currentUrl ?? 'unknown',
        'isWarpcast': userAgent?.contains('Warpcast') == true,
        'isFarcasterClient': _isFarcasterClient(userAgent),
      };
    } catch (e) {
      debugPrint('Error getting environment info: $e');
      return {
        'platform': 'web',
        'isMiniApp': false,
        'sdkAvailable': false,
        'userAgent': 'error',
        'error': e.toString(),
      };
    }
  }

  /// 将 JavaScript 对象转换为 Dart Map
  Map<String, dynamic> _jsObjectToMap(dynamic jsObject) {
    if (jsObject == null) return {};
    
    try {
      // 尝试使用 JSON 序列化/反序列化
      final jsonString = js.context['JSON'].callMethod('stringify', [jsObject]);
      return jsonDecode(jsonString as String) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error converting JS object to map: $e');
      
      // 回退到手动转换常见属性
      try {
        final Map<String, dynamic> result = {};
        
        // 尝试获取常见的用户属性
        if (js_util.hasProperty(jsObject, 'fid')) {
          result['fid'] = js_util.getProperty(jsObject, 'fid');
        }
        if (js_util.hasProperty(jsObject, 'username')) {
          result['username'] = js_util.getProperty(jsObject, 'username');
        }
        if (js_util.hasProperty(jsObject, 'displayName')) {
          result['displayName'] = js_util.getProperty(jsObject, 'displayName');
        }
        if (js_util.hasProperty(jsObject, 'pfpUrl')) {
          result['pfpUrl'] = js_util.getProperty(jsObject, 'pfpUrl');
        }
        if (js_util.hasProperty(jsObject, 'bio')) {
          result['bio'] = js_util.getProperty(jsObject, 'bio');
        }
        if (js_util.hasProperty(jsObject, 'followers')) {
          result['followers'] = js_util.getProperty(jsObject, 'followers');
        }
        if (js_util.hasProperty(jsObject, 'following')) {
          result['following'] = js_util.getProperty(jsObject, 'following');
        }
        if (js_util.hasProperty(jsObject, 'verified')) {
          result['verified'] = js_util.getProperty(jsObject, 'verified');
        }
        
        return result;
      } catch (e2) {
        debugPrint('Error in fallback conversion: $e2');
        return {};
      }
    }
  }

  /// 检查是否为 Farcaster 客户端
  bool _isFarcasterClient(String? userAgent) {
    if (userAgent == null) return false;
    
    final farcasterClientIndicators = [
      'Warpcast',
      'Farcaster',
      'Supercast',
      'Rainbow',
      'FarQuest',
    ];
    
    return farcasterClientIndicators.any(
      (indicator) => userAgent.contains(indicator),
    );
  }

  /// 日志环境信息（用于调试）
  void logEnvironmentInfo() {
    final info = getEnvironmentInfo();
    debugPrint('=== Farcaster Mini App Environment Info ===');
    info.forEach((key, value) {
      debugPrint('$key: $value');
    });
    debugPrint('==========================================');
  }
}