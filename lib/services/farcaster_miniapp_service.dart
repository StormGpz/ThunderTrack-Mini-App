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
      final userAgent = js.context['navigator']['userAgent'] as String?;
      final currentUrl = js.context['location']['href'] as String?;
      final isIframe = js.context['window'] != js.context['parent'];
      
      // 检查多种Farcaster环境指标
      final indicators = [
        // URL参数检测
        currentUrl?.contains('miniApp=true') == true,
        currentUrl?.contains('/mini') == true,
        
        // iframe检测
        isIframe,
        
        // User Agent检测
        userAgent?.contains('Warpcast') == true,
        userAgent?.contains('Farcaster') == true,
        userAgent?.contains('Supercast') == true,
        
        // 检查是否有Farcaster SDK
        js.context['farcasterSDK'] != null,
      ];
      
      final isDetected = indicators.any((indicator) => indicator);
      
      debugPrint('🔍 Mini App环境检测:');
      debugPrint('   URL: $currentUrl');
      debugPrint('   UserAgent: $userAgent');
      debugPrint('   isIframe: $isIframe');
      debugPrint('   hasSDK: ${js.context['farcasterSDK'] != null}');
      debugPrint('   结果: ${isDetected ? "✅ Farcaster环境" : "❌ 非Farcaster环境"}');
      
      return isDetected;
    } catch (e) {
      debugPrint('Error checking Mini App environment: $e');
      return false;
    }
  }

  /// 调用 Mini App 准备就绪信号
  Future<void> markReady() async {
    if (!kIsWeb) return;
    
    try {
      // 首先尝试直接调用 farcasterSDK
      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK != null) {
        final actions = farcasterSDK['actions'];
        if (actions != null) {
          final ready = actions['ready'];
          if (ready != null) {
            // 调用 sdk.actions.ready()
            ready.apply([]);
            debugPrint('Farcaster SDK ready() called successfully');
            return;
          }
        }
      }
      
      // 备用方案：检查是否有全局 ready 函数
      final markReadyFunction = js.context['markMiniAppReady'];
      if (markReadyFunction != null) {
        markReadyFunction.apply([]);
        debugPrint('Global markMiniAppReady() called successfully');
      } else {
        debugPrint('No ready function found (SDK or global)');
      }
    } catch (e) {
      debugPrint('Error sending Mini App ready signal: $e');
    }
  }

  /// 获取 Farcaster 用户信息（通过 SDK）
  Future<Map<String, dynamic>?> getFarcasterUser() async {
    if (!kIsWeb) return null;
    
    try {
      // 首先检查 Farcaster SDK 是否已加载
      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK == null) {
        debugPrint('Farcaster SDK not found in global context');
        return null;
      }
      
      // 获取 SDK context
      final sdkContext = farcasterSDK['context'];
      if (sdkContext == null) {
        debugPrint('SDK context not found');
        return null;
      }
      
      // 获取用户信息
      final user = sdkContext['user'];
      if (user == null) {
        debugPrint('User not found in SDK context');
        return null;
      }
      
      // 转换为 Dart Map
      final userMap = _jsObjectToMap(user);
      debugPrint('Farcaster user data: $userMap');
      return userMap;
      
    } catch (e) {
      debugPrint('Error getting Farcaster user: $e');
      return null;
    }
  }

  /// 使用 Quick Auth 获取认证token
  Future<String?> getQuickAuthToken() async {
    if (!kIsWeb) return null;
    
    try {
      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK == null) {
        debugPrint('Farcaster SDK not found');
        return null;
      }
      
      final quickAuth = farcasterSDK['quickAuth'];
      if (quickAuth == null) {
        debugPrint('Quick Auth not found in SDK');
        return null;
      }
      
      final getToken = quickAuth['getToken'];
      if (getToken == null) {
        debugPrint('getToken method not found');
        return null;
      }
      
      // 调用 sdk.quickAuth.getToken()
      final result = await _callAsyncFunction(getToken, []);
      
      if (result != null && result['token'] != null) {
        final token = result['token'] as String;
        debugPrint('Quick Auth token obtained: ${token.substring(0, 20)}...');
        return token;
      }
      
      debugPrint('No token returned from Quick Auth');
      return null;
      
    } catch (e) {
      debugPrint('Error getting Quick Auth token: $e');
      return null;
    }
  }

  /// 使用 Sign In with Farcaster
  Future<Map<String, dynamic>?> signInWithFarcaster() async {
    if (!kIsWeb) return null;
    
    try {
      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK == null) {
        debugPrint('Farcaster SDK not found');
        return null;
      }
      
      final actions = farcasterSDK['actions'];
      if (actions == null) {
        debugPrint('Actions not found in SDK');
        return null;
      }
      
      final signIn = actions['signIn'];
      if (signIn == null) {
        debugPrint('signIn method not found');
        return null;
      }
      
      // 生成随机nonce（至少8个字符）
      final nonce = _generateNonce();
      
      // 调用 sdk.actions.signIn()
      final signInParams = js.JsObject.jsify({
        'nonce': nonce,
        'acceptAuthAddress': true, // 支持Auth Address以获得最佳用户体验
      });
      
      final result = await _callAsyncFunction(signIn, [signInParams]);
      
      if (result != null) {
        final resultMap = _jsObjectToMap(result);
        debugPrint('SIWF sign in successful');
        return {
          ...resultMap,
          'nonce': nonce, // 包含nonce以便验证
        };
      }
      
      debugPrint('No result returned from sign in');
      return null;
      
    } catch (e) {
      debugPrint('Error signing in with Farcaster: $e');
      
      // 检查是否是用户拒绝错误
      if (e.toString().contains('RejectedByUser')) {
        throw Exception('用户拒绝了登录请求');
      }
      
      throw Exception('Farcaster登录失败: $e');
    }
  }

  /// 生成随机nonce
  String _generateNonce() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = js.context['Math']['random'];
    final result = StringBuffer();
    
    for (int i = 0; i < 16; i++) {
      final randomIndex = (random.apply([]) * chars.length).floor();
      result.write(chars[randomIndex]);
    }
    
    return result.toString();
  }

  /// 调用异步JavaScript函数
  Future<dynamic> _callAsyncFunction(dynamic jsFunction, List<dynamic> args) async {
    try {
      final result = jsFunction.apply(args);
      
      // 如果返回的是Promise，等待其完成
      if (result != null && result['then'] != null) {
        // 这是一个Promise，我们需要等待它
        return await _promiseToFuture(result);
      }
      
      return result;
    } catch (e) {
      debugPrint('Error calling async JS function: $e');
      rethrow;
    }
  }

  /// 将JavaScript Promise转换为Dart Future
  Future<dynamic> _promiseToFuture(dynamic promise) async {
    try {
      // 创建一个Completer来处理Promise的结果
      final completer = js.context.callMethod('eval', ['''
        new Promise((resolve, reject) => {
          arguments[0].then(resolve).catch(reject);
        })
      ''']);
      
      // 简化处理：直接返回promise结果
      // 注意：这是一个简化的实现，实际项目中可能需要更复杂的Promise处理
      return promise;
    } catch (e) {
      debugPrint('Error converting Promise to Future: $e');
      throw e;
    }
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
      // 检查全局 farcasterSDK 对象
      final farcasterSDK = js.context['farcasterSDK'];
      return farcasterSDK != null;
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
      final isIframe = js.context['window'] != js.context['parent'];
      final hasSDK = js.context['farcasterSDK'] != null;
      
      return {
        'platform': 'web',
        'isMiniApp': isMiniAppEnvironment,
        'sdkAvailable': isSdkAvailable,
        'userAgent': userAgent ?? 'unknown',
        'currentUrl': currentUrl ?? 'unknown',
        'isIframe': isIframe,
        'hasSDK': hasSDK,
        'isWarpcast': userAgent?.contains('Warpcast') == true,
        'isFarcasterClient': _isFarcasterClient(userAgent),
        'detectionMethods': {
          'urlMiniApp': currentUrl?.contains('miniApp=true') == true,
          'urlMini': currentUrl?.contains('/mini') == true,
          'iframe': isIframe,
          'warpcastUA': userAgent?.contains('Warpcast') == true,
          'farcasterUA': userAgent?.contains('Farcaster') == true,
          'supercastUA': userAgent?.contains('Supercast') == true,
          'hasSDK': hasSDK,
        }
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