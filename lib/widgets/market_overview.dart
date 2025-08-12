import 'package:flutter/material.dart';

/// 市场概览组件
class MarketOverview extends StatefulWidget {
  const MarketOverview({super.key});

  @override
  State<MarketOverview> createState() => _MarketOverviewState();
}

class _MarketOverviewState extends State<MarketOverview> {
  // 模拟市场数据
  final List<Map<String, dynamic>> _marketData = [
    {
      'symbol': 'BTC',
      'price': 65420.00,
      'change': 2.35,
      'color': Colors.green,
    },
    {
      'symbol': 'ETH',
      'price': 2845.50,
      'change': -1.24,
      'color': Colors.red,
    },
    {
      'symbol': 'SOL',
      'price': 98.76,
      'change': 5.67,
      'color': Colors.green,
    },
    {
      'symbol': 'ARB',
      'price': 1.23,
      'change': -0.85,
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '市场概览',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '实时',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 市场数据网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _marketData.length,
            itemBuilder: (context, index) {
              final data = _marketData[index];
              return _buildMarketItem(data);
            },
          ),
          
          const SizedBox(height: 16),
          
          // 快速操作按钮
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  '查看全部',
                  Icons.visibility,
                  Colors.blue,
                  () => _showAllMarkets(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  '价格提醒',
                  Icons.notifications,
                  Colors.orange,
                  () => _showPriceAlerts(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketItem(Map<String, dynamic> data) {
    final isPositive = data['change'] > 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                data['symbol'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: changeColor,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '\$${data['price'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${data['change'].toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showAllMarkets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('即将推出 - 完整市场列表'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPriceAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('即将推出 - 价格提醒功能'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}