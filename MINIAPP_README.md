# ThunderTrack - Farcaster Mini App

基于 Flutter Web 构建的去中心化交易日记应用，集成了 Farcaster Mini App SDK。

## 🚀 功能特点

- **Farcaster 原生登录**: 自动检测 Mini App 环境，无需表单登录
- **交易记录**: 集成 Hyperliquid API 获取实时交易数据
- **去中心化存储**: 使用 IPFS 存储交易日记内容
- **社交分享**: 支持在 Farcaster 中分享交易心得
- **钱包集成**: 支持以太坊钱包连接和交易

## 📦 项目结构

```
lib/
├── main.dart                          # 主应用入口
├── services/
│   ├── farcaster_miniapp_service.dart # Farcaster Mini App 服务
│   ├── neynar_service.dart           # Neynar API 服务
│   └── hyperliquid_service.dart      # Hyperliquid API 服务
├── providers/
│   └── user_provider.dart            # 用户状态管理
├── models/
│   └── user.dart                     # 用户数据模型
└── pages/
    ├── trading_page.dart             # 交易页面
    ├── diary_page.dart               # 日记页面
    └── profile_page.dart             # 个人页面

web/
├── index.html                        # 集成了 Mini App SDK
└── .well-known/
    └── farcaster.json               # Mini App 清单文件
```

## 🛠️ 开发环境设置

### 1. 环境要求

- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Web 浏览器（推荐 Chrome）

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 本地开发

```bash
# 启动开发服务器
flutter run -d web

# 或指定端口
flutter run -d web --web-port 8080
```

### 4. 构建生产版本

```bash
flutter build web --release
```

## 🌐 部署到生产环境

### 方法一: Vercel 部署

1. **安装 Vercel CLI**:
```bash
npm i -g vercel
```

2. **创建 vercel.json**:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "build/web/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/build/web/$1"
    }
  ]
}
```

3. **构建和部署**:
```bash
flutter build web --release
vercel --prod
```

### 方法二: Firebase Hosting

1. **安装 Firebase CLI**:
```bash
npm install -g firebase-tools
```

2. **初始化 Firebase**:
```bash
firebase init hosting
```

3. **配置 firebase.json**:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

4. **部署**:
```bash
flutter build web --release
firebase deploy
```

## 🔧 配置 Mini App

### 1. 更新 farcaster.json

编辑 `web/.well-known/farcaster.json`，将域名替换为你的实际域名：

```json
{
  "miniapp": {
    "version": "1",
    "name": "ThunderTrack",
    "iconUrl": "https://your-domain.com/icons/Icon-512.png",
    "homeUrl": "https://your-domain.com",
    "splashImageUrl": "https://your-domain.com/icons/Icon-512.png",
    "splashBackgroundColor": "#667eea"
  }
}
```

### 2. 更新 index.html Meta Tags

编辑 `web/index.html`，更新所有 `your-domain.com` 为你的实际域名。

### 3. 添加应用图标

确保以下文件存在：
- `web/icons/Icon-512.png` - Mini App 图标
- `web/og-image.png` - 社交分享图片 (1200x630px)
- `web/logo.png` - 启动画面图片 (200x200px)

## 🧪 测试 Mini App

### 1. 本地测试

使用 `?miniApp=true` 参数测试：
```
http://localhost:8080?miniApp=true
```

### 2. Farcaster Frame Validator

访问 [Warpcast Frame Validator](https://warpcast.com/~/developers/frames) 输入你的域名进行验证。

### 3. 在 Warpcast 中测试

1. 发布包含你的 Mini App URL 的 Cast
2. 查看是否显示正确的预览卡片
3. 点击按钮测试应用启动

## 🔑 环境变量配置

创建 `.env` 文件（如果需要）：

```env
# Hyperliquid API (如果有 API Key)
HYPERLIQUID_API_KEY=your_api_key

# Neynar API Key
NEYNAR_API_KEY=your_neynar_key

# IPFS/Pinata Keys
PINATA_API_KEY=your_pinata_key
PINATA_SECRET_KEY=your_pinata_secret
```

## 🐛 调试信息

应用会在浏览器控制台输出详细的调试信息：

- Mini App 环境检测结果
- Farcaster SDK 加载状态
- 用户登录流程状态
- API 调用结果

## 📱 支持的 Farcaster 客户端

- **Warpcast** (移动端和桌面端)
- **Supercast**
- **Rainbow**
- **其他支持 Mini Apps 的 Farcaster 客户端**

## 🔗 相关链接

- [Farcaster Mini Apps 官方文档](https://docs.farcaster.xyz/developers/frames/v2)
- [Flutter Web 部署指南](https://docs.flutter.dev/deployment/web)
- [Warpcast 开发者工具](https://warpcast.com/~/developers)

## 🆘 常见问题

### Q: 为什么在浏览器中看不到登录按钮？

A: Mini App SDK 只在 Farcaster 客户端环境中加载。在普通浏览器中会显示模拟登录对话框。

### Q: 如何测试真实的 Farcaster 登录？

A: 需要在 Warpcast 等 Farcaster 客户端中打开应用，或使用 `?miniApp=true` 参数模拟 Mini App 环境。

### Q: ready() 函数什么时候调用？

A: 应用在 Flutter 框架完全加载后自动调用，无需手动处理。

---

## 🎯 下一步计划

1. 集成真实的 Hyperliquid API
2. 实现 IPFS 去中心化存储
3. 添加更多交易分析功能
4. 优化 Mini App 用户体验