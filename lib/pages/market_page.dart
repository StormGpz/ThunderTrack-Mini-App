import 'package:flutter/material.dart';

/// 市场页面，展示各种市场数据和行情分析
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            '市场页面',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('查看市场数据和行情分析'),
        ],
      ),
    );
  }
}