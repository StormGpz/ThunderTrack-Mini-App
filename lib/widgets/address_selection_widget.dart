import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/address_auth.dart';
import '../services/farcaster_miniapp_service.dart';
import '../providers/user_provider.dart';
import '../theme/eva_theme.dart';

/// 地址选择和授权组件
class AddressSelectionWidget extends StatefulWidget {
  final Function(AddressOption)? onAddressSelected;
  final Function(String)? onAddressAuthorized;
  final bool showAuthStatus;

  const AddressSelectionWidget({
    Key? key,
    this.onAddressSelected,
    this.onAddressAuthorized,
    this.showAuthStatus = true,
  }) : super(key: key);

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  // Address detection service removed - functionality not available
  final FarcasterMiniAppService _miniAppService = FarcasterMiniAppService();
  List<AddressOption> _availableAddresses = [];
  AddressOption? _selectedAddress;
  bool _isLoading = false;
  bool _isAuthorizing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableAddresses();
  }

  Future<void> _loadAvailableAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      
      if (user != null) {
        // 从用户信息中获取绑定的钱包地址
        final addresses = <AddressOption>[];
        
        // 调试：打印用户信息
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.addDebugLog('🔍 检查用户钱包地址...');
        userProvider.addDebugLog('📊 用户FID: ${user.fid}');
        userProvider.addDebugLog('📊 用户名: ${user.username}');
        userProvider.addDebugLog('📊 钱包地址: ${user.walletAddress ?? "null"}');
        
        // 检查用户是否有绑定的钱包地址
        if (user.walletAddress != null && user.walletAddress!.isNotEmpty) {
          addresses.add(AddressOption(
            address: user.walletAddress!,
            type: 'Farcaster绑定钱包',
            recommended: true,
            isConnected: true,
          ));
          userProvider.addDebugLog('✅ 找到绑定钱包地址: ${user.walletAddress}');
        } else {
          userProvider.addDebugLog('❌ 用户未绑定钱包地址');
          
          // 尝试从Mini App服务直接获取更多信息
          try {
            final contextInfo = await _miniAppService.getContextUserInfo();
            if (contextInfo != null) {
              userProvider.addDebugLog('📋 Context信息字段: ${contextInfo.keys.join(', ')}');
              
              // 检查多种可能的地址字段
              final addressFields = ['custodyAddress', 'connectedAddress', 'verifiedAddress', 'walletAddress', 'address'];
              for (final field in addressFields) {
                final addressValue = contextInfo[field];
                if (addressValue != null && addressValue.toString().isNotEmpty) {
                  addresses.add(AddressOption(
                    address: addressValue.toString(),
                    type: 'Farcaster $field',
                    recommended: true,
                    isConnected: true,
                  ));
                  userProvider.addDebugLog('✅ 从Context获取到${field}: $addressValue');
                  break; // 找到一个就够了
                }
              }
            }
          } catch (e) {
            userProvider.addDebugLog('❌ 获取Context信息失败: $e');
          }
        }
        
        setState(() {
          _availableAddresses = addresses;
          // 如果有地址，自动选择第一个
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses.first;
            if (widget.onAddressSelected != null) {
              widget.onAddressSelected!(addresses.first);
            }
          }
        });
        
        // 最终结果日志
        if (addresses.isEmpty) {
          userProvider.addDebugLog('💡 最终结果：用户未绑定任何钱包地址，显示空状态页面');
        } else {
          userProvider.addDebugLog('🎯 找到 ${addresses.length} 个可用钱包地址');
        }
      }
    } catch (e) {
      setState(() {
        _error = '加载地址失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authorizeAddress(AddressOption option) async {
    setState(() {
      _isAuthorizing = true;
      _error = null;
    });

    try {
      // TODO: 实现钱包签名授权
      // 暂时使用模拟签名
      debugPrint('📋 模拟地址授权: ${option.address}');

      setState(() {
        _isAuthorizing = false;
      });

      // 通知授权成功
      if (widget.onAddressAuthorized != null) {
        widget.onAddressAuthorized!(option.address);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ 地址授权成功'),
          backgroundColor: EvaTheme.neonGreen,
        ),
      );
    } catch (e) {
      setState(() {
        _isAuthorizing = false;
        _error = '授权失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_availableAddresses.isEmpty) {
      return _buildEmptyStateWidget();
    }

    return _buildAddressSelectionWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EvaTheme.deepBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvaTheme.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: EvaTheme.primaryPurple,
          ),
          const SizedBox(height: 16),
          Text(
            '正在检测可用地址...',
            style: TextStyle(
              color: EvaTheme.lightGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EvaTheme.deepBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvaTheme.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: EvaTheme.errorRed,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '未找到可用的钱包地址',
            style: TextStyle(
              color: EvaTheme.lightText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请在 Farcaster 中绑定钱包地址，或连接外部钱包',
            style: TextStyle(
              color: EvaTheme.lightGray,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                '绑定 Farcaster 钱包',
                Icons.link,
                () => _showBindFarcasterDialog(),
              ),
              _buildActionButton(
                '连接外部钱包',
                Icons.wallet,
                () => _showConnectWalletDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelectionWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EvaTheme.deepBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvaTheme.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: EvaTheme.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '交易钱包设置',
                style: TextStyle(
                  color: EvaTheme.lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 错误信息
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EvaTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EvaTheme.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: EvaTheme.errorRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: EvaTheme.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 地址列表
          ...(_availableAddresses.map((address) => _buildAddressOption(address))),
        ],
      ),
    );
  }

  Widget _buildAddressOption(AddressOption option) {
    final isSelected = _selectedAddress?.address == option.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? EvaTheme.primaryPurple.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
            ? EvaTheme.primaryPurple 
            : EvaTheme.lightGray.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: option.recommended ? EvaTheme.neonGreen.withValues(alpha: 0.2) : EvaTheme.primaryPurple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            option.type == 'Farcaster钱包' ? Icons.shield : Icons.account_balance_wallet,
            color: option.recommended ? EvaTheme.neonGreen : EvaTheme.primaryPurple,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.type,
                        style: TextStyle(
                          color: EvaTheme.lightText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (option.recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EvaTheme.neonGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '推荐',
                            style: TextStyle(
                              color: EvaTheme.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    option.address, // Address service removed - functionality not available
                    style: TextStyle(
                      color: EvaTheme.lightGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedAddress = option;
          });
          if (widget.onAddressSelected != null) {
            widget.onAddressSelected!(option);
          }
        },
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: EvaTheme.primaryPurple,
            side: BorderSide(color: EvaTheme.primaryPurple),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  void _showBindFarcasterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvaTheme.deepBlack,
        title: Text(
          '绑定 Farcaster 钱包',
          style: TextStyle(color: EvaTheme.lightText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '请在 Farcaster 应用中绑定您的钱包地址：',
              style: TextStyle(color: EvaTheme.lightGray),
            ),
            const SizedBox(height: 16),
            Text(
              '1. 打开 Farcaster 应用\n2. 前往设置页面\n3. 选择"连接钱包"\n4. 完成钱包验证',
              style: TextStyle(color: EvaTheme.lightGray, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: EvaTheme.lightGray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadAvailableAddresses(); // 重新检测地址
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EvaTheme.primaryPurple,
            ),
            child: const Text('刷新地址', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showConnectWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvaTheme.deepBlack,
        title: Text(
          '连接外部钱包',
          style: TextStyle(color: EvaTheme.lightText),
        ),
        content: Text(
          '外部钱包连接功能将在后续版本中提供。\n建议您在 Farcaster 中绑定钱包地址以获得最佳体验。',
          style: TextStyle(color: EvaTheme.lightGray),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvaTheme.primaryPurple,
            ),
            child: const Text('知道了', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}