import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trade.dart';

/// 交易表单组件
class TradeForm extends StatefulWidget {
  final Function(Trade) onTradeSubmitted;

  const TradeForm({
    super.key,
    required this.onTradeSubmitted,
  });

  @override
  State<TradeForm> createState() => _TradeFormState();
}

class _TradeFormState extends State<TradeForm> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedSide = 'buy';
  String _selectedOrderType = 'market';
  String _selectedPlatform = 'Hyperliquid';
  
  final List<String> _availablePlatforms = [
    'Hyperliquid',
    'Binance',
    'OKX',
    'Bybit',
    'Other',
  ];

  final List<String> _popularSymbols = [
    'ETH/USDT',
    'BTC/USDT',
    'SOL/USDT',
    'ARB/USDT',
    'AVAX/USDT',
    'MATIC/USDT',
  ];

  @override
  void dispose() {
    _symbolController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalValue {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return amount * price;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final trade = Trade(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userFid: 'current_user', // 实际应用中从用户状态获取
        symbol: _symbolController.text.toUpperCase(),
        side: _selectedSide,
        orderType: _selectedOrderType,
        size: double.parse(_amountController.text),
        price: double.parse(_priceController.text),
        timestamp: DateTime.now(),
        status: 'filled', // 已完成状态
        fee: _totalValue * 0.001, // 0.1% 手续费
        diaryId: _notesController.text.isEmpty ? null : 'diary_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      widget.onTradeSubmitted(trade);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    Icon(
                      _selectedSide == 'buy' ? Icons.trending_up : Icons.trending_down,
                      color: _selectedSide == 'buy' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '记录新交易',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 交易类型选择
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('买入'),
                        value: 'buy',
                        groupValue: _selectedSide,
                        onChanged: (value) => setState(() => _selectedSide = value!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('卖出'),
                        value: 'sell',
                        groupValue: _selectedSide,
                        onChanged: (value) => setState(() => _selectedSide = value!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 交易对输入
                TextFormField(
                  controller: _symbolController,
                  decoration: InputDecoration(
                    labelText: '交易对',
                    hintText: '例如: ETH/USDT',
                    border: const OutlineInputBorder(),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (symbol) => _symbolController.text = symbol,
                      itemBuilder: (context) => _popularSymbols
                          .map((symbol) => PopupMenuItem(
                                value: symbol,
                                child: Text(symbol),
                              ))
                          .toList(),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入交易对';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
                
                const SizedBox(height: 16),
                
                // 数量和价格
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: '数量',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入数量';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return '请输入有效数量';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: '价格',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入价格';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return '请输入有效价格';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 总价值显示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('总价值:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '\$${_totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedSide == 'buy' ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 订单类型选择
                DropdownButtonFormField<String>(
                  value: _selectedOrderType,
                  decoration: const InputDecoration(
                    labelText: '订单类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'market', child: Text('市价单')),
                    DropdownMenuItem(value: 'limit', child: Text('限价单')),
                  ],
                  onChanged: (value) => setState(() => _selectedOrderType = value!),
                ),
                
                const SizedBox(height: 16),
                
                // 平台选择
                DropdownButtonFormField<String>(
                  value: _selectedPlatform,
                  decoration: const InputDecoration(
                    labelText: '交易平台',
                    border: OutlineInputBorder(),
                  ),
                  items: _availablePlatforms
                      .map((platform) => DropdownMenuItem(
                            value: platform,
                            child: Text(platform),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPlatform = value!),
                ),
                
                const SizedBox(height: 16),
                
                // 备注
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: '备注 (可选)',
                    hintText: '交易原因、策略等',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 24),
                
                // 提交按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedSide == 'buy' ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _selectedSide == 'buy' ? '记录买入交易' : '记录卖出交易',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}