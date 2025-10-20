# 日记 dApp 开发计划

## 项目概述
一个简单的区块链日记应用，允许用户：
- 手动记录日记条目
- 使用 Farcaster 钱包签名日记内容
- 查看日记历史记录
- 管理日记（编辑、删除）

## 核心功能

### 1. 日记模型 (Diary Model)
```
DiaryEntry {
  id: String (uuid or timestamp)
  title: String (日记标题)
  content: String (日记内容)
  tags: List<String> (标签，用于分类)
  createdAt: DateTime (创建时间)
  updatedAt: DateTime (更新时间)
  signature: String? (Farcaster 钱包签名)
  walletAddress: String? (签名地址)
  isPublished: bool (是否已发布到链上)
}
```

### 2. 功能模块

#### 2.1 日记编写页面 (DiaryWritePage)
- 标题输入框
- 内容文本编辑器
- 标签选择
- 保存为草稿
- 使用钱包签名并发布
- 取消按钮

#### 2.2 日记列表页面 (DiaryListPage)
- 显示所有日记（按创建时间倒序）
- 支持搜索和筛选
- 标签显示
- 发布状态指示（已签名/未签名）
- 点击查看详情
- 长按选项菜单（编辑、删除、分享）

#### 2.3 日记详情页面 (DiaryDetailPage)
- 显示完整日记内容
- 显示签名信息
- 显示签名地址
- 编辑和删除按钮
- 分享功能

#### 2.4 日记 Provider (DiaryProvider)
- 管理日记数据状态
- 本地存储（SharedPreferences）
- 加载/保存/删除操作
- 签名功能集成

### 3. 存储策略
- **本地存储**: 使用 SharedPreferences 存储日记列表 (JSON格式)
- **备用方案**: 后续可集成到智能合约或 IPFS

### 4. Farcaster 钱包集成
- 使用现有的 UserProvider 获取钱包地址
- 调用 `signTypedData()` 方法签名日记内容
- 显示签名后的地址
- 验证签名有效性

## 项目结构

```
lib/
├── models/
│   └── diary_entry.dart          # 日记数据模型
├── pages/
│   ├── diary_list_page.dart      # 日记列表页
│   ├── diary_write_page.dart     # 日记编写页
│   └── diary_detail_page.dart    # 日记详情页
├── providers/
│   └── diary_provider.dart       # 日记状态管理
├── services/
│   └── diary_service.dart        # 日记业务逻辑
└── widgets/
    └── diary_widgets.dart        # 日记相关组件
```

## 开发步骤

1. ✅ 清理 Farcaster 测试代码
2. 📋 创建日记数据模型
3. 📋 实现 DiaryService（本地存储）
4. 📋 实现 DiaryProvider（状态管理）
5. 📋 创建日记列表页面
6. 📋 创建日记编写页面
7. 📋 创建日记详情页面
8. 📋 集成钱包签名功能
9. 📋 测试完整流程

## 技术栈
- Flutter + Dart
- Provider (状态管理)
- SharedPreferences (本地存储)
- Farcaster SDK (钱包集成)
- EVA 主题风格

## 下一步
准备创建日记数据模型文件
