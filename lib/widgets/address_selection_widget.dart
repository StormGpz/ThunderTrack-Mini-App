import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/address_auth.dart';
import '../models/user.dart';
import '../services/address_detection_service.dart';
import '../services/hyperliquid_service.dart';
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
  final AddressDetectionService _addressService = AddressDetectionService();
  final HyperliquidService _hyperliquidService = HyperliquidService();
  
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
        final addresses = await _addressService.detectAvailableAddresses(user);
        final recommended = await _addressService.getRecommendedAddress(user);
        
        setState(() {
          _availableAddresses = addresses;
          _selectedAddress = recommended;
        });

        // 如果有推荐地址，自动选择
        if (recommended != null && widget.onAddressSelected != null) {
          widget.onAddressSelected!(recommended);
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
      // 生成授权消息
      final message = _hyperliquidService.generateAuthMessage(option.address);
      
      // TODO: 实际项目中需要调用钱包签名
      // 这里使用模拟签名
      final signature = 'mock_signature_${DateTime.now().millisecondsSinceEpoch}';
      
      // 验证授权
      final success = await _hyperliquidService.authorizeAddress(option.address, signature);
      
      if (success) {
        setState(() {
          _isAuthorizing = false;
        });
        
        // 通知授权成功
        if (widget.onAddressAuthorized != null) {
          widget.onAddressAuthorized!(option.address);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 地址授权成功'),
            backgroundColor: EvaTheme.neonGreen,
          ),
        );
      } else {
        throw Exception('授权验证失败');
      }
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
        border: Border.all(color: EvaTheme.primaryPurple.withOpacity(0.3)),
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
        border: Border.all(color: EvaTheme.errorRed.withOpacity(0.3)),
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
        border: Border.all(color: EvaTheme.primaryPurple.withOpacity(0.3)),
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
                color: EvaTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EvaTheme.errorRed.withOpacity(0.3)),
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

          // 授权按钮
          if (_selectedAddress != null && !_hyperliquidService.isAddressAuthorized(_selectedAddress!.address)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAuthorizing ? null : () => _authorizeAddress(_selectedAddress!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvaTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isAuthorizing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('授权中...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.security, size: 16),
                        const SizedBox(width: 8),
                        const Text('点击授权签名'),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '此签名仅用于验证地址所有权，不会产生任何费用',
              style: TextStyle(
                color: EvaTheme.lightGray,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressOption(AddressOption option) {
    final isSelected = _selectedAddress?.address == option.address;
    final isAuthorized = _hyperliquidService.isAddressAuthorized(option.address);
    final authStatus = _hyperliquidService.getAddressAuthStatus(option.address);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? EvaTheme.primaryPurple.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
            ? EvaTheme.primaryPurple 
            : EvaTheme.lightGray.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: option.recommended ? EvaTheme.neonGreen.withOpacity(0.2) : EvaTheme.primaryPurple.withOpacity(0.2),
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
                            color: EvaTheme.neonGreen.withOpacity(0.2),
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
                    _addressService.formatAddress(option.address),
                    style: TextStyle(
                      color: EvaTheme.lightGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showAuthStatus) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAuthorized 
                    ? EvaTheme.neonGreen.withOpacity(0.2)
                    : EvaTheme.warningYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  authStatus.displayName,
                  style: TextStyle(
                    color: isAuthorized ? EvaTheme.neonGreen : EvaTheme.warningYellow,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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