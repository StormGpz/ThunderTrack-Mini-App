/// 地址授权状态枚举
enum AddressAuthStatus {
  unselected('未选择'),
  selected('已选择'),
  authorizing('授权中'),
  authorized('已授权'),
  failed('授权失败'),
  expired('授权过期');

  const AddressAuthStatus(this.displayName);
  final String displayName;

  bool get canTrade => this == AddressAuthStatus.authorized;
  bool get needsAuth => this == AddressAuthStatus.selected || this == AddressAuthStatus.failed || this == AddressAuthStatus.expired;
}

/// 地址授权信息模型
class AddressAuthInfo {
  final String address;
  final AddressAuthStatus status;
  final String signature;
  final DateTime timestamp;
  final DateTime? expiresAt;

  AddressAuthInfo({
    required this.address,
    required this.status,
    required this.signature,
    required this.timestamp,
    this.expiresAt,
  });

  /// 是否已授权
  bool get isAuthorized => status == AddressAuthStatus.authorized && !isExpired;
  
  /// 是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 剩余有效时间（小时）
  int get remainingHours {
    if (expiresAt == null) return -1;
    final remaining = expiresAt!.difference(DateTime.now()).inHours;
    return remaining > 0 ? remaining : 0;
  }

  factory AddressAuthInfo.fromJson(Map<String, dynamic> json) {
    return AddressAuthInfo(
      address: json['address'] as String,
      status: AddressAuthStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AddressAuthStatus.unselected,
      ),
      signature: json['signature'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiresAt: json['expires_at'] != null 
        ? DateTime.parse(json['expires_at'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'status': status.name,
      'signature': signature,
      'timestamp': timestamp.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }

  AddressAuthInfo copyWith({
    String? address,
    AddressAuthStatus? status,
    String? signature,
    DateTime? timestamp,
    DateTime? expiresAt,
  }) {
    return AddressAuthInfo(
      address: address ?? this.address,
      status: status ?? this.status,
      signature: signature ?? this.signature,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  String toString() {
    return 'AddressAuthInfo(address: ${address.substring(0, 8)}..., status: ${status.displayName})';
  }
}

/// 地址选项模型
class AddressOption {
  final String address;
  final String type; // "Farcaster钱包" | "绑定钱包" | "外部钱包"
  final bool recommended;
  final bool isConnected;
  final String? label; // 用户自定义标签

  AddressOption({
    required this.address,
    required this.type,
    this.recommended = false,
    this.isConnected = false,
    this.label,
  });

  /// 显示名称
  String get displayName {
    if (label != null && label!.isNotEmpty) {
      return label!;
    }
    return '$type (${address.substring(0, 6)}...${address.substring(address.length - 4)})';
  }

  /// 地址简写
  String get shortAddress {
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  factory AddressOption.fromJson(Map<String, dynamic> json) {
    return AddressOption(
      address: json['address'] as String,
      type: json['type'] as String,
      recommended: json['recommended'] as bool? ?? false,
      isConnected: json['is_connected'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'type': type,
      'recommended': recommended,
      'is_connected': isConnected,
      if (label != null) 'label': label,
    };
  }

  @override
  String toString() {
    return 'AddressOption(${displayName})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressOption &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}