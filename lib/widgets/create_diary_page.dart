import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/trading_diary.dart';
import '../services/diary_template_service.dart';
import '../services/farcaster_share_service.dart';

/// 创建日记页面
class CreateDiaryPage extends StatefulWidget {
  final DiaryTemplate template;
  final Function(TradingDiary) onDiaryCreated;

  const CreateDiaryPage({
    super.key,
    required this.template,
    required this.onDiaryCreated,
  });

  @override
  State<CreateDiaryPage> createState() => _CreateDiaryPageState();
}

class _CreateDiaryPageState extends State<CreateDiaryPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<String> _selectedTags = [];
  bool _isPublic = true;
  bool _shareToFarcaster = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeTemplate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化模板内容
  void _initializeTemplate() {
    _titleController.text = '${widget.template.name} - ${_formatDate(DateTime.now())}';
    _contentController.text = widget.template.template;
    _selectedTags = DiaryTemplateService.getSuggestedTags(widget.template.type).take(2).toList();
  }

  /// 保存日记
  Future<void> _saveDiary() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      // 模拟保存延时
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 创建日记对象
      final diary = TradingDiary(
        id: _generateId(),
        authorFid: 'current_user_fid', // TODO: 从认证状态获取
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: widget.template.type,
        tags: _selectedTags,
        createdAt: DateTime.now(),
        isPublic: _isPublic,
      );

      // 通知父组件
      widget.onDiaryCreated(diary);

      // 分享到Farcaster（如果勾选了）
      if (_shareToFarcaster && _isPublic) {
        final shareService = FarcasterShareService();
        await shareService.shareDiary(diary);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_shareToFarcaster && _isPublic ? '日记保存并分享成功！' : '日记保存成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 生成随机ID
  String _generateId() {
    return 'diary_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  /// 显示标签选择器
  void _showTagSelector() {
    final allTags = DiaryTemplateService.getSuggestedTags(widget.template.type);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('选择标签'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setDialogState(() {
                      if (selected) {
                        if (!_selectedTags.contains(tag)) {
                          _selectedTags.add(tag);
                        }
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  /// 插入Emoji
  void _insertEmoji(String emoji) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.template.icon),
            const SizedBox(width: 8),
            Text(widget.template.name),
          ],
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveDiary,
              child: const Text('保存'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题输入
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '标题',
                        hintText: '请输入日记标题',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return '请输入标题';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 内容输入
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '内容',
                        hintText: '请输入日记内容',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 15,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return '请输入内容';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 标签区域
                    Row(
                      children: [
                        const Text(
                          '标签：',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ..._selectedTags.map((tag) => Chip(
                                label: Text(tag),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedTags.remove(tag);
                                  });
                                },
                              )),
                              ActionChip(
                                label: const Text('添加标签'),
                                avatar: const Icon(Icons.add, size: 16),
                                onPressed: _showTagSelector,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 公开设置
                    SwitchListTile(
                      title: const Text('公开发布'),
                      subtitle: const Text('其他用户可以在广场看到这篇日记'),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                          // 如果设置为私有，自动关闭Farcaster分享
                          if (!value) {
                            _shareToFarcaster = false;
                          }
                        });
                      },
                    ),
                    
                    // Farcaster分享设置
                    SwitchListTile(
                      title: const Text('分享到 Farcaster'),
                      subtitle: const Text('保存时自动分享到 Farcaster'),
                      value: _shareToFarcaster,
                      onChanged: _isPublic ? (value) {
                        setState(() {
                          _shareToFarcaster = value;
                        });
                      } : null,
                    ),
                  ],
                ),
              ),
            ),
            
            // 底部工具栏
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '常用：',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: DiaryTemplateService.getEmojiSuggestions().length,
                        separatorBuilder: (context, index) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          final emoji = DiaryTemplateService.getEmojiSuggestions()[index];
                          return InkWell(
                            onTap: () => _insertEmoji(emoji),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}