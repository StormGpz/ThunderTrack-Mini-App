import 'package:flutter/material.dart';
import '../models/trade.dart';
import 'package:intl/intl.dart';

/// 交易列表组件
class TradeList extends StatelessWidget {
  final List<Trade> trades;
  final VoidCallback? onRefresh;

  const TradeList({
    super.key,
    required this.trades,
    this.onRefresh,
  });

  /// 创建Sliver版本的交易列表
  static Widget sliver({
    required List<Trade> trades,
    VoidCallback? onRefresh,
  }) {
    return _TradeListSliver(trades: trades, onRefresh: onRefresh);
  }

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_flat,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无交易记录',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方按钮记录您的第一笔交易',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          final trade = trades[index];
          return TradeListItem(
            trade: trade,
            onTap: () => _showTradeDetails(context, trade),
          );
        },
      ),
    );
  }

  void _showTradeDetails(BuildContext context, Trade trade) {
    showDialog(
      context: context,
      builder: (context) => TradeDetailsDialog(trade: trade),
    );
  }
}

/// Sliver版本的交易列表
class _TradeListSliver extends StatelessWidget {
  final List<Trade> trades;
  final VoidCallback? onRefresh;

  const _TradeListSliver({
    required this.trades,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_flat,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无交易记录',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击上方按钮记录您的第一笔交易',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final trade = trades[index];
            return TradeListItem(
              trade: trade,
              onTap: () => _showTradeDetails(context, trade),
            );
          },
          childCount: trades.length,
        ),
      ),
    );
  }

  void _showTradeDetails(BuildContext context, Trade trade) {
    showDialog(
      context: context,
      builder: (context) => TradeDetailsDialog(trade: trade),
    );
  }
}

/// 单个交易项组件
class TradeListItem extends StatelessWidget {
  final Trade trade;
  final VoidCallback? onTap;

  const TradeListItem({
    super.key,
    required this.trade,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = trade.isBuy ? Colors.green : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部信息行
              Row(
                children: [
                  // 交易类型图标
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      trade.isBuy ? Icons.trending_up : Icons.trending_down,
                      color: color,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 交易对和状态
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trade.symbol,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(trade.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusText(trade.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getStatusColor(trade.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              trade.orderType,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 价格和总值
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${trade.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${trade.notionalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 底部信息行
              Row(
                children: [
                  // 数量
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '数量',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          trade.size.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 手续费
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '手续费',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '\$${(trade.fee ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 时间
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '时间',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          DateFormat('MM/dd HH:mm').format(trade.timestamp),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // 备注（如果有diaryId）
              if (trade.diaryId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 16,
                        color: Colors.grey.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '关联交易日记',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'filled':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '处理中';
      case 'filled':
        return '已完成';
      case 'cancelled':
        return '已取消';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }
}

/// 交易详情对话框
class TradeDetailsDialog extends StatelessWidget {
  final Trade trade;

  const TradeDetailsDialog({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    final color = trade.isBuy ? Colors.green : Colors.red;
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    trade.isBuy ? Icons.trending_up : Icons.trending_down,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trade.symbol,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        trade.isBuy ? '买入交易' : '卖出交易',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 交易详情
            _buildDetailRow('交易ID', trade.id),
            _buildDetailRow('数量', trade.size.toString()),
            _buildDetailRow('价格', '\$${trade.price.toStringAsFixed(2)}'),
            _buildDetailRow('总价值', '\$${trade.notionalValue.toStringAsFixed(2)}'),
            _buildDetailRow('手续费', '\$${(trade.fee ?? 0).toStringAsFixed(2)}'),
            _buildDetailRow('订单类型', trade.orderType),
            _buildDetailRow('状态', _getStatusText(trade.status)),
            _buildDetailRow('时间', DateFormat('yyyy-MM-dd HH:mm:ss').format(trade.timestamp)),
            
            if (trade.diaryId != null) ...[
              const SizedBox(height: 16),
              const Text(
                '关联日记',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('日记ID: ${trade.diaryId}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '处理中';
      case 'filled':
        return '已完成';
      case 'cancelled':
        return '已取消';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }
}