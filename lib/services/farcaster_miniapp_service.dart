import 'dart:js' as js;
import 'dart:convert';
import 'dart:async';
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
        userAgent?.toLowerCase().contains('warpcast') == true,
        userAgent?.toLowerCase().contains('farcaster') == true,  
        userAgent?.toLowerCase().contains('supercast') == true,
        
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
        debugPrint('❌ Farcaster SDK not found in global context');
        return null;
      }
      
      debugPrint('✅ Found Farcaster SDK in global context');
      
      // 获取 SDK context
      final sdkContext = farcasterSDK['context'];
      if (sdkContext == null) {
        debugPrint('❌ SDK context not found');
        return null;
      }
      
      debugPrint('✅ Found SDK context');
      
      // 获取用户信息
      final user = sdkContext['user'];
      if (user == null) {
        debugPrint('❌ User not found in SDK context');
        return null;
      }
      
      debugPrint('✅ Found user in SDK context');
      
      // 转换为 Dart Map
      final userMap = _jsObjectToMap(user);
      debugPrint('🎯 Farcaster user data: $userMap');
      return userMap;
      
    } catch (e) {
      debugPrint('❌ Error getting Farcaster user: $e');
      return null;
    }
  }

  /// 使用 Quick Auth 获取认证token和用户信息
  Future<Map<String, dynamic>?> quickAuthLogin() async {
    if (!kIsWeb) {
      debugPrint('❌ 不在Web环境中');
      return null;
    }
    
    try {
      debugPrint('🔍 检查Farcaster SDK...');
      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK == null) {
        debugPrint('❌ Farcaster SDK not found in js.context');
        debugPrint('🔍 Context type: ${js.context.runtimeType}');
        return null;
      }
      
      debugPrint('✅ Farcaster SDK找到，检查Quick Auth...');
      final quickAuth = farcasterSDK['quickAuth'];
      if (quickAuth == null) {
        debugPrint('❌ Quick Auth not available in SDK');
        debugPrint('🔍 Available SDK keys: ${_getJsObjectKeys(farcasterSDK)}');
        return null;
      }
      
      debugPrint('✅ Quick Auth可用，检查getToken方法...');
      final getTokenMethod = quickAuth['getToken'];
      if (getTokenMethod == null) {
        debugPrint('❌ getToken method not found');
        debugPrint('🔍 Available quickAuth keys: ${_getJsObjectKeys(quickAuth)}');
        return null;
      }
      
      debugPrint('🚀 开始调用sdk.quickAuth.getToken()...');
      
      // 获取认证token
      final tokenResult = await _callAsyncFunction(getTokenMethod, []);
      
      debugPrint('🔍 Token result: $tokenResult');
      debugPrint('🔍 Token result type: ${tokenResult.runtimeType}');
      
      if (tokenResult != null && tokenResult['token'] != null) {
        final token = tokenResult['token'] as String;
        debugPrint('✅ Quick Auth token获取成功: ${token.substring(0, 20)}...');
        
        // 解析JWT获取用户FID
        final userInfo = _parseJwtToken(token);
        if (userInfo != null) {
          debugPrint('✅ JWT解析成功，用户FID: ${userInfo['fid']}');
          
          // 同时尝试从context获取额外用户信息
          final contextUser = await _getContextUserInfo();
          debugPrint('🔍 Context用户信息: $contextUser');
          
          // 合并信息
          final result = {
            'token': token,
            'fid': userInfo['fid'],
            'authMethod': 'quickAuth',
            'tokenExpiry': userInfo['expiry'],
            ...?contextUser, // 如果有context用户信息，合并进来
          };
          
          debugPrint('🎉 Quick Auth 登录成功，最终结果: $result');
          return result;
        } else {
          debugPrint('❌ JWT解析失败');
        }
      } else {
        debugPrint('❌ Token result为空或无token字段');
        debugPrint('🔍 实际获得: $tokenResult');
      }
      
      debugPrint('❌ Quick Auth token获取失败');
      return null;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Quick Auth 登录出错: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// 获取JS对象的键名（用于调试）
  List<String> _getJsObjectKeys(dynamic jsObject) {
    try {
      if (jsObject == null) return [];
      final keys = js.context['Object'].callMethod('keys', [jsObject]);
      return List<String>.from(keys);
    } catch (e) {
      debugPrint('获取JS对象键名失败: $e');
      return [];
    }
  }

  /// 从 SDK context 获取用户详细信息（作为补充）
  Future<Map<String, dynamic>?> _getContextUserInfo() async {
    try {
      final farcasterSDK = js.context['farcasterSDK'];
      final user = farcasterSDK?['context']?['user'];
      
      if (user != null) {
        final userMap = _jsObjectToMap(user);
        debugPrint('📋 Context用户信息: ${userMap.keys}');
        debugPrint('🔍 Context详细信息: $userMap');
        return userMap;
      } else {
        debugPrint('⚠️ Context中没有用户信息');
      }
    } catch (e) {
      debugPrint('⚠️ 获取context用户信息失败: $e');
    }
    return null;
  }

  /// 通过FID获取用户详细信息（备用方案）
  Future<Map<String, dynamic>?> getUserInfoByFid(String fid) async {
    try {
      debugPrint('🔍 尝试通过FID获取用户信息: $fid');
      
      // 方案1: 尝试从Context获取
      final contextUser = await _getContextUserInfo();
      if (contextUser != null && contextUser.isNotEmpty) {
        debugPrint('✅ 从Context获取到用户信息');
        return contextUser;
      }
      
      // 方案2: 使用Farcaster公开API
      debugPrint('🌐 尝试从Farcaster API获取用户信息...');
      
      // 这里可以调用 https://api.neynar.com/v2/farcaster/user/bulk?fids=${fid}
      // 但需要API key，或者使用其他公开API
      
      debugPrint('💡 建议：实现Neynar API调用或其他用户信息源');
      
      return null;
    } catch (e) {
      debugPrint('❌ 获取用户详细信息失败: $e');
      return null;
    }
  }

  /// 使用 Quick Auth 获取认证token（保留原方法兼容性）
  Future<String?> getQuickAuthToken() async {
    final result = await quickAuthLogin();
    return result?['token'];
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
      debugPrint('🔄 开始处理JS Promise...');
      
      // 使用JS interop创建Promise处理
      final completer = Completer<dynamic>();
      
      // 创建成功回调
      final onSuccess = js.allowInterop((dynamic value) {
        debugPrint('✅ Promise resolve: $value');
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      });
      
      // 创建失败回调
      final onError = js.allowInterop((dynamic error) {
        debugPrint('❌ Promise reject: $error');
        if (!completer.isCompleted) {
          completer.completeError(Exception('Promise rejected: $error'));
        }
      });
      
      // 附加回调到Promise
      promise.callMethod('then', [onSuccess]).callMethod('catch', [onError]);
      
      // 设置超时
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          debugPrint('⏰ Promise超时');
          completer.completeError(TimeoutException('Promise timeout'));
        }
      });
      
      return await completer.future;
    } catch (e) {
      debugPrint('❌ Promise处理错误: $e');
      rethrow;
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
        'isWarpcast': userAgent?.toLowerCase().contains('warpcast') == true,
        'isFarcasterClient': _isFarcasterClient(userAgent),
        'detectionMethods': {
          'urlMiniApp': currentUrl?.contains('miniApp=true') == true,
          'urlMini': currentUrl?.contains('/mini') == true,
          'iframe': isIframe,
          'warpcastUA': userAgent?.toLowerCase().contains('warpcast') == true,
          'farcasterUA': userAgent?.toLowerCase().contains('farcaster') == true,
          'supercastUA': userAgent?.toLowerCase().contains('supercast') == true,
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
    if (jsObject == null) {
      debugPrint('🔍 JS对象为null');
      return {};
    }
    
    debugPrint('🔍 开始转换JS对象到Map...');
    debugPrint('🔍 JS对象类型: ${jsObject.runtimeType}');
    
    try {
      // 方法1: 尝试使用 JSON 序列化/反序列化
      debugPrint('🔄 尝试JSON序列化方法...');
      final jsonString = js.context['JSON'].callMethod('stringify', [jsObject]);
      debugPrint('✅ JSON序列化成功: ${jsonString.toString().substring(0, 100)}...');
      final result = jsonDecode(jsonString as String) as Map<String, dynamic>;
      debugPrint('✅ JSON转换完成，包含字段: ${result.keys.join(', ')}');
      return result;
    } catch (e) {
      debugPrint('❌ JSON序列化失败: $e');
      
      // 方法2: 手动提取已知字段
      debugPrint('🔄 尝试手动提取字段...');
      try {
        final result = <String, dynamic>{};
        
        // 获取所有可能的字段
        final fields = ['fid', 'username', 'displayName', 'pfpUrl', 'bio', 'location', 'verified', 'followers', 'following'];
        
        for (final field in fields) {
          try {
            final value = _getProperty(jsObject, field);
            if (value != null) {
              result[field] = value;
              debugPrint('✅ 获取字段 $field: ${value.toString().length > 50 ? value.toString().substring(0, 50) + "..." : value}');
            } else {
              debugPrint('⚪ 字段 $field: null');
            }
          } catch (e) {
            debugPrint('❌ 获取字段 $field 失败: $e');
          }
        }
        
        debugPrint('✅ 手动提取完成，共 ${result.length} 个字段');
        return result;
      } catch (e2) {
        debugPrint('❌ 手动提取也失败: $e2');
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
    
    final lowerUA = userAgent.toLowerCase();
    final farcasterClientIndicators = [
      'warpcast',
      'farcaster', 
      'supercast',
      'rainbow',
      'farquest',
    ];
    
    return farcasterClientIndicators.any(
      (indicator) => lowerUA.contains(indicator),
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

  /// 解析JWT Token获取用户信息
  Map<String, dynamic>? _parseJwtToken(String token) {
    try {
      // JWT格式: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('❌ JWT格式不正确');
        return null;
      }
      
      // 解码payload部分
      String payload = parts[1];
      
      // 添加padding使其长度为4的倍数
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      // Base64解码
      final bytes = base64Url.decode(payload);
      final decodedJson = utf8.decode(bytes);
      final Map<String, dynamic> claims = jsonDecode(decodedJson);
      
      debugPrint('🔍 JWT Claims: $claims');
      
      // 提取关键信息
      return {
        'fid': claims['sub'], // Subject通常是用户FID
        'expiry': claims['exp'], // 过期时间
        'issued': claims['iat'], // 签发时间
        'domain': claims['domain'], // 域名
        ...claims, // 包含所有原始claims
      };
    } catch (e) {
      debugPrint('❌ JWT解析失败: $e');
      return null;
    }
  }
}