import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// HTTP客户端工具类
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;

  /// 初始化HTTP客户端
  void initialize() {
    _dio = Dio(BaseOptions(
      connectTimeout: AppConfig.requestTimeoutMs,
      receiveTimeout: AppConfig.requestTimeoutMs,
      sendTimeout: AppConfig.requestTimeoutMs,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 添加拦截器
    if (AppConfig.isDevelopment) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ));
    }

    // 添加错误处理拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioError error, ErrorInterceptorHandler handler) {
        _handleError(error);
        handler.next(error);
      },
    ));
  }

  /// GET请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
  }) async {
    try {
      final finalOptions = _mergeOptions(options, baseUrl);
      final response = await _dio.get<T>(
        baseUrl != null ? '$baseUrl$path' : path,
        queryParameters: queryParameters,
        options: finalOptions,
      );
      return response;
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
  }) async {
    try {
      final finalOptions = _mergeOptions(options, baseUrl);
      final response = await _dio.post<T>(
        baseUrl != null ? '$baseUrl$path' : path,
        data: data,
        queryParameters: queryParameters,
        options: finalOptions,
      );
      return response;
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
  }) async {
    try {
      final finalOptions = _mergeOptions(options, baseUrl);
      final response = await _dio.put<T>(
        baseUrl != null ? '$baseUrl$path' : path,
        data: data,
        queryParameters: queryParameters,
        options: finalOptions,
      );
      return response;
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
  }) async {
    try {
      final finalOptions = _mergeOptions(options, baseUrl);
      final response = await _dio.delete<T>(
        baseUrl != null ? '$baseUrl$path' : path,
        data: data,
        queryParameters: queryParameters,
        options: finalOptions,
      );
      return response;
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 合并请求选项，处理Neynar API身份验证
  Options _mergeOptions(Options? options, String? baseUrl) {
    final mergedHeaders = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 如果是Neynar API请求，添加API密钥
    if (baseUrl != null && baseUrl.contains('neynar.com')) {
      mergedHeaders['api_key'] = AppConfig.neynarApiKey;
    }

    // 合并用户提供的headers
    if (options?.headers != null) {
      mergedHeaders.addAll(options!.headers!);
    }

    return Options(
      headers: mergedHeaders,
      method: options?.method,
      receiveTimeout: options?.receiveTimeout,
      sendTimeout: options?.sendTimeout,
      responseType: options?.responseType,
      contentType: options?.contentType,
      validateStatus: options?.validateStatus,
      receiveDataWhenStatusError: options?.receiveDataWhenStatusError,
      followRedirects: options?.followRedirects,
      maxRedirects: options?.maxRedirects,
      requestEncoder: options?.requestEncoder,
      responseDecoder: options?.responseDecoder,
      listFormat: options?.listFormat,
    );
  }

  /// 处理Dio错误
  Exception _handleDioError(dynamic error) {
    if (error is DioError) {
      switch (error.type) {
        case DioErrorType.connectTimeout:
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          return ApiException('网络超时，请检查网络连接');
        case DioErrorType.response:
          return ApiException('服务器错误: ${error.response?.statusCode}');
        case DioErrorType.cancel:
          return ApiException('请求已取消');
        case DioErrorType.other:
          return ApiException('网络连接失败');
        default:
          return ApiException('请求失败');
      }
    }
    return ApiException('请求失败: $error');
  }

  /// 通用错误处理
  void _handleError(DioError error) {
    debugPrint('API Error: ${error.message}');
    if (error.response != null) {
      debugPrint('Status Code: ${error.response?.statusCode}');
      debugPrint('Response Data: ${error.response?.data}');
    }
  }
}

/// API异常类
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}