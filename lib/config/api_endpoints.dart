/// API端点配置
class ApiEndpoints {
  // Hyperliquid API端点
  static const String hyperliquidInfo = '/info';
  static const String hyperliquidOrder = '/clearinghouse/order';
  static const String hyperliquidCancel = '/clearinghouse/cancel';
  static const String hyperliquidUserState = '/info/userState';
  static const String hyperliquidAllMids = '/info/allMids';
  
  // Neynar API端点 (Farcaster)
  static const String neynarAuth = '/v2/farcaster/auth';
  static const String neynarUser = '/v2/farcaster/user';
  static const String neynarCast = '/v2/farcaster/cast';
  static const String neynarFollows = '/v2/farcaster/following';
  static const String neynarNotifications = '/v2/farcaster/notifications';
  
  // IPFS/Pinata端点
  static const String pinataPin = '/pinning/pinJSONToIPFS';
  static const String pinataList = '/data/pinList';
  static const String pinataUnpin = '/pinning/unpin';
}