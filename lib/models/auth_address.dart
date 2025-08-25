/// 认证地址响应模型
class AuthAddressResponse {
  final String address;
  final AuthAddressStatus status;
  final String? authAddressApprovalUrl;
  final int? fid;

  AuthAddressResponse({
    required this.address,
    required this.status,
    this.authAddressApprovalUrl,
    this.fid,
  });

  factory AuthAddressResponse.fromJson(Map<String, dynamic> json) {
    return AuthAddressResponse(
      address: json['address'] as String,
      status: AuthAddressStatus.fromString(json['status'] as String),
      authAddressApprovalUrl: json['auth_address_approval_url'] as String?,
      fid: json['fid'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'status': status.value,
      if (authAddressApprovalUrl != null) 'auth_address_approval_url': authAddressApprovalUrl,
      if (fid != null) 'fid': fid,
    };
  }

  @override
  String toString() {
    return 'AuthAddressResponse(address: $address, status: ${status.displayName}, fid: $fid)';
  }
}

/// 认证地址状态枚举
enum AuthAddressStatus {
  pendingApproval('pending_approval', '待审批'),
  approved('approved', '已批准'),
  revoked('revoked', '已撤销');

  const AuthAddressStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static AuthAddressStatus fromString(String status) {
    return values.firstWhere(
      (e) => e.value == status,
      orElse: () => throw ArgumentError('Unknown status: $status'),
    );
  }

  bool get isActive => this == AuthAddressStatus.approved;
  bool get isPending => this == AuthAddressStatus.pendingApproval;
  bool get isRevoked => this == AuthAddressStatus.revoked;
}