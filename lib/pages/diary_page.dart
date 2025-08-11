import 'package:flutter/material.dart';

/// 交易日记页面，展示其他人的交易笔记和心得分享
class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            '交易日记',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('浏览其他交易者的心得分享'),
          SizedBox(height: 20),
          Text(
            '点击右下角的 + 按钮开始写日记',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}