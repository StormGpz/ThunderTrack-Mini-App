// ignore_for_file: deprecated_member_use
import 'dart:js' as js;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
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

  /// 使用 Quick Auth 获取认证token和FID（简化版）
  Future<Map<String, dynamic>?> quickAuthLogin() async {
    if (!kIsWeb) {
      debugPrint('❌ 不在Web环境中');
      return null;
    }
    
    try {
      debugPrint('🔍 开始Quick Auth登录...');
      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK == null) {
        debugPrint('❌ Farcaster SDK not found');
        return null;
      }
      
      final quickAuth = farcasterSDK['quickAuth'];
      if (quickAuth == null) {
        debugPrint('❌ Quick Auth not available');
        return null;
      }
      
      final getTokenMethod = quickAuth['getToken'];
      if (getTokenMethod == null) {
        debugPrint('❌ getToken method not found');
        return null;
      }
      
      debugPrint('🚀 调用 sdk.quickAuth.getToken()...');
      final tokenResult = await _callAsyncFunction(getTokenMethod, []);
      
      if (tokenResult != null && tokenResult['token'] != null) {
        final token = tokenResult['token'] as String;
        debugPrint('✅ Quick Auth token获取成功');
        
        // 解析JWT获取FID
        final userInfo = _parseJwtToken(token);
        if (userInfo != null) {
          final result = {
            'token': token,
            'fid': userInfo['fid'],
            'authMethod': 'quickAuth',
            'tokenExpiry': userInfo['expiry'],
          };
          
          debugPrint('🎉 Quick Auth成功，FID: ${userInfo['fid']}');
          return result;
        }
      }
      
      debugPrint('❌ Quick Auth失败');
      return null;
      
    } catch (e) {
      debugPrint('❌ Quick Auth出错: $e');
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

  /// 从 SDK context 获取用户详细信息（优化版）
  Future<Map<String, dynamic>?> getContextUserInfo() async {
    try {
      debugPrint('🔍 开始获取SDK Context用户信息...');

      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK == null) {
        debugPrint('❌ Farcaster SDK不存在');
        return null;
      }

      debugPrint('✅ Farcaster SDK存在');

      // 额外检查SDK钱包相关的API
      debugPrint('🔍 检查SDK钱包相关API...');
      final wallet = farcasterSDK['wallet'];
      if (wallet != null) {
        debugPrint('✅ 找到 SDK wallet API');

        // 尝试获取钱包地址
        final address = wallet['address'];
        final ethProvider = wallet['ethProvider'];
        final accounts = wallet['accounts'];

        debugPrint('   wallet.address: $address');
        debugPrint('   wallet.ethProvider: ${ethProvider != null}');
        debugPrint('   wallet.accounts: $accounts');
      } else {
        debugPrint('❌ SDK中没有wallet API');
      }

      // 检查是否有ethereum相关的API
      final ethereum = farcasterSDK['ethereum'];
      if (ethereum != null) {
        debugPrint('✅ 找到 SDK ethereum API');

        final selectedAddress = ethereum['selectedAddress'];
        final accounts = ethereum['accounts'];

        debugPrint('   ethereum.selectedAddress: $selectedAddress');
        debugPrint('   ethereum.accounts: $accounts');
      } else {
        debugPrint('❌ SDK中没有ethereum API');
      }

      // 检查 context
      final context = farcasterSDK['context'];
      if (context == null) {
        debugPrint('❌ SDK.context 不存在');
        return null;
      }

      debugPrint('✅ SDK.context 存在');

      // 检查 user
      final user = context['user'];
      if (user == null) {
        debugPrint('❌ SDK.context.user 为 null');
        return null;
      }

      debugPrint('✅ SDK.context.user 存在');
      debugPrint('🔍 User对象类型: ${user.runtimeType}');
      debugPrint('🔍 User对象字符串: ${user.toString()}');

      // 使用优化的转换方法
      final userMap = _extractUserDataFromContext(user);
      debugPrint('📋 Context用户信息提取结果: ${userMap.keys.join(', ')}');
      debugPrint('🔍 Context详细信息: $userMap');

      // 如果从SDK wallet中获取到地址，添加到结果中
      if (wallet != null) {
        final walletAddress = wallet['address'];
        if (walletAddress != null) {
          userMap['sdkWalletAddress'] = walletAddress.toString();
          debugPrint('🔑 从SDK wallet添加地址: $walletAddress');
        }
      }

      if (ethereum != null) {
        final ethAddress = ethereum['selectedAddress'];
        if (ethAddress != null) {
          userMap['sdkEthereumAddress'] = ethAddress.toString();
          debugPrint('🔑 从SDK ethereum添加地址: $ethAddress');
        }
      }

      return userMap;

    } catch (e) {
      debugPrint('⚠️ 获取context用户信息失败: $e');
      return null;
    }
  }

  /// 专门从 SDK Context 提取用户数据（处理压缩混淆）
  Map<String, dynamic> _extractUserDataFromContext(dynamic userObject) {
    debugPrint('🔧 开始提取SDK Context用户数据...');
    
    // 方法1: 尝试JSON序列化
    try {
      debugPrint('🔄 尝试JSON序列化...');
      final jsonString = js.context['JSON'].callMethod('stringify', [userObject]);
      if (jsonString != null && jsonString.toString() != 'null') {
        debugPrint('✅ JSON序列化成功');
        final result = jsonDecode(jsonString as String) as Map<String, dynamic>;
        debugPrint('✅ JSON解析完成，字段: ${result.keys.join(', ')}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ JSON序列化失败: $e');
    }
    
    // 方法2: 使用Object.keys获取所有属性
    try {
      debugPrint('🔄 尝试Object.keys方法...');
      final keys = js.context['Object'].callMethod('keys', [userObject]);
      if (keys != null) {
        final keyList = List<String>.from(keys);
        debugPrint('🔍 发现属性: ${keyList.join(', ')}');
        
        final result = <String, dynamic>{};
        for (final key in keyList) {
          try {
            final value = userObject[key];
            if (value != null) {
              // 转换JavaScript值为Dart值
              result[key] = _convertJsValueToDart(value);
              debugPrint('✅ 提取属性 $key: ${result[key]}');
            }
          } catch (e) {
            debugPrint('❌ 提取属性 $key 失败: $e');
          }
        }
        
        if (result.isNotEmpty) {
          debugPrint('✅ Object.keys方法成功，共 ${result.length} 个字段');
          return result;
        }
      }
    } catch (e) {
      debugPrint('❌ Object.keys方法失败: $e');
    }
    
    // 方法3: 直接访问已知的Farcaster用户字段
    debugPrint('🔄 尝试直接字段访问...');
    final result = <String, dynamic>{};
    final commonFields = [
      'fid', 'username', 'displayName', 'pfpUrl', 'bio',
      'powerBadge', 'verified', 'custodyAddress', 'connectedAddress',
      'authAddresses', 'verifiedAddresses', 'verifications'
    ];
    
    for (final field in commonFields) {
      try {
        final value = userObject[field];
        if (value != null) {
          result[field] = _convertJsValueToDart(value);
          debugPrint('✅ 直接访问 $field: ${result[field]}');
        }
      } catch (e) {
        debugPrint('❌ 直接访问 $field 失败: $e');
      }
    }
    
    debugPrint('🎯 最终提取结果: $result');
    return result;
  }

  /// 转换JavaScript值为Dart值
  dynamic _convertJsValueToDart(dynamic jsValue) {
    if (jsValue == null) return null;
    
    try {
      // 基本类型直接返回
      if (jsValue is String || jsValue is num || jsValue is bool) {
        return jsValue;
      }
      
      // 对象类型尝试JSON转换
      final jsonString = js.context['JSON'].callMethod('stringify', [jsValue]);
      if (jsonString != null && jsonString.toString() != 'null') {
        return jsonDecode(jsonString as String);
      }
    } catch (e) {
      debugPrint('⚠️ JS值转换失败: $e');
    }
    
    // 兜底返回字符串表示
    return jsValue.toString();
  }

  /// 尝试其他可能的用户信息来源
  Future<Map<String, dynamic>?> _tryAlternativeUserSources(dynamic farcasterSDK) async {
    debugPrint('🔄 尝试其他用户信息来源...');
    
    try {
      // 1. 检查是否有 getCurrentUser 方法
      if (farcasterSDK['getCurrentUser'] != null) {
        debugPrint('🔍 尝试 sdk.getCurrentUser()...');
        final currentUser = await _callAsyncFunction(farcasterSDK['getCurrentUser'], []);
        if (currentUser != null) {
          debugPrint('✅ getCurrentUser() 成功');
          return _jsObjectToMap(currentUser);
        }
      }
      
      // 2. 检查是否有 user 直接属性
      if (farcasterSDK['user'] != null) {
        debugPrint('🔍 尝试 sdk.user...');
        final user = farcasterSDK['user'];
        return _jsObjectToMap(user);
      }
      
      // 3. 检查 context 的其他属性
      final context = farcasterSDK['context'];
      if (context != null) {
        final contextKeys = _getJsObjectKeys(context);
        debugPrint('🔍 检查context的其他属性: ${contextKeys.join(', ')}');
        
        for (final key in contextKeys) {
          if (key != 'user' && key.toLowerCase().contains('user')) {
            debugPrint('🔍 尝试 context.$key...');
            try {
              final userData = context[key];
              if (userData != null) {
                final userMap = _jsObjectToMap(userData);
                if (userMap.isNotEmpty) {
                  debugPrint('✅ 从 context.$key 获取到用户数据');
                  return userMap;
                }
              }
            } catch (e) {
              debugPrint('❌ context.$key 访问失败: $e');
            }
          }
        }
      }
      
      debugPrint('❌ 所有替代方案都失败了');
      return null;
      
    } catch (e) {
      debugPrint('❌ 尝试替代方案时出错: $e');
      return null;
    }
  }

  /// 通过FID获取用户详细信息（备用方案）
  Future<Map<String, dynamic>?> getUserInfoByFid(String fid) async {
    try {
      debugPrint('🔍 尝试通过FID获取用户信息: $fid');
      
      // 方案1: 尝试从Context获取
      final contextUser = await getContextUserInfo();
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

  /// 获取以太坊钱包提供者 (官方方式)
  dynamic getEthereumProvider() {
    if (!kIsWeb) return null;

    try {
      // 方案1: 通过 SDK 获取钱包提供者 (官方推荐)
      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK != null) {
        // 检查 sdk.wallet.ethProvider (官方文档推荐的方式)
        final wallet = farcasterSDK['wallet'];
        if (wallet != null) {
          final ethProvider = wallet['ethProvider'];
          if (ethProvider != null) {
            debugPrint('✅ 找到 Farcaster SDK wallet.ethProvider (官方方式)');
            return ethProvider;
          }
        }

        // 备用：检查是否有其他钱包相关API
        final ethereum = farcasterSDK['ethereum'];
        if (ethereum != null) {
          debugPrint('✅ 找到 Farcaster SDK ethereum API');
          return ethereum;
        }
      }

      // 方案2: 检查是否有 wagmi connector 注入的提供者
      final ethereum = js.context['ethereum'];
      if (ethereum != null) {
        // 检查是否是 Farcaster 注入的 (farcaster miniapp wagmi connector)
        final isFarcaster = ethereum['isFarcaster'] == true;
        final isConnected = ethereum['isConnected'] == true;
        debugPrint('${isFarcaster ? "✅" : "⚠️"} 找到以太坊提供者');
        debugPrint('   isFarcaster: $isFarcaster');
        debugPrint('   isConnected: $isConnected');
        return ethereum;
      }

      // 方案3: 检查全局以太坊提供者函数
      final getProviderFunction = js.context['getEthereumProvider'];
      if (getProviderFunction != null) {
        debugPrint('✅ 找到全局 getEthereumProvider 函数');
        return getProviderFunction.apply([]);
      }

      debugPrint('❌ 未找到任何以太坊提供者');
      debugPrint('🔍 可用的全局对象键: ${_getGlobalKeys()}');
    } catch (e) {
      debugPrint('Error getting Ethereum provider: $e');
    }

    return null;
  }

  /// 调试内置钱包地址 - 专门用于查找内置钱包地址
  Future<Map<String, dynamic>?> debugBuiltinWalletAddress() async {
    if (!kIsWeb) return null;

    try {
      debugPrint('🔍 开始全面调试所有可能的钱包地址来源...');

      final result = <String, dynamic>{};
      final farcasterSDK = js.context['farcasterSDK'];
      final allAddresses = <String>[];

      if (farcasterSDK != null) {
        // 1. 检查 SDK wallet API
        final wallet = farcasterSDK['wallet'];
        if (wallet != null) {
          debugPrint('🔍 检查 SDK wallet...');

          // 获取所有wallet相关属性
          final walletKeys = _getJsObjectKeys(wallet);
          debugPrint('   wallet可用属性: ${walletKeys.join(', ')}');

          for (final key in walletKeys) {
            try {
              final value = wallet[key];
              if (value != null) {
                final valueStr = value.toString();
                result['sdk_wallet_$key'] = valueStr;
                debugPrint('   wallet.$key: $valueStr');

                // 如果看起来像以太坊地址，添加到地址列表
                if (_isEthereumAddress(valueStr)) {
                  allAddresses.add(valueStr);
                  debugPrint('🔑 发现地址: $valueStr (来源: wallet.$key)');
                }
              }
            } catch (e) {
              debugPrint('❌ 无法获取 wallet.$key: $e');
            }
          }
        }

        // 2. 检查 SDK ethereum API
        final ethereum = farcasterSDK['ethereum'];
        if (ethereum != null) {
          debugPrint('🔍 检查 SDK ethereum...');

          final ethereumKeys = _getJsObjectKeys(ethereum);
          debugPrint('   ethereum可用属性: ${ethereumKeys.join(', ')}');

          for (final key in ethereumKeys) {
            try {
              final value = ethereum[key];
              if (value != null) {
                final valueStr = value.toString();
                result['sdk_ethereum_$key'] = valueStr;
                debugPrint('   ethereum.$key: $valueStr');

                // 如果看起来像以太坊地址，添加到地址列表
                if (_isEthereumAddress(valueStr)) {
                  allAddresses.add(valueStr);
                  debugPrint('🔑 发现地址: $valueStr (来源: ethereum.$key)');
                }
              }
            } catch (e) {
              debugPrint('❌ 无法获取 ethereum.$key: $e');
            }
          }
        }

        // 3. 全面检查 context 和 user 信息
        final context = farcasterSDK['context'];
        if (context != null) {
          debugPrint('🔍 检查 SDK context...');

          final contextKeys = _getJsObjectKeys(context);
          debugPrint('   context可用属性: ${contextKeys.join(', ')}');

          final user = context['user'];
          if (user != null) {
            debugPrint('🔍 深度检查 context.user...');

            // 获取user对象的所有属性
            final userKeys = _getJsObjectKeys(user);
            debugPrint('   user可用属性: ${userKeys.join(', ')}');

            for (final key in userKeys) {
              try {
                final value = user[key];
                if (value != null) {
                  final valueStr = value.toString();
                  result['context_user_$key'] = valueStr;
                  debugPrint('   user.$key: $valueStr');

                  // 检查是否是地址或包含地址的字段
                  if (_isEthereumAddress(valueStr)) {
                    allAddresses.add(valueStr);
                    debugPrint('🔑 发现地址: $valueStr (来源: user.$key)');
                  } else if (key.toLowerCase().contains('address') ||
                            key.toLowerCase().contains('wallet') ||
                            key.toLowerCase().contains('custody')) {
                    debugPrint('🔍 地址相关字段 user.$key: $valueStr');

                    // 如果是数组或对象，尝试解析
                    if (valueStr.startsWith('[') || valueStr.startsWith('{')) {
                      try {
                        final parsed = jsonDecode(valueStr);
                        debugPrint('   解析后: $parsed');
                        _extractAddressesFromData(parsed, allAddresses, 'user.$key');
                      } catch (e) {
                        debugPrint('   无法解析JSON: $e');
                      }
                    }
                  }
                }
              } catch (e) {
                debugPrint('❌ 无法获取 user.$key: $e');
              }
            }
          }

          // 检查context的其他属性
          for (final key in contextKeys) {
            if (key != 'user') {
              try {
                final value = context[key];
                if (value != null) {
                  final valueStr = value.toString();
                  result['context_$key'] = valueStr;
                  debugPrint('   context.$key: $valueStr');

                  if (_isEthereumAddress(valueStr)) {
                    allAddresses.add(valueStr);
                    debugPrint('🔑 发现地址: $valueStr (来源: context.$key)');
                  }
                }
              } catch (e) {
                debugPrint('❌ 无法获取 context.$key: $e');
              }
            }
          }
        }

        // 4. 检查SDK的其他属性
        final sdkKeys = _getJsObjectKeys(farcasterSDK);
        debugPrint('🔍 检查 SDK 其他属性: ${sdkKeys.join(', ')}');

        for (final key in sdkKeys) {
          if (!['wallet', 'ethereum', 'context'].contains(key)) {
            try {
              final value = farcasterSDK[key];
              if (value != null) {
                final valueStr = value.toString();
                result['sdk_$key'] = valueStr;
                debugPrint('   sdk.$key: $valueStr');

                if (_isEthereumAddress(valueStr)) {
                  allAddresses.add(valueStr);
                  debugPrint('🔑 发现地址: $valueStr (来源: sdk.$key)');
                }
              }
            } catch (e) {
              debugPrint('❌ 无法获取 sdk.$key: $e');
            }
          }
        }

        // 5. 尝试provider方法获取账户
        final provider = getEthereumProvider();
        if (provider != null) {
          debugPrint('🔍 通过 provider 获取账户...');

          try {
            final request = provider['request'];
            if (request != null) {
              // 尝试获取当前账户
              final accountsPromise = _callAsyncFunction(request, [js.JsObject.jsify({
                'method': 'eth_accounts',
                'params': [],
              })]);

              if (accountsPromise != null) {
                final accounts = await accountsPromise;
                if (accounts != null) {
                  result['provider_accounts'] = accounts.toString();
                  debugPrint('📋 Provider accounts: $accounts');

                  // 提取账户地址
                  if (accounts is List) {
                    for (final account in accounts) {
                      if (_isEthereumAddress(account.toString())) {
                        allAddresses.add(account.toString());
                        debugPrint('🔑 发现地址: ${account.toString()} (来源: provider.accounts)');
                      }
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('❌ 通过 provider 获取账户失败: $e');
            result['provider_error'] = e.toString();
          }
        }

        // 6. 检查全局window对象中的地址
        debugPrint('🔍 检查全局对象中的地址...');
        final globalAddresses = _searchGlobalAddresses();
        globalAddresses.forEach((source, address) {
          result['global_$source'] = address;
          allAddresses.add(address);
          debugPrint('🔑 发现地址: $address (来源: global.$source)');
        });
      }

      // 去重并分析地址
      final uniqueAddresses = allAddresses.toSet().toList();
      result['all_unique_addresses'] = uniqueAddresses;
      result['address_count'] = uniqueAddresses.length;

      debugPrint('🎯 所有发现的地址 (${uniqueAddresses.length}个):');
      for (int i = 0; i < uniqueAddresses.length; i++) {
        final addr = uniqueAddresses[i];
        debugPrint('   ${i + 1}. $addr ${addr.startsWith('0x7122') ? '⭐ (匹配目标!)' : ''}');
      }

      debugPrint('🎯 完整的调试结果: $result');
      return result.isNotEmpty ? result : null;

    } catch (e) {
      debugPrint('❌ 调试内置钱包地址失败: $e');
      return null;
    }
  }

  /// 检查字符串是否是以太坊地址
  bool _isEthereumAddress(String value) {
    // 以太坊地址：0x开头，42字符长度，包含十六进制字符
    return value.length == 42 &&
           value.startsWith('0x') &&
           RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(value);
  }

  /// 从数据结构中递归提取地址
  void _extractAddressesFromData(dynamic data, List<String> addresses, String source) {
    if (data == null) return;

    if (data is String && _isEthereumAddress(data)) {
      addresses.add(data);
      debugPrint('🔑 从$source提取地址: $data');
    } else if (data is List) {
      for (final item in data) {
        _extractAddressesFromData(item, addresses, source);
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        _extractAddressesFromData(value, addresses, '$source.$key');
      });
    }
  }

  /// 搜索全局对象中的地址
  Map<String, String> _searchGlobalAddresses() {
    final result = <String, String>{};

    try {
      // 检查window对象的一些常见属性
      final searchProperties = [
        'ethereum', 'web3', 'farcasterAddress', 'userAddress',
        'walletAddress', 'connectedAddress', 'currentAddress'
      ];

      for (final prop in searchProperties) {
        try {
          final value = js.context[prop];
          if (value != null) {
            final valueStr = value.toString();
            if (_isEthereumAddress(valueStr)) {
              result[prop] = valueStr;
            }
          }
        } catch (e) {
          // 忽略错误，继续检查其他属性
        }
      }

      // 检查localStorage中的地址
      try {
        final localStorage = js.context['localStorage'];
        if (localStorage != null) {
          final storageKeys = ['userAddress', 'walletAddress', 'farcasterAddress', 'connectedAddress'];
          for (final key in storageKeys) {
            try {
              final value = localStorage.callMethod('getItem', [key]);
              if (value != null && _isEthereumAddress(value.toString())) {
                result['localStorage_$key'] = value.toString();
              }
            } catch (e) {
              // 忽略错误
            }
          }
        }
      } catch (e) {
        debugPrint('检查localStorage失败: $e');
      }

    } catch (e) {
      debugPrint('搜索全局地址失败: $e');
    }

    return result;
  }

  /// 获取全局对象的键名用于调试
  List<String> _getGlobalKeys() {
    try {
      final keys = js.context['Object'].callMethod('keys', [js.context]);
      return List<String>.from(keys).where((key) =>
        key.toLowerCase().contains('wallet') ||
        key.toLowerCase().contains('ethereum') ||
        key.toLowerCase().contains('farcaster')
      ).toList();
    } catch (e) {
      return [];
    }
  }

  /// 检查是否支持内置钱包交易
  bool get hasBuiltinWallet {
    if (!kIsWeb) return false;

    try {
      final farcasterSDK = js.context['farcasterSDK'];
      if (farcasterSDK != null) {
        final wallet = farcasterSDK['wallet'];
        final ethereum = farcasterSDK['ethereum'];
        return wallet != null || ethereum != null;
      }

      final ethereum = js.context['ethereum'];
      return ethereum != null && ethereum['isFarcaster'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 通过内置钱包签名消息
  Future<String?> signMessageWithBuiltinWallet(String message, String address) async {
    if (!kIsWeb) return null;

    try {
      final provider = getEthereumProvider();
      if (provider == null) {
        debugPrint('❌ 未找到内置钱包提供者');
        return null;
      }

      debugPrint('🔏 使用内置钱包签名消息...');

      // 尝试个人签名
      final signature = await _callAsyncFunction(
        provider['request'],
        [js.JsObject.jsify({
          'method': 'personal_sign',
          'params': [message, address]
        })]
      );

      if (signature != null) {
        debugPrint('✅ 内置钱包签名成功');
        return signature.toString();
      }

      return null;
    } catch (e) {
      debugPrint('❌ 内置钱包签名失败: $e');
      return null;
    }
  }

  /// 通过内置钱包进行 EIP-712 签名
  Future<String?> signTypedDataWithBuiltinWallet(Map<String, dynamic> typedData, String address) async {
    if (!kIsWeb) return null;

    try {
      final provider = getEthereumProvider();
      if (provider == null) {
        debugPrint('❌ 未找到内置钱包提供者');
        return null;
      }

      debugPrint('🔏 使用内置钱包进行EIP-712签名...');

      final signature = await _callAsyncFunction(
        provider['request'],
        [js.JsObject.jsify({
          'method': 'eth_signTypedData_v4',
          'params': [address, js.JsObject.jsify(typedData)]
        })]
      );

      if (signature != null) {
        debugPrint('✅ 内置钱包EIP-712签名成功');
        return signature.toString();
      }

      return null;
    } catch (e) {
      debugPrint('❌ 内置钱包EIP-712签名失败: $e');
      return null;
    }
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
    debugPrint('🔍 JS对象字符串表示: ${jsObject.toString()}');
    
    // 检查是否是压缩混淆的对象
    if (jsObject.toString().contains('instance of minified:')) {
      debugPrint('⚠️ 检测到压缩混淆的JS对象，使用特殊处理方法...');
      return _handleMinifiedJsObject(jsObject);
    }
    
    try {
      // 方法1: 尝试使用 JSON 序列化/反序列化
      debugPrint('🔄 尝试JSON序列化方法...');
      final jsonString = js.context['JSON'].callMethod('stringify', [jsObject]);
      debugPrint('✅ JSON序列化成功: ${jsonString.toString().substring(0, math.min(100, jsonString.toString().length))}...');
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

  /// 处理压缩混淆的JavaScript对象
  Map<String, dynamic> _handleMinifiedJsObject(dynamic jsObject) {
    debugPrint('🔧 处理压缩混淆的JS对象...');
    
    try {
      // 方法1: 强制使用JSON.stringify，即使对象被压缩
      debugPrint('🔄 强制JSON序列化压缩对象...');
      final jsonString = js.context['JSON'].callMethod('stringify', [jsObject]);
      if (jsonString != null && jsonString.toString() != 'null' && jsonString.toString() != '{}') {
        debugPrint('✅ 压缩对象JSON序列化成功: ${jsonString.toString()}');
        final result = jsonDecode(jsonString as String) as Map<String, dynamic>;
        debugPrint('✅ 压缩对象转换完成，包含字段: ${result.keys.join(', ')}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ 压缩对象JSON序列化失败: $e');
    }
    
    try {
      // 方法2: 使用Object.keys获取所有属性名
      debugPrint('🔄 使用Object.keys获取压缩对象属性...');
      final keys = js.context['Object'].callMethod('keys', [jsObject]);
      final result = <String, dynamic>{};
      
      if (keys != null) {
        final keyList = List<String>.from(keys);
        debugPrint('🔍 发现属性: ${keyList.join(', ')}');
        
        for (final key in keyList) {
          try {
            final value = jsObject[key];
            if (value != null) {
              result[key] = _convertJsValue(value);
              debugPrint('✅ 压缩对象属性 $key: ${result[key]}');
            }
          } catch (e) {
            debugPrint('❌ 获取压缩对象属性 $key 失败: $e');
          }
        }
        
        debugPrint('✅ 压缩对象属性提取完成，共 ${result.length} 个字段');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Object.keys方法失败: $e');
    }
    
    // 方法3: 尝试已知字段名的直接访问
    debugPrint('🔄 尝试直接访问已知字段...');
    final result = <String, dynamic>{};
    final knownFields = ['fid', 'username', 'displayName', 'pfpUrl', 'bio', 'location', 'verified'];
    
    for (final field in knownFields) {
      try {
        final value = jsObject[field];
        if (value != null) {
          result[field] = _convertJsValue(value);
          debugPrint('✅ 直接访问字段 $field: ${result[field]}');
        }
      } catch (e) {
        debugPrint('❌ 直接访问字段 $field 失败: $e');
      }
    }
    
    debugPrint('🎯 压缩对象最终结果: $result');
    return result;
  }

  /// 转换JavaScript值为Dart值
  dynamic _convertJsValue(dynamic jsValue) {
    if (jsValue == null) return null;
    
    try {
      // 如果是基本类型，直接返回
      if (jsValue is String || jsValue is num || jsValue is bool) {
        return jsValue;
      }
      
      // 如果是对象，尝试JSON序列化
      final jsonString = js.context['JSON'].callMethod('stringify', [jsValue]);
      if (jsonString != null && jsonString.toString() != 'null') {
        return jsonDecode(jsonString as String);
      }
    } catch (e) {
      debugPrint('⚠️ 转换JS值失败: $e');
    }
    
    return jsValue.toString();
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