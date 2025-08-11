import 'package:flutter/material.dart';

/// 交易页面，显示市场活跃交易和买卖操作
class TradingPage extends StatelessWidget {
  const TradingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            '交易页面',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('查看市场活跃交易，执行买卖操作'),
        ],
      ),
    );
  }
}