/// 应用配置常量
class AppConfig {
  // 应用信息
  static const String appName = 'ThunderTrack';
  static const String version = '1.0.0';
  
  // API配置
  static const bool isDevelopment = true;
  
  // Hyperliquid API
  static const String hyperliquidBaseUrl = 'https://api.hyperliquid.xyz';
  static const String hyperliquidWsUrl = 'wss://api.hyperliquid.xyz/ws';
  
  // Neynar API (Farcaster)
  static const String neynarBaseUrl = 'https://api.neynar.com';
  static const String neynarApiKey = '2BF15C3E-13B0-4B28-9CA5-4F687C41B7C3';
  
  // IPFS配置
  static const String ipfsGateway = 'https://ipfs.io/ipfs/';
  static const String pinataApiUrl = 'https://api.pinata.cloud';
  static const String pinataApiKey = 'YOUR_PINATA_API_KEY';
  
  // 本地存储配置
  static const String userBoxName = 'user_data';
  static const String tradeBoxName = 'trade_data';
  static const String diaryBoxName = 'diary_data';
  
  // 其他配置
  static const int requestTimeoutMs = 30000;
  static const int wsReconnectDelayMs = 5000;
  static const int maxRetryAttempts = 3;
}