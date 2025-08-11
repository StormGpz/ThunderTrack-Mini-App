import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// 用户数据模型
@JsonSerializable()
class User {
  /// Farcaster ID
  final String fid;
  
  /// 用户名
  final String username;
  
  /// 显示名称
  final String displayName;
  
  /// 用户头像URL
  final String? avatarUrl;
  
  /// 用户简介
  final String? bio;
  
  /// 钱包地址
  final String? walletAddress;
  
  /// 关注者列表
  final List<String> followers;
  
  /// 正在关注的用户列表
  final List<String> following;
  
  /// 验证状态
  final bool isVerified;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后活跃时间
  final DateTime? lastActiveAt;

  const User({
    required this.fid,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.walletAddress,
    this.followers = const [],
    this.following = const [],
    this.isVerified = false,
    required this.createdAt,
    this.lastActiveAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// 复制对象并更新部分字段
  User copyWith({
    String? fid,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? walletAddress,
    List<String>? followers,
    List<String>? following,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return User(
      fid: fid ?? this.fid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      walletAddress: walletAddress ?? this.walletAddress,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && fid == other.fid;

  @override
  int get hashCode => fid.hashCode;

  @override
  String toString() => 'User(fid: $fid, username: $username)';
}