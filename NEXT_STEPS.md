# ThunderTrack 下一步计划（Wallet 授权与集成）

本文件用于记录“钱包真实授权 + Hyperliquid API 对接”的推进计划与待确认要点。下次继续时，只需在对话中说明“按 NEXT_STEPS.md 继续第 X 步”。

## 目标
- 打通 Web 环境的钱包连接与签名能力（EIP‑712 / EIP‑191）。
- 完成交易地址授权（基于 Hyperliquid 要求的签名格式）。
- 为下单/撤单等请求注入真实签名，替代当前占位逻辑。
- 保持前端安全：不在前端长期存储敏感私钥，优先使用用户钱包签名或后端代理签名（取决于 HL 规范）。

## 待确认（必须）
- Hyperliquid 授权规范：
  - 是否使用“API 私钥”模式（类似 Python SDK）还是“EOA EIP‑712 签名”模式？
  - 授权/下单所需 typedData 的 domain/types/message 具体字段？链 ID（大概率 Arbitrum 42161）？
  - 请求体中签名、地址、动作字段名（示例：signature/sender/action/nonce/expiry 等）。
- Farcaster Mini App 环境是否暴露以太坊 Provider？是否可发起 EIP‑712（typedData v4）？
- 交易地址来源：
  - 使用 Farcaster 已验证地址（verifications）还是允许用户另连外部 EOA？
- 是否允许后端代理签名（如 HL 仅支持 API 私钥）？

> 注：以上任何未知项将以“占位/骨架”实现，待你提供官方文档后补齐细节。

## 阶段性计划

### 阶段 1：WalletService（Web）
- 新增：`lib/services/wallet_service.dart`
- 能力：
  - `connect()`：连接钱包（优先 Mini App provider → window.ethereum）。
  - `getAddress()` / `getChainId()`。
  - `signMessage(String)`、`signTypedDataV4(Map typedData)`。
- 技术点：使用 `dart:js_util` 封装 Promise；仅在 Web 可用（必要时条件导入）。
- UI：在 `AddressSelectionWidget` 增加“连接外部钱包”入口，将所获地址加入候选地址。

### 阶段 2：TradingAuthService（地址授权）
- 新增：`lib/services/trading_auth_service.dart`
- 能力：
  - 生成“授权签名”所需的 typedData（占位，待 HL 文档补齐）。
  - 调用 Wallet 签名，得到签名值，回写 `AddressAuthInfo`（沿用现有模型）。
  - 持久化授权信息（沿用 `HyperliquidService` 内的缓存 + SharedPreferences）。
- UI：在 `AddressSelectionWidget` 增加“授权地址”按钮 + 进度/结果反馈。

### 阶段 3：HyperliquidService 落地授权
- 扩展 `HyperliquidService`：
  - `authorizeTradingAddress(String address)`：
    - 组合 HL 规范的 typedData；
    - 调用 `TradingAuthService` 发起签名；
    - 保存 `AddressAuthInfo`（含过期时间）；
    - 如 HL 需要，调用相应上报/注册接口。
  - 实现 `verifyEip712Signature(...)`（如 HL 提供校验或参考实现；否则先保留 TODO）。

### 阶段 4：下单/撤单签名
- 完善 `placeOrder` / `cancelOrder`：
  - 在请求体中注入 HL 要求的签名字段与元数据（address、nonce、expiry、chainId 等）。
  - 响应解析与错误提示（签名无效/过期/地址未授权）。
- `TradingProvider`：根据最终返回结构，完善用户交易与持仓解析（当前为 TODO）。

### 阶段 5：安全与配置
- 移除前端明文 `neynarApiKey`；改用 `--dart-define` 注入：
  - `NEYNAR_API_KEY`、`PINATA_API_KEY`、（如需）`HL_API_BASE` 等。
  - 在 `AppConfig`/`ApiClient` 中读取 `const String.fromEnvironment(...)`。
- 若 HL 仅支持“API 私钥”签名，前端改为“订单意图”→ 后端代理签名 → HL；前端不触碰 API 私钥。

### 阶段 6：测试与回归
- 单测：
  - WalletService（在 Web 下以 mock Promise 验证参数与回调）。
  - TradingAuthService 的 typedData 生成（对比快照）与签名调用（mock）。
- 集成/手测：
  - 连接钱包 → 授权地址 → 下单/撤单 → 错误场景（过期/拒签/链错误）。

### 阶段 7：文档与开关
- README：新增“环境变量、授权说明、风控提示”。
- Feature Flag：在 UI 增加“使用真实签名”开关（默认关，方便演示/Mock 场景切换）。

## 接口草案（骨架）

- WalletService
  - `Future<bool> connect()`
  - `Future<String> getAddress()`
  - `Future<int> getChainId()`
  - `Future<String> signTypedDataV4(Map<String, dynamic> typedData)`

- TradingAuthService
  - `Future<AddressAuthInfo> authorize({required String address, required Map<String, dynamic> typedData})`
  - `bool isAuthorized(String address)`（基于缓存与过期判断）

- HyperliquidService（扩展）
  - `Future<bool> authorizeTradingAddress(String address)`
  - 在 `placeOrder`/`cancelOrder` 中注入签名（待 HL 规范）

> typedData 占位示例（仅结构占位，字段以 HL 官方为准）：
>
> ```
> final typedData = {
>   'domain': {
>     'name': 'Hyperliquid',            // TBD
>     'version': '1',                   // TBD
>     'chainId': 42161,                 // TBD
>     'verifyingContract': '0x...',     // 如需
>   },
>   'types': {
>     'EIP712Domain': [...],
>     'Action': [
>       {'name': 'action', 'type': 'string'},
>       {'name': 'address', 'type': 'address'},
>       {'name': 'nonce', 'type': 'uint256'},
>       {'name': 'expiry', 'type': 'uint256'},
>       // 其他 HL 要求字段
>     ]
>   },
>   'primaryType': 'Action',
>   'message': {
>     'action': 'authorize',
>     'address': address,
>     'nonce': nonce,
>     'expiry': expiry,
>   }
> };
> ```

## 执行顺序与时间建议（可调整）
1) 阶段 1（WalletService 骨架 + UI 入口）
2) 阶段 2（TradingAuthService 骨架 + AddressAuthInfo 存储）
3) 补齐 HL 授权规范 → 完成阶段 3/4 细节
4) 阶段 5（安全配置）
5) 阶段 6/7（测试与文档）

## 下次如何继续
- 直接在聊天输入：
  - “继续：按 NEXT_STEPS.md 第 1 步，创建 WalletService 骨架并接入 AddressSelectionWidget 的连接按钮。”
  - 或者：“已拿到 HL 授权文档，请实现 typedData 按规范生成并完成 authorizeTradingAddress。”

## 变更影响与注意事项
- 本项目目标平台为 Web。`dart:js`/`dart:html` 相关能力在移动/桌面不可用；如需多端，需条件导入。
- 生产环境不应在前端保存 API 私钥。EOA 钱包签名优先；如必须 API 私钥签名，应后端代理。
- 现有 `withValues(alpha: ...)` API 需要较新的 Flutter 版本，请确保本地环境兼容。

---
最后更新：预填初版计划（等待 Hyperliquid 授权文档补齐以继续阶段 3/4）。
