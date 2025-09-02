import 'package:flutter/material.dart';
import '../services/hyperliquid_service.dart';
import '../theme/eva_theme.dart';

/// Hyperliquid API测试页面
class HyperliquidTestPage extends StatefulWidget {
  const HyperliquidTestPage({super.key});

  @override
  State<HyperliquidTestPage> createState() => _HyperliquidTestPageState();
}

class _HyperliquidTestPageState extends State<HyperliquidTestPage> {
  final HyperliquidService _hyperliquidService = HyperliquidService();
  
  bool _isLoading = false;
  String _status = '准备测试API连接...';
  Map<String, double>? _midsData;
  Map<String, dynamic>? _metaData;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyperliquid API 测试'),
        backgroundColor: EvaTheme.primaryPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: EvaTheme.primaryGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 状态卡片
              Card(
                elevation: 8,
                color: EvaTheme.mechGray,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '连接状态',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: EvaTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_isLoading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(EvaTheme.neonGreen),
                              ),
                            )
                          else if (_error != null)
                            Icon(Icons.error, color: EvaTheme.errorRed, size: 16)
                          else if (_midsData != null || _metaData != null)
                            Icon(Icons.check_circle, color: EvaTheme.neonGreen, size: 16)
                          else
                            Icon(Icons.radio_button_unchecked, color: EvaTheme.textGray, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _status,
                              style: TextStyle(color: EvaTheme.lightText),
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: EvaTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EvaTheme.errorRed.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: EvaTheme.errorRed, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 测试按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testGetAllMids,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EvaTheme.infoBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('测试价格数据 (getAllMids)'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testGetMeta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EvaTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('测试市场数据 (getMeta)'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 完整测试按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testAllApis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EvaTheme.neonGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '运行完整API测试',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 结果显示
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: const [
                          Tab(text: '价格数据'),
                          Tab(text: '市场信息'),
                        ],
                        labelColor: EvaTheme.infoBlue,
                        unselectedLabelColor: EvaTheme.textGray,
                        indicatorColor: EvaTheme.infoBlue,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildMidsDataTab(),
                            _buildMetaDataTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 测试getAllMids API
  Future<void> _testGetAllMids() async {
    setState(() {
      _isLoading = true;
      _status = '正在获取价格数据...';
      _error = null;
    });

    try {
      final mids = await _hyperliquidService.getAllMids();
      setState(() {
        _midsData = mids;
        _status = '价格数据获取成功 (${mids.length} 个交易对)';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = '价格数据获取失败';
        _isLoading = false;
      });
    }
  }

  /// 测试getMeta API
  Future<void> _testGetMeta() async {
    setState(() {
      _isLoading = true;
      _status = '正在获取市场信息...';
      _error = null;
    });

    try {
      final meta = await _hyperliquidService.getMeta();
      setState(() {
        _metaData = meta;
        _status = '市场信息获取成功';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = '市场信息获取失败';
        _isLoading = false;
      });
    }
  }

  /// 运行完整API测试
  Future<void> _testAllApis() async {
    setState(() {
      _isLoading = true;
      _status = '正在运行完整API测试...';
      _error = null;
      _midsData = null;
      _metaData = null;
    });

    try {
      // 并行测试两个API
      final results = await Future.wait([
        _hyperliquidService.getAllMids(),
        _hyperliquidService.getMeta(),
      ]);

      setState(() {
        _midsData = results[0] as Map<String, double>;
        _metaData = results[1] as Map<String, dynamic>;
        _status = '✅ 所有API测试成功完成';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = '❌ API测试失败';
        _isLoading = false;
      });
    }
  }

  /// 构建价格数据标签页
  Widget _buildMidsDataTab() {
    if (_midsData == null) {
      return Center(
        child: Text(
          '暂无价格数据\n点击上方按钮开始测试',
          textAlign: TextAlign.center,
          style: TextStyle(color: EvaTheme.textGray),
        ),
      );
    }

    final sortedEntries = _midsData!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // 按价格降序排列

    return Card(
      color: EvaTheme.mechGray,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EvaTheme.infoBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  entry.key.substring(0, 2),
                  style: TextStyle(
                    color: EvaTheme.infoBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              entry.key,
              style: TextStyle(color: EvaTheme.lightText, fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              '\$${entry.value.toStringAsFixed(2)}',
              style: TextStyle(
                color: EvaTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建市场信息标签页
  Widget _buildMetaDataTab() {
    if (_metaData == null) {
      return Center(
        child: Text(
          '暂无市场信息\n点击上方按钮开始测试',
          textAlign: TextAlign.center,
          style: TextStyle(color: EvaTheme.textGray),
        ),
      );
    }

    return Card(
      color: EvaTheme.mechGray,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _metaData!.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: EvaTheme.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(color: EvaTheme.lightText),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}