import '../models/trading_diary.dart';

/// 日记模板系统
class DiaryTemplate {
  /// 模板ID
  final String id;
  
  /// 模板名称
  final String name;
  
  /// 模板描述
  final String description;
  
  /// 模板类型
  final DiaryType type;
  
  /// 模板内容
  final String template;
  
  /// 图标
  final String icon;

  const DiaryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.template,
    required this.icon,
  });
}

/// 日记模板服务
class DiaryTemplateService {
  static const List<DiaryTemplate> _templates = [
    // 单笔复盘模板
    DiaryTemplate(
      id: 'single_trade',
      name: '单笔复盘',
      description: '分析单笔交易的决策过程和结果',
      type: DiaryType.singleTrade,
      icon: '📊',
      template: '''📊 **交易概要**

• **币种：** [请填写交易对，如 ETH/USDT]
• **操作：** [买入/卖出] [数量]
• **价格：** \$[价格]
• **时间：** [交易时间]

💭 **操作逻辑**

• **买入理由：** [技术分析/基本面/消息面]
• **预期目标：** [目标价位或持有期]
• **风险评估：** [高/中/低风险]
• **止损设置：** [止损价位]

📈 **结果总结**

• **实际收益：** [+/-X%]
• **持有时长：** [X天/小时]
• **成功要素：** [分析成功的关键因素]
• **改进方向：** [下次可以改进的地方]

🎯 **经验教训**

[记录本次交易的核心收获和感悟]''',
    ),

    // 策略总结模板
    DiaryTemplate(
      id: 'strategy_summary',
      name: '策略总结',
      description: '总结一段时间的交易策略和表现',
      type: DiaryType.strategySummary,
      icon: '🎯',
      template: '''🎯 **策略名称：** [震荡区间套利/趋势跟踪/其他]

📅 **执行周期：** [开始时间] - [结束时间]

💰 **资金配置**

• **总投入：** \$[金额]
• **主要品种：** [ETH 60%, BTC 40%]
• **风险控制：** [单笔止损X%, 总仓位X%]

📊 **操作记录**

**买入记录：**
• [时间] [币种] [价格] [数量] [理由]
• [时间] [币种] [价格] [数量] [理由]

**卖出记录：**
• [时间] [币种] [价格] [盈亏] [原因]

📈 **策略表现**

• **总收益率：** [+/-X%]
• **胜率：** [X%]
• **最大回撤：** [X%]
• **夏普比率：** [如果计算的话]

🧠 **策略思考**

• **市场判断：** [当时的市场环境分析]
• **执行情况：** [是否严格按策略执行]
• **意外情况：** [遇到的突发事件处理]

💡 **优化建议**

• **成功经验：** [值得继续保持的做法]
• **失败教训：** [需要避免的错误]
• **改进方向：** [下个周期的优化重点]''',
    ),

    // 自由记录模板
    DiaryTemplate(
      id: 'free_form',
      name: '自由记录',
      description: '记录交易想法、市场观点或学习心得',
      type: DiaryType.freeForm,
      icon: '📝',
      template: '''📝 **今日交易思考**

💭 **市场观察**

[记录对当前市场的观察和判断]

📚 **学习收获**

[记录今天学到的交易知识或技巧]

🎯 **交易计划**

[制定接下来的交易计划和目标]

⚠️ **风险提醒**

[提醒自己注意的风险点]

✨ **灵感想法**

[记录突然想到的交易策略或想法]''',
    ),
  ];

  /// 获取所有模板
  static List<DiaryTemplate> getAllTemplates() => _templates;

  /// 根据类型获取模板
  static DiaryTemplate? getTemplateByType(DiaryType type) {
    try {
      return _templates.firstWhere((template) => template.type == type);
    } catch (e) {
      return null;
    }
  }

  /// 根据ID获取模板
  static DiaryTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 生成自定义模板内容
  static String generateCustomTemplate({
    required DiaryType type,
    String? symbol,
    DateTime? date,
    Map<String, String>? customFields,
  }) {
    final template = getTemplateByType(type);
    if (template == null) return '';

    String content = template.template;

    // 替换常用占位符
    if (symbol != null) {
      content = content.replaceAll('[请填写交易对，如 ETH/USDT]', symbol);
      content = content.replaceAll('[币种]', symbol.split('/')[0]);
    }

    if (date != null) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      content = content.replaceAll('[交易时间]', dateStr);
      content = content.replaceAll('[开始时间]', dateStr);
    }

    // 替换自定义字段
    if (customFields != null) {
      customFields.forEach((key, value) {
        content = content.replaceAll('[$key]', value);
      });
    }

    return content;
  }

  /// 获取常用标签建议
  static List<String> getSuggestedTags(DiaryType type) {
    switch (type) {
      case DiaryType.singleTrade:
        return ['技术分析', '基本面', '短线', '长线', '止损', '获利', '复盘'];
      case DiaryType.strategySummary:
        return ['策略', '回测', '风控', '资管', '套利', '趋势', '震荡'];
      case DiaryType.freeForm:
        return ['学习', '思考', '计划', '观察', '心得', '想法', '总结'];
    }
  }

  /// 获取emoji建议
  static List<String> getEmojiSuggestions() {
    return [
      '📈', '📉', '💰', '🎯', '⚡', '🚀', '💡', '⚠️',
      '✅', '❌', '🔥', '💎', '🌙', '☀️', '⭐', '🎉',
    ];
  }
}