import 'dart:js' as js;
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
        markReadyFunction.apply([]);
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
        final result = getUserFunction.apply([]);
        
        if (result != null) {
          // 简化的对象转换
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
        return getProviderFunction.apply([]);
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
      
      // 简化的回退方案
      try {
        return {
          'fid': _getProperty(jsObject, 'fid'),
          'username': _getProperty(jsObject, 'username'),
          'displayName': _getProperty(jsObject, 'displayName'),
          'pfpUrl': _getProperty(jsObject, 'pfpUrl'),
        };
      } catch (e2) {
        debugPrint('Error in fallback conversion: $e2');
        return {};
      }
    }
  }

  /// 安全获取 JS 对象属性
  dynamic _getProperty(dynamic jsObject, String property) {
    try {
      return jsObject[property];
    } catch (e) {
      return null;
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